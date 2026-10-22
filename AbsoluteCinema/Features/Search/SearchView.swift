import SwiftUI

struct SearchView: View {
    @Bindable var viewModel: SearchViewModel
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color("SecondaryText"))
                TextField("Поиск фильмов", text: $viewModel.query)
                    .accessibilityIdentifier("search.query")
                    .submitLabel(.search)
                    .focused($isSearchFocused)
                    .onSubmit(submitSearch)
                Button("Найти", action: submitSearch)
                    .accessibilityIdentifier("search.submit")
                    .disabled(!viewModel.canSearch)
            }
            .padding(14)
            .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 10))
            .padding()

            if viewModel.isLoading {
                ProgressView("Ищем фильмы…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let message = viewModel.errorMessage {
                ErrorNotice(message: message, retry: submitSearch)
            } else if !viewModel.hasSearched {
                ContentUnavailableView("Найдите фильм", systemImage: "magnifyingglass",
                                       description: Text("Введите название и нажмите «Найти»."))
            } else if viewModel.movies.isEmpty {
                ContentUnavailableView("Ничего не найдено", systemImage: "magnifyingglass",
                                       description: Text("Попробуйте другое название."))
            } else {
                List(viewModel.movies) { movie in
                    NavigationLink(value: movie) {
                        MovieRow(movie: movie)
                    }
                    .accessibilityIdentifier("search.result.\(movie.id)")
                    .listRowBackground(Color("Background"))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Background"))
        .navigationTitle("Поиск")
        .onDisappear { viewModel.cancelLoading() }
    }

    private func submitSearch() {
        isSearchFocused = false
        viewModel.search()
    }
}
