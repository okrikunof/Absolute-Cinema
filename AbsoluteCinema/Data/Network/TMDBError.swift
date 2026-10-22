import Foundation

enum TMDBError: LocalizedError {
    case configuration
    case unauthorized
    case notFound
    case tooManyRequests
    case unavailable
    case invalidResponse
    case connection
    case timeout
    case invalidRating
    case guestSession
    case guestSessionExpired
    case ratingRejected
    case invalidRequest

    var errorDescription: String? {
        switch self {
        case .configuration:
            "Не удалось подключиться к каталогу фильмов."
        case .unauthorized:
            "Сервис фильмов отклонил доступ."
        case .notFound:
            "Фильм больше не доступен в каталоге."
        case .tooManyRequests:
            "Слишком много запросов. Попробуйте немного позже."
        case .unavailable:
            "Сервис фильмов временно недоступен. Попробуйте ещё раз."
        case .invalidResponse:
            "Не удалось прочитать ответ сервиса фильмов."
        case .connection:
            "Не удалось связаться с сервисом фильмов. Проверьте подключение к интернету."
        case .timeout:
            "Сервис фильмов не ответил вовремя. Попробуйте ещё раз."
        case .invalidRating:
            "Оценка должна быть от 1 до 10."
        case .guestSession:
            "Не удалось открыть гостевую сессию TMDB. Повторите отправку."
        case .guestSessionExpired:
            "Гостевая сессия TMDB завершилась. Повторите отправку."
        case .ratingRejected:
            "TMDB не принял оценку. Попробуйте отправить её ещё раз."
        case .invalidRequest:
            "Сервис фильмов не смог обработать запрос. Попробуйте ещё раз."
        }
    }
}
