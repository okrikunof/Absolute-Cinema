import Foundation
import SwiftData

@Model
final class RatedMovie {
    @Attribute(.unique) var movieID: Int
    var title: String
    var originalTitle: String
    var year: Int?
    var runtime: Int?
    var overview: String
    var genres: [String]
    var tmdbRating: Double
    var voteCount: Int
    var posterName: String?
    var posterPath: String?
    var userRating: Int
    var comment: String
    var ratedAt: Date

    init(movie: Movie, rating: Int, comment: String, ratedAt: Date) {
        movieID = movie.id
        title = movie.title
        originalTitle = movie.originalTitle
        year = movie.year
        runtime = movie.runtime
        overview = movie.overview
        genres = movie.genres
        tmdbRating = movie.rating
        voteCount = movie.voteCount
        posterName = movie.posterName
        posterPath = movie.posterPath
        userRating = rating
        self.comment = comment
        self.ratedAt = ratedAt
    }

    // для экрана возвращаем обычную структуру
    var snapshot: SavedRating {
        SavedRating(
            movie: Movie(
                id: movieID,
                title: title,
                originalTitle: originalTitle,
                year: year,
                runtime: runtime,
                overview: overview,
                genres: genres,
                rating: tmdbRating,
                voteCount: voteCount,
                posterName: posterName,
                posterPath: posterPath
            ),
            rating: userRating,
            comment: comment,
            ratedAt: ratedAt
        )
    }

    func updateMovie(_ movie: Movie) {
        title = movie.title
        originalTitle = movie.originalTitle
        year = movie.year
        runtime = movie.runtime
        overview = movie.overview
        genres = movie.genres
        tmdbRating = movie.rating
        voteCount = movie.voteCount
        posterName = movie.posterName ?? posterName
        posterPath = movie.posterPath ?? posterPath
    }
}
