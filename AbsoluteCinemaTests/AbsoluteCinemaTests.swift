import Foundation
import SwiftData
import XCTest
@testable import AbsoluteCinema

private func movie(_ id: Int = 62) -> Movie {
    Movie(id: id, title: "Фильм \(id)", originalTitle: "Movie \(id)", year: 1968,
          runtime: 149, overview: "Описание", genres: ["фантастика"],
          rating: 8.044, voteCount: 12960, posterName: nil)
}

private func memoryContainer() throws -> ModelContainer {
    try ModelContainer(for: RatedMovie.self,
                       configurations: ModelConfiguration(isStoredInMemoryOnly: true))
}

final class StorageTests: XCTestCase {
    @MainActor
    func testCreateReadUpdateDeleteIncludingComment() throws {
        let container = try memoryContainer()
        let repository = RatingRepository(container: container)
        XCTAssertNil(try repository.rating(for: 62))
        _ = try repository.save(movie: movie(), rating: 7, comment: "Мой отзыв 🎬\nВторая строка")
        XCTAssertEqual(try repository.rating(for: 62)?.comment, "Мой отзыв 🎬\nВторая строка")

        let updated = try repository.save(movie: movie(), rating: 9, comment: "Новое впечатление")
        XCTAssertEqual(updated.rating, 9)
        XCTAssertEqual(try repository.ratings(sortedBy: .newestFirst).count, 1)
        try repository.remove(movieID: 62)
        XCTAssertNil(try repository.rating(for: 62))
        XCTAssertTrue(try repository.ratings(sortedBy: .newestFirst).isEmpty)
    }

    @MainActor
    func testCommentEditAndSameRatingKeepDate() throws {
        let container = try memoryContainer()
        let repository = RatingRepository(container: container)
        let first = try repository.save(movie: movie(), rating: 8, comment: "")
        let updated = try repository.save(movie: movie(), rating: 8, comment: "Добавил комментарий")
        XCTAssertEqual(updated.ratedAt, first.ratedAt)
        XCTAssertEqual(updated.comment, "Добавил комментарий")
    }

    @MainActor
    func testInvalidRatingDoesNotOverwriteRecord() throws {
        let container = try memoryContainer()
        let repository = RatingRepository(container: container)
        _ = try repository.save(movie: movie(), rating: 8, comment: "Сохранённый комментарий")
        // Три набора данных одного отрицательного сценария.
        for value in [0, 11, -1] {
            XCTAssertThrowsError(
                try repository.save(movie: movie(), rating: value, comment: "Не должно сохраниться")
            ) { error in
                guard case AppError.invalidRating = error else {
                    return XCTFail("Ожидалась ошибка invalidRating, получена \(error)")
                }
            }
            XCTAssertEqual(try repository.rating(for: 62)?.rating, 8)
            XCTAssertEqual(try repository.rating(for: 62)?.comment, "Сохранённый комментарий")
        }
    }

    @MainActor
    func testSortingUsesPersonalRating() throws {
        let container = try memoryContainer()
        let repository = RatingRepository(container: container)
        _ = try repository.save(movie: movie(1), rating: 10, comment: "")
        _ = try repository.save(movie: movie(3), rating: 5, comment: "")
        _ = try repository.save(movie: movie(2), rating: 5, comment: "")
        XCTAssertEqual(try repository.ratings(sortedBy: .highestFirst).map(\.rating), [10, 5, 5])
    }

    @MainActor
    func testDiskStoreSurvivesReopeningAndDeletion() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("ratings.store")
        func open() throws -> ModelContainer {
            try ModelContainer(for: RatedMovie.self, configurations: ModelConfiguration(url: url))
        }
        do {
            let repository = RatingRepository(container: try open())
            _ = try repository.save(movie: movie(), rating: 9, comment: "Осталось после перезапуска")
        }
        do {
            let repository = RatingRepository(container: try open())
            XCTAssertEqual(try repository.rating(for: 62)?.comment, "Осталось после перезапуска")
            XCTAssertEqual(try repository.rating(for: 62)?.movie.overview, "Описание")
            try repository.remove(movieID: 62)
        }
        let reopened = RatingRepository(container: try open())
        XCTAssertTrue(try reopened.ratings(sortedBy: .newestFirst).isEmpty)
    }

    @MainActor
    func testSettingsKeepSortOrder() throws {
        let suite = "FilmGraphTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        XCTAssertEqual(settings.sortOrder, .newestFirst)
        XCTAssertNil(defaults.object(forKey: SettingsStore.sortKey))
        settings.setSortOrder(.newestFirst)
        XCTAssertEqual(defaults.string(forKey: SettingsStore.sortKey), "newestFirst")
        settings.setSortOrder(.highestFirst)
        XCTAssertEqual(SettingsStore(defaults: defaults).sortOrder, .highestFirst)
    }
}
