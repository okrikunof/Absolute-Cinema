import SwiftData
import XCTest
@testable import AbsoluteCinema

final class RatingTests: XCTestCase {
    @MainActor
    func testUpdatingCommentKeepsDateAndDoesNotDuplicateRating() throws {
        let container = try makeContainer()
        let movie = try XCTUnwrap(MockMovies.movies.first)
        let originalDate = Date(timeIntervalSince1970: 1_000)
        // Берём старую дату, чтобы заметить её случайное обновление при сохранении
        let context = ModelContext(container)
        context.insert(RatedMovie(movie: movie, rating: 8, comment: "Первый отзыв", ratedAt: originalDate))
        try context.save()

        let repository = RatingRepository(container: container)
        _ = try repository.save(movie: movie, rating: 8, comment: "Уточнённый отзыв")

        // Читаем через другой контекст, чтобы проверить сохранение в базу
        let reader = ModelContext(container)
        let entries = try reader.fetch(FetchDescriptor<RatedMovie>())
        XCTAssertEqual(entries.count, 1)
        let saved = try XCTUnwrap(entries.first)
        XCTAssertEqual(saved.movieID, movie.id)
        XCTAssertEqual(saved.userRating, 8)
        XCTAssertEqual(saved.comment, "Уточнённый отзыв")
        XCTAssertEqual(saved.ratedAt, originalDate)
    }

    @MainActor
    func testDeletingRatingKeepsMovieInWatchlist() throws {
        let container = try makeContainer()
        let movie = try XCTUnwrap(MockMovies.movies.first)
        let ratings = RatingRepository(container: container)
        let watchlist = WatchlistRepository(container: container)
        _ = try ratings.save(movie: movie, rating: 8, comment: "Пересмотреть")
        try watchlist.add(movie)

        try ratings.remove(movieID: movie.id)

        let savedRatings = RatingRepository(container: container)
        let savedWatchlist = WatchlistRepository(container: container)
        XCTAssertNil(try savedRatings.rating(for: movie.id))
        XCTAssertEqual(try savedWatchlist.movie(for: movie.id), movie)
    }

    @MainActor
    func testInvalidRatingDoesNotOverwriteSavedData() throws {
        let container = try makeContainer()
        let movie = try XCTUnwrap(MockMovies.movies.first)
        let repository = RatingRepository(container: container)
        let original = try repository.save(movie: movie, rating: 8, comment: "Сохранённый отзыв")

        for invalidRating in [0, 11] {
            XCTAssertThrowsError(try repository.save(movie: movie, rating: invalidRating, comment: "Замена")) {
                guard case AppError.invalidRating = $0 else {
                    return XCTFail("Ожидалась ошибка диапазона оценки, получена: \($0)")
                }
            }
            let reader = RatingRepository(container: container)
            XCTAssertEqual(try reader.rating(for: movie.id), original)
        }
    }

    @MainActor
    func testDiscardingDraftRestoresSavedRatingAndComment() throws {
        let container = try makeContainer()
        let movie = try XCTUnwrap(MockMovies.movies.first)
        let ratings = RatingRepository(container: container)
        let original = try ratings.save(movie: movie, rating: 8, comment: "Сохранённый отзыв")
        let viewModel = MovieDetailsViewModel(
            movie: movie, ratings: ratings,
            watchlist: WatchlistRepository(container: container), client: TMDBClient()
        )
        viewModel.loadRating()
        viewModel.draftRating = 5
        viewModel.comment = "Несохранённый отзыв"
        XCTAssertTrue(viewModel.canSave)

        // Повторное чтение не должно затирать черновик
        viewModel.loadRating()
        XCTAssertEqual(viewModel.draftRating, 5)
        XCTAssertEqual(viewModel.comment, "Несохранённый отзыв")

        viewModel.discardRatingChanges()

        XCTAssertEqual(viewModel.draftRating, 8)
        XCTAssertEqual(viewModel.comment, "Сохранённый отзыв")
        XCTAssertFalse(viewModel.hasChanges)
        XCTAssertFalse(viewModel.canSave)
        let reader = RatingRepository(container: container)
        XCTAssertEqual(try reader.rating(for: movie.id), original)
    }

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: RatedMovie.self, WatchlistMovie.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}
