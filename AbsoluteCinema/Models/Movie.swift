import Foundation

struct Movie: Identifiable, Equatable {
    let id: Int
    let title: String
    let originalTitle: String
    let year: Int
    let runtime: Int
    let overview: String
    let genres: [String]
    let rating: Double
    let voteCount: Int
    let posterAssetName: String
}
