import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {
    var query = "" {
        didSet {
            if query != oldValue { queryChanged() }
        }
    }
    private(set) var movies: [Movie] = []
    private(set) var isLoading = false
    private(set) var hasSearched = false
    private(set) var errorMessage: String?
    private(set) var recentMovies: [Movie]
    private(set) var trendingMovies: [Movie] = []
    private(set) var isLoadingTrending = false
    private(set) var trendingError: String?
    private var hasRequestedTrending = false
    @ObservationIgnored private var searchTask: Task<Void, Never>?
    private let client: TMDBClient
    private let history: RecentMoviesStore

    init(client: TMDBClient, history: RecentMoviesStore) {
        self.client = client
        self.history = history
        recentMovies = history.load()
    }

    var canSearch: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func search() {
        cancelLoading()
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        movies = []
        errorMessage = nil
        hasSearched = !text.isEmpty
        guard hasSearched else { return }
        isLoading = true
        searchTask = Task {
            do {
                let loaded = try await client.searchMovies(query: text)
                // Не даём старому ответу заменить результаты нового поиска
                try Task.checkCancellation()
                movies = loaded
                isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                isLoading = false
                errorMessage = (error as? TMDBError)?.errorDescription
                    ?? "Не удалось загрузить фильмы. Попробуйте ещё раз"
            }
        }
    }

    func recordOpenedMovie(_ movie: Movie) {
        recentMovies.removeAll { $0.id == movie.id }
        recentMovies.insert(movie, at: 0)
        recentMovies = Array(recentMovies.prefix(10))
        history.save(recentMovies)
    }

    func clearRecentMovies() {
        recentMovies = []
        history.save([])
    }

    func loadTrending() {
        guard !hasRequestedTrending else { return }
        hasRequestedTrending = true
        isLoadingTrending = true
        trendingError = nil
        // Тренды продолжают загружаться, даже если пользователь открыл карточку
        Task {
            defer { isLoadingTrending = false }
            do {
                trendingMovies = try await client.trendingMovies()
            } catch {
                trendingError = (error as? TMDBError)?.errorDescription
                    ?? "Не удалось загрузить фильмы в тренде."
            }
        }
    }

    func retryTrending() {
        guard !isLoadingTrending else { return }
        hasRequestedTrending = false
        loadTrending()
    }

    private func queryChanged() {
        cancelLoading()
        movies = []
        errorMessage = nil
        hasSearched = false
    }

    func cancelLoading() {
        searchTask?.cancel()
        searchTask = nil
        if isLoading { hasSearched = false }
        isLoading = false
    }
}
