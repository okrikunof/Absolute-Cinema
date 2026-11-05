import Foundation

struct Movie: Identifiable, Hashable, Sendable, Codable {
    let id: Int
    let title: String
    let originalTitle: String
    let year: Int?
    let runtime: Int?
    let overview: String
    let genres: [String]
    let rating: Double
    let voteCount: Int
    let posterName: String?
    var posterPath: String?
    // Сохранённые фильмы и моки содержат полную карточку; результаты поиска — нет.
    var hasDetails = true
}
