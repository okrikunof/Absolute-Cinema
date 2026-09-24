import SwiftUI

@main
struct AbsoluteCinemaApp: App {
    var body: some Scene {
        WindowGroup {
            MovieDetailsView(viewModel: MovieDetailsViewModel(movie: MovieMock.spaceOdyssey))
        }
    }
}
