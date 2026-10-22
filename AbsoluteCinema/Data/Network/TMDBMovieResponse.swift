import Foundation

struct TMDBMovieListResponse: Decodable, Sendable {
    let results: [TMDBMovieResponse]
}

// Список и карточка имеют общие поля. runtime и genres приходят только в карточке.
struct TMDBMovieResponse: Decodable, Sendable {
    let id: Int
    let title: String
    let originalTitle: String
    let releaseDate: String?
    let runtime: Int?
    let overview: String?
    let genres: [TMDBGenreResponse]?
    let voteAverage: Double?
    let voteCount: Int?
    let posterPath: String?

    private enum CodingKeys: String, CodingKey {
        case id, title, runtime, overview, genres
        case originalTitle = "original_title"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case posterPath = "poster_path"
    }

    func movie(hasDetails: Bool) -> Movie {
        Movie(
            id: id,
            title: title,
            originalTitle: originalTitle,
            year: releaseDate.flatMap { Int($0.prefix(4)) },
            runtime: runtime.flatMap { $0 > 0 ? $0 : nil },
            overview: overview ?? "",
            genres: genres?.map(\.name) ?? [],
            rating: voteAverage ?? 0,
            voteCount: voteCount ?? 0,
            posterName: nil,
            posterPath: posterPath?.isEmpty == false ? posterPath : nil,
            hasDetails: hasDetails
        )
    }
}

struct TMDBGenreResponse: Decodable, Sendable {
    let name: String
}
