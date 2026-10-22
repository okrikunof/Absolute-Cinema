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
    @ObservationIgnored private var searchTask: Task<Void, Never>?
    private let client: TMDBClient

    init(client: TMDBClient) {
        self.client = client
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
                // Отменённый запрос не должен заменять результаты нового поиска.
                try Task.checkCancellation()
                movies = loaded
                isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                isLoading = false
                errorMessage = (error as? TMDBError)?.errorDescription
                    ?? "Не удалось загрузить фильмы. Попробуйте ещё раз."
            }
        }
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
