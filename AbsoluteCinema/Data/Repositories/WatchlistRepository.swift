import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class WatchlistRepository {
    private(set) var revision = 0
    private let container: ModelContainer
    private let context: ModelContext

    init(container: ModelContainer) {
        self.container = container
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    func moviesInBackground() async throws -> [Movie] {
        let container = container
        // Создаём контекст вне MainActor, чтобы чтение не занимало поток интерфейса.
        return try await Task.detached(priority: .userInitiated) {
            let reader = SavedMoviesReader(modelContainer: container)
            return try await reader.watchlist()
        }.value
    }

    private func entry(for movieID: Int) throws -> WatchlistMovie? {
        let id = movieID
        var descriptor = FetchDescriptor<WatchlistMovie>(predicate: #Predicate { $0.movieID == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func contains(movieID: Int) throws -> Bool {
        try entry(for: movieID) != nil
    }

    func movie(for movieID: Int) throws -> Movie? {
        try entry(for: movieID)?.movie
    }

    func movies() throws -> [Movie] {
        let descriptor = FetchDescriptor<WatchlistMovie>(sortBy: [
            SortDescriptor(\WatchlistMovie.addedAt, order: .reverse),
            SortDescriptor(\WatchlistMovie.movieID)
        ])
        return try context.fetch(descriptor).map(\.movie)
    }

    func add(_ movie: Movie) throws {
        guard movie.hasDetails else { throw AppError.incompleteMovie }
        guard try !contains(movieID: movie.id) else { return }
        context.insert(WatchlistMovie(movie: movie))
        try saveChanges()
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
