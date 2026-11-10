import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class RatingRepository {
    private(set) var revision = 0
    private let context: ModelContext

    init(container: ModelContainer) {
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    func ratings(sortedBy order: RatingSortOrder) throws -> [SavedRating] {
        var descriptors: [SortDescriptor<RatedMovie>] = []
        if order == .highestFirst {
            descriptors.append(SortDescriptor(\RatedMovie.userRating, order: .reverse))
        }
        descriptors += [SortDescriptor(\RatedMovie.ratedAt, order: .reverse),
                        SortDescriptor(\RatedMovie.movieID)]
        return try context.fetch(FetchDescriptor(sortBy: descriptors)).map(\.snapshot)
    }

    private func entry(for movieID: Int) throws -> RatedMovie? {
        let id = movieID
        var descriptor = FetchDescriptor<RatedMovie>(predicate: #Predicate { $0.movieID == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func rating(for movieID: Int) throws -> SavedRating? {
        try entry(for: movieID)?.snapshot
    }

    func save(movie: Movie, rating: Int, comment: String) throws -> SavedRating {
        guard (1...10).contains(rating) else { throw AppError.invalidRating }
        guard movie.hasDetails else { throw AppError.incompleteMovie }
        let entry: RatedMovie
        if let existing = try self.entry(for: movie.id) {
            entry = existing
            // Правка комментария не должна менять дату оценки
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
        try saveChanges()
        return entry.snapshot
    }

    func remove(movieID: Int) throws {
        guard let entry = try entry(for: movieID) else { return }
        context.delete(entry)
        try saveChanges()
    }

    private func saveChanges() throws {
        do {
            try context.save()
            revision += 1
        } catch {
            context.rollback()
            throw error
        }
    }
}
