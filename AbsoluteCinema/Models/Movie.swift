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
    // Поиск и тренды возвращают неполные сведения, поэтому для них hasDetails = false
    var hasDetails = true
}
