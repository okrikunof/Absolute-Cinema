import Foundation
import XCTest
@testable import AbsoluteCinema

final class TMDBClientTests: XCTestCase {
    func testSearchSendsGETAndParsesMovie() async throws {
        // Arrange: задаём ответ сервера, не обращаясь к интернету.
        let session = makeSession(responses: [
            .init(status: 200, json: """
                {"results":[{"id":62,"title":"Одиссея","original_title":"A Space Odyssey",
                "release_date":"1968-04-02","vote_average":8.0,"vote_count":12960}]}
                """)
        ])
        defer { session.invalidateAndCancel() }
        let client = makeClient(session: session)

        // Act: выполняется настоящий путь URLRequest → URLSession → JSONParser.
        let movies = try await client.searchMovies(query: "Космос & кино")

        // Assert: проверяем и запрос, и разобранные данные, а не только HTTP 200.
        let requests = StubURLProtocol.recordedRequests()
        XCTAssertEqual(requests.count, 1)
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.path, "/3/search/movie")
        XCTAssertEqual(query("query", in: request), "Космос & кино")
        XCTAssertEqual(query("language", in: request), "ru-RU")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer unit-test-token")
        XCTAssertEqual(movies.count, 1)
        let movie = try XCTUnwrap(movies.first)
        XCTAssertEqual(movie.id, 62)
        XCTAssertEqual(movie.title, "Одиссея")
        XCTAssertEqual(movie.year, 1968)
        XCTAssertEqual(movie.rating, 8.0)
        XCTAssertNil(movie.runtime)
        XCTAssertFalse(movie.hasDetails)
    }

    func testRatingSendsPOSTAndReusesGuestSession() async throws {
        let session = makeSession(responses: [
            .init(status: 200, json: """
                {"success":true,"guest_session_id":"test-guest","expires_at":"2099-01-01 00:00:00 UTC"}
                """),
            .init(status: 201, json: #"{"status_code":1}"#),
            .init(status: 200, json: #"{"success":true,"status_code":12}"#)
        ])
        defer { session.invalidateAndCancel() }
        let client = makeClient(session: session)

        let first = try await client.sendRating(movieID: 62, rating: 8)
        let second = try await client.sendRating(movieID: 62, rating: 9)

        guard case .saved = first else { return XCTFail("Первый POST должен сохранить оценку") }
        guard case .updated = second else { return XCTFail("Второй POST должен обновить оценку") }
        let requests = StubURLProtocol.recordedRequests()
        // Один GET сессии и два POST: повторного создания сессии нет.
        XCTAssertEqual(requests.count, 3)
        guard requests.count == 3 else { return }
        XCTAssertEqual(requests[0].httpMethod, "GET")
        XCTAssertEqual(requests[0].url?.path, "/3/authentication/guest_session/new")
        for (request, expectedRating) in zip(requests.dropFirst(), [8, 9]) {
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/3/movie/62/rating")
            XCTAssertEqual(query("guest_session_id", in: request), "test-guest")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"),
                           "application/json;charset=utf-8")
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body(of: request))
                                    as? [String: Int])
            XCTAssertEqual(json, ["value": expectedRating])
        }
    }

    func testUnauthorizedResponseThrowsAccessError() async throws {
        let session = makeSession(responses: [
            .init(status: 401, json: #"{"success":false,"status_code":7}"#)
        ])
        defer { session.invalidateAndCancel() }
        let client = makeClient(session: session)

        do {
            _ = try await client.searchMovies(query: "Фильм")
            XCTFail("HTTP 401 должен приводить к ошибке, а не к успешному результату")
        } catch TMDBError.unauthorized {
            // Ожидаемый исход: отказ доступа распознан клиентом.
        } catch {
            XCTFail("Ожидалась unauthorized, получена \(error)")
        }
    }

    private func makeSession(responses: [StubURLProtocol.Response]) -> URLSession {
        StubURLProtocol.prepare(responses)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func makeClient(session: URLSession) -> TMDBClient {
        TMDBClient(session: session,
                   configuration: TMDBConfiguration(apiKey: nil, readAccessToken: "unit-test-token"))
    }

    private func query(_ name: String, in request: URLRequest) -> String? {
        request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?
            .queryItems?.first(where: { $0.name == name })?.value
    }

    private func body(of request: URLRequest) throws -> Data {
        if let data = request.httpBody { return data }
        // URLSession может передать тело перехватчику как поток.
        let stream = try XCTUnwrap(request.httpBodyStream)
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while true {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count == 0 { return data }
            guard count > 0 else { throw stream.streamError ?? URLError(.cannotDecodeRawData) }
            data.append(contentsOf: buffer.prefix(count))
        }
    }
}

// URLSession вызывает этот перехватчик вместо настоящего сервера.
// Очередь ответов и записанные запросы защищены lock от сетевых callback.
private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    struct Response {
        let status: Int
        let json: String
    }

    private static let lock = NSLock()
    private static var responses: [Response] = []
    private static var requests: [URLRequest] = []

    static func prepare(_ responses: [Response]) {
        lock.lock()
        defer { lock.unlock() }
        Self.responses = responses
        requests = []
    }

    static func recordedRequests() -> [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return requests
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lock.lock()
        Self.requests.append(request)
        let stub = Self.responses.isEmpty ? nil : Self.responses.removeFirst()
        Self.lock.unlock()

        guard let stub, let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: stub.status,
                                             httpVersion: nil,
                                             headerFields: ["Content-Type": "application/json"]) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(stub.json.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
