import Foundation

struct SavedRating: Identifiable, Equatable, Sendable {
    let movie: Movie
    let rating: Int
    let comment: String
    let ratedAt: Date

    var id: Int { movie.id }
}
