import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class RatingRepository {
    private(set) var revision = 0
    private let container: ModelContainer
    private let context: ModelContext

    init(container: ModelContainer) {
        self.container = container
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    func ratingsInBackground(sortedBy order: RatingSortOrder) async throws -> [SavedRating] {
        let container = container
        // Создаём контекст вне MainActor, чтобы чтение не занимало поток интерфейса.
        return try await Task.detached(priority: .userInitiated) {
            let reader = SavedMoviesReader(modelContainer: container)
            return try await reader.ratings(sortedBy: order)
        }.value
    }

    private func entry(for movieID: Int) throws -> RatedMovie? {
        let id = movieID
        var descriptor = FetchDescriptor<RatedMovie>(predicate: #Predicate { $0.movieID == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    // найти одну сохранённую оценку по ID фильма
    func rating(for movieID: Int) throws -> SavedRating? {
        try entry(for: movieID)?.snapshot
    }

    // прочитать все оценки в выбранном порядке
    func ratings(sortedBy order: RatingSortOrder) throws -> [SavedRating] {
        var descriptors: [SortDescriptor<RatedMovie>] = []
        if order == .highestFirst {
            descriptors.append(SortDescriptor(\RatedMovie.userRating, order: .reverse))
        }
        descriptors += [SortDescriptor(\RatedMovie.ratedAt, order: .reverse),
                        SortDescriptor(\RatedMovie.movieID)]
        return try context.fetch(FetchDescriptor(sortBy: descriptors)).map(\.snapshot)
    }

    // для одного фильма хранится только одна запись
    func save(movie: Movie, rating: Int, comment: String) throws -> SavedRating {
        guard (1...10).contains(rating) else { throw AppError.invalidRating }
        guard movie.hasDetails else { throw AppError.incompleteMovie }
        let entry: RatedMovie
        if let existing = try self.entry(for: movie.id) {
            entry = existing
            // изменение только комментария не меняет дату выставления оценки
            if existing.userRating != rating {
                existing.ratedAt = Date()
            }
            existing.userRating = rating
            existing.comment = comment
            existing.updateMovie(movie)
        } else {
            entry = RatedMovie(movie: movie, rating: rating, comment: comment, ratedAt: Date())
            context.insert(entry)
        }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        revision += 1
        return entry.snapshot
    }

    // удалить запись с оценкой и комментарием.
    func remove(movieID: Int) throws {
        guard let entry = try entry(for: movieID) else { return }
        context.delete(entry)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        revision += 1
    }
}
