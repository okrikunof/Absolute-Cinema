import Observation

@MainActor
@Observable
final class WatchlistViewModel {
    private(set) var movies: [Movie] = []
    var errorMessage: String?
    private let repository: WatchlistRepository

    init(repository: WatchlistRepository) {
        self.repository = repository
    }

    var repositoryRevision: Int { repository.revision }

    func reload() {
        errorMessage = nil
        do {
            movies = try repository.movies()
        } catch {
            errorMessage = "Не удалось прочитать список желаемого."
        }
    }

    func remove(_ movie: Movie) {
        do {
            try repository.remove(movieID: movie.id)
        } catch {
            errorMessage = "Не удалось убрать фильм из списка."
        }
    }
}
