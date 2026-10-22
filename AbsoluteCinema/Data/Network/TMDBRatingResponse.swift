import Foundation

struct TMDBGuestSessionResponse: Decodable, Sendable {
    let success: Bool
    let guestSessionID: String?
    let expiresAt: String?

    private enum CodingKeys: String, CodingKey {
        case success
        case guestSessionID = "guest_session_id"
        case expiresAt = "expires_at"
    }
}

struct TMDBRatingRequest: Encodable, Sendable {
    let value: Int
}

// Этот ответ используется и для результата POST, и для ошибок сервиса.
struct TMDBStatusResponse: Decodable, Sendable {
    let success: Bool?
    let statusCode: Int

    private enum CodingKeys: String, CodingKey {
        case success
        case statusCode = "status_code"
    }
}

enum TMDBRatingResult: Sendable {
    case saved
    case updated
    case unchanged

    func message(rating: Int) -> String {
        switch self {
        case .saved: "Оценка \(rating) из 10 отправлена в TMDB."
        case .updated: "Оценка в TMDB обновлена: \(rating) из 10."
        case .unchanged: "В TMDB уже сохранена оценка \(rating) из 10."
        }
    }
}
