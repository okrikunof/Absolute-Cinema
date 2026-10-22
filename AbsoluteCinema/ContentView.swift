import SwiftUI

// Здесь находятся вкладки и переход в карточку фильма.
struct ContentView: View {
    let repository: RatingRepository
    let watchlist: WatchlistRepository
    let client: TMDBClient
    @State private var search: SearchViewModel
    @State private var ratings: RatingsViewModel
    @State private var wantedMovies: WatchlistViewModel

    init(repository: RatingRepository, watchlist: WatchlistRepository, client: TMDBClient) {
        self.repository = repository
        self.watchlist = watchlist
        self.client = client
        _search = State(initialValue: SearchViewModel(client: client))
        _ratings = State(initialValue: RatingsViewModel(repository: repository,
                                                       settings: SettingsStore()))
        _wantedMovies = State(initialValue: WatchlistViewModel(repository: watchlist))
    }

    var body: some View {
        TabView {
            NavigationStack {
                SearchView(viewModel: search)
                    .navigationDestination(for: Movie.self) { movie in
                        details(movie: movie)
                    }
            }
            .tabItem { Label("Поиск", systemImage: "magnifyingglass") }

            NavigationStack {
                RatingsView(viewModel: ratings)
                    .navigationDestination(for: Movie.self) { movie in
                        details(movie: movie)
                    }
            }
            .tabItem { Label("Мои оценки", systemImage: "star") }

            NavigationStack {
                WatchlistView(viewModel: wantedMovies)
                    .navigationDestination(for: Movie.self) { movie in
                        details(movie: movie)
                    }
            }
            .tabItem { Label("Хочу посмотреть", systemImage: "bookmark") }
        }
        .toolbarBackground(Color("Surface"), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }

    private func details(movie: Movie) -> some View {
        MovieDetailsView(viewModel: MovieDetailsViewModel(
            movie: movie, ratings: repository, watchlist: watchlist, client: client
        ))
    }
}
