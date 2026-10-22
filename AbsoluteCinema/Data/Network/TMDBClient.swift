import Foundation

// Actor выполняет обработку ответов отдельно от состояния интерфейса на MainActor.
actor TMDBClient {
    private let session: URLSession
    private let configurationOverride: TMDBConfiguration?
    private var guestSession: (id: String, expiresAt: Date)?

    private enum Method: String {
        case get = "GET"
        case post = "POST"
    }

    init(session: URLSession = .shared, configuration: TMDBConfiguration? = nil) {
        self.session = session
        configurationOverride = configuration
    }

    func searchMovies(query: String) async throws -> [Movie] {
        let response: TMDBMovieListResponse = try await request(
            path: "search/movie",
            queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "include_adult", value: "false"),
                URLQueryItem(name: "page", value: "1")
            ]
        )
        return response.results.map { $0.movie(hasDetails: false) }
    }

    func movie(id: Int) async throws -> Movie {
        let response: TMDBMovieResponse = try await request(path: "movie/\(id)")
        guard response.id == id else { throw TMDBError.invalidResponse }
        return response.movie(hasDetails: true)
    }

    func sendRating(movieID: Int, rating: Int) async throws -> TMDBRatingResult {
        guard (1...10).contains(rating) else { throw TMDBError.invalidRating }
        let guestID = try await guestSessionID()
        let body = try JSONEncoder().encode(TMDBRatingRequest(value: rating))
        do {
            let response: TMDBStatusResponse = try await request(
                path: "movie/\(movieID)/rating",
                method: .post,
                queryItems: [URLQueryItem(name: "guest_session_id", value: guestID)],
                body: body
            )
            // Даже HTTP 200 не означает успех: проверяем результат из JSON.
            guard response.success != false else { throw ratingError(statusCode: response.statusCode) }
            switch response.statusCode {
            case 1: return .saved
            case 12: return .updated
            case 40: return .unchanged
            default: throw ratingError(statusCode: response.statusCode)
            }
        } catch TMDBError.guestSessionExpired {
            guestSession = nil
            throw TMDBError.guestSessionExpired
        }
    }

    private func guestSessionID() async throws -> String {
        if let guestSession, guestSession.expiresAt > Date() {
            return guestSession.id
        }
        let response: TMDBGuestSessionResponse = try await request(path: "authentication/guest_session/new")
        guard response.success,
              let id = response.guestSessionID, !id.isEmpty,
              let expiresAt = response.expiresAt else {
            throw TMDBError.guestSession
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss 'UTC'"
        guard let date = formatter.date(from: expiresAt), date > Date() else {
            throw TMDBError.guestSession
        }
        // Сессия хранится только в памяти; после перезапуска создаётся новая.
        guestSession = (id, date)
        return id
    }

    private func ratingError(statusCode: Int) -> TMDBError {
        switch statusCode {
        case 17, 37: .guestSessionExpired
        case 3, 7, 10, 14, 35, 36: .unauthorized
        default: .ratingRejected
        }
    }

    private func request<Response: Decodable & Sendable>(
        path: String, method: Method = .get,
        queryItems: [URLQueryItem] = [], body: Data? = nil
    ) async throws -> Response {
        try Task.checkCancellation()
        let configuration = try configurationOverride ?? TMDBConfiguration.load()
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.themoviedb.org"
        components.path = "/3/\(path)"
        components.queryItems = [URLQueryItem(name: "language", value: "ru-RU")] + queryItems

        let token = configuration.readAccessToken.flatMap { $0.isEmpty ? nil : $0 }
        if token == nil, let key = configuration.apiKey, !key.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "api_key", value: key))
        }
        guard let url = components.url else { throw TMDBError.invalidResponse }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.httpBody = body
        urlRequest.timeoutInterval = 20
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            urlRequest.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        if let token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)
            try Task.checkCancellation()
            guard let response = response as? HTTPURLResponse else {
                throw TMDBError.invalidResponse
            }
            if !(200..<300).contains(response.statusCode) {
                let failure = try? await JSONParser.decode(TMDBStatusResponse.self, from: data)
                try Task.checkCancellation()
                if let failure, [17, 37].contains(failure.statusCode) {
                    throw TMDBError.guestSessionExpired
                }
                switch response.statusCode {
                case 401, 403: throw TMDBError.unauthorized
                case 404: throw TMDBError.notFound
                case 400, 422: throw TMDBError.invalidRequest
                case 429: throw TMDBError.tooManyRequests
                default: throw TMDBError.unavailable
                }
            }
            return try await JSONParser.decode(Response.self, from: data)
        } catch let error as URLError {
            if error.code == .cancelled { throw CancellationError() }
            if error.code == .timedOut { throw TMDBError.timeout }
            throw TMDBError.connection
        } catch is DecodingError {
            throw TMDBError.invalidResponse
        }
    }
}
