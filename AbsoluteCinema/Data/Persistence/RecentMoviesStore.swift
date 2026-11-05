import Foundation

// Храним только десять последних открытых карточек, без оценок и комментариев.
final class RecentMoviesStore {
    private let defaults: UserDefaults
    private let key = "dev.search.recentMovies"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [Movie] {
        guard let data = defaults.data(forKey: key),
              let movies = try? JSONDecoder().decode([Movie].self, from: data) else {
            return []
        }
        return movies
    }

    func save(_ movies: [Movie]) {
        guard let data = try? JSONEncoder().encode(movies) else { return }
        defaults.set(data, forKey: key)
    }
}
