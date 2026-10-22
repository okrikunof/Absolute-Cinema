import SwiftData
import SwiftUI

@main
@MainActor
struct AbsoluteCinemaApp: App {
    private let repository: RatingRepository?
    private let watchlist: WatchlistRepository?
    private let client: TMDBClient

    init() {
        #if DEBUG
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--ui-testing")
        client = isUITesting ? UITestSupport.makeClient() : TMDBClient()
        #else
        let isUITesting = false
        client = TMDBClient()
        #endif

        do {
            let configuration = ModelConfiguration("DevRatings", isStoredInMemoryOnly: isUITesting)
            let container = try ModelContainer(for: RatedMovie.self, WatchlistMovie.self,
                                               configurations: configuration)

            let ratings = RatingRepository(container: container)
            #if DEBUG
            if isUITesting { try UITestSupport.seed(ratings: ratings) }
            #endif
            repository = ratings
            watchlist = WatchlistRepository(container: container)
        } catch {
            repository = nil
            watchlist = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if let repository, let watchlist {
                ContentView(repository: repository, watchlist: watchlist, client: client)
                    .preferredColorScheme(.dark)
                    .foregroundStyle(Color("PrimaryText"))
                    .tint(Color.accentColor)
            } else {
                Text("Не удалось открыть хранилище оценок. Перезапустите приложение.")
                    .padding()
            }
        }
    }
}
