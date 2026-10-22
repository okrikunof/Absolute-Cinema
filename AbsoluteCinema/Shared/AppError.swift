import Foundation

enum AppError: LocalizedError {
    case invalidRating
    case incompleteMovie

    var errorDescription: String? {
        switch self {
        case .invalidRating: "Оценка должна быть от 1 до 10."
        case .incompleteMovie: "Дождитесь загрузки сведений о фильме."
        }
    }
}
