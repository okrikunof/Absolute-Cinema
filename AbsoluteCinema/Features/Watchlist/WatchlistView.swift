import SwiftUI

struct WatchlistView: View {
    let viewModel: WatchlistViewModel

    var body: some View {
        VStack(spacing: 0) {
            if let message = viewModel.errorMessage {
                ErrorNotice(message: message, retry: viewModel.reload)
            }
            if viewModel.movies.isEmpty, viewModel.errorMessage == nil {
                ContentUnavailableView("Список пока пуст", systemImage: "bookmark",
                                       description: Text("Добавьте фильм через кнопку «Хочу посмотреть» в карточке."))
            } else {
                List(viewModel.movies) { movie in
                    NavigationLink(value: movie) {
                        MovieRow(movie: movie)
                    }
                    .listRowBackground(Color("Background"))
                    .swipeActions {
                        Button("Убрать из списка", role: .destructive) { viewModel.remove(movie) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Background"))
        .navigationTitle("Хочу посмотреть")
        .onAppear { viewModel.reload() }
        .onChange(of: viewModel.repositoryRevision) { _, _ in viewModel.reload() }
    }
}
