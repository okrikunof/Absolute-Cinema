#if DEBUG
import Foundation

// Включается только аргументом UI-тестов. Личная база и настоящий API не используются.
enum UITestSupport {
    static func makeClient() -> TMDBClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [UITestURLProtocol.self]
        return TMDBClient(
            session: URLSession(configuration: configuration),
            configuration: TMDBConfiguration(apiKey: nil, readAccessToken: "ui-test-token")
        )
    }

    @MainActor
    static func seed(ratings: RatingRepository) throws {
        if let movie = MockMovies.movies.first(where: { $0.id == 603 }) {
            _ = try ratings.save(movie: movie, rating: 8, comment: "Matrix baseline")
        }
    }
}

private final class UITestURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            let (status, json) = Self.response(for: request)
            let data = try JSONSerialization.data(withJSONObject: json)
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: status,
                                                 httpVersion: nil,
                                                 headerFields: ["Content-Type": "application/json"]) else {
                throw URLError(.badServerResponse)
            }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    private static func response(for request: URLRequest) -> (Int, [String: Any]) {
        let components = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let path = request.url?.path ?? ""
        if request.httpMethod == "GET", path == "/3/search/movie" {
            let query = components?.queryItems?.first(where: { $0.name == "query" })?.value ?? ""
            let movies = MockMovies.movies.filter {
                $0.title.localizedCaseInsensitiveContains(query)
                    || $0.originalTitle.localizedCaseInsensitiveContains(query)
            }
            return (200, ["results": movies.map(movieJSON)])
        }
        if request.httpMethod == "GET", path == "/3/authentication/guest_session/new" {
            return (200, ["success": true, "guest_session_id": "ui-test-guest",
                          "expires_at": "2099-01-01 00:00:00 UTC"])
        }
        let parts = path.split(separator: "/")
        if parts.count >= 3, parts[0] == "3", parts[1] == "movie",
           let id = Int(parts[2]), let movie = MockMovies.movies.first(where: { $0.id == id }) {
            if request.httpMethod == "GET", parts.count == 3 {
                return (200, movieJSON(movie))
            }
            if request.httpMethod == "POST", parts.count == 4, parts[3] == "rating" {
                return (201, ["status_code": 1])
            }
        }
        return (404, ["success": false, "status_code": 34])
    }

    private static func movieJSON(_ movie: Movie) -> [String: Any] {
        [
            "id": movie.id,
            "title": movie.title,
            "original_title": movie.originalTitle,
            "release_date": movie.year.map { "\($0)-01-01" } ?? "",
            "runtime": movie.runtime ?? 0,
            "overview": movie.overview,
            "genres": movie.genres.map { ["name": $0] },
            "vote_average": movie.rating,
            "vote_count": movie.voteCount
        ]
    }
}
#endif
