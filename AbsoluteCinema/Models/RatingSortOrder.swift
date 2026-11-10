import Foundation

enum RatingSortOrder: String, CaseIterable, Identifiable, Sendable {
    case newestFirst
    case highestFirst

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newestFirst: "Сначала недавние"
        case .highestFirst: "Сначала высокая оценка"
        }
    }
}
