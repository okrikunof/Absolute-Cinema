import Foundation
import SwiftData

@Model
final class WatchlistMovie {
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
    var addedAt: Date

    init(movie: Movie) {
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
        addedAt = Date()
    }

    // Список хранит и описание, чтобы карточка открывалась без исходного массива моков.
    var movie: Movie {
        Movie(id: movieID, title: title, originalTitle: originalTitle,
              year: year, runtime: runtime, overview: overview, genres: genres,
              rating: tmdbRating, voteCount: voteCount, posterName: posterName,
              posterPath: posterPath)
    }
}
