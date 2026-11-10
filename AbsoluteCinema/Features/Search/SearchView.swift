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
                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color("SecondaryText"))
                    }
                    .accessibilityLabel("Очистить поиск")
                }
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
                discoveryContent
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
        .onAppear { viewModel.loadTrending() }
        .onDisappear { viewModel.cancelLoading() }
    }

    private var discoveryContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("В тренде").font(.title2.bold())
                        Text("Популярное на этой неделе")
                            .font(.subheadline).foregroundStyle(Color("SecondaryText"))
                    }
                    .padding(.horizontal)

                    if viewModel.isLoadingTrending {
                        ProgressView("Загружаем фильмы…")
                            .frame(maxWidth: .infinity).padding(32)
                    } else if let message = viewModel.trendingError {
                        ErrorNotice(message: message, retry: viewModel.retryTrending)
                    } else if viewModel.trendingMovies.isEmpty {
                        Text("Подборка пока пуста. Найдите фильм по названию.")
                            .foregroundStyle(Color("SecondaryText")).padding(.horizontal)
                    } else {
                        movieCarousel(viewModel.trendingMovies)
                    }
                }

                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Недавно открывали").font(.title2.bold())
                        Spacer()
                        if !viewModel.recentMovies.isEmpty {
                            Button("Очистить", action: viewModel.clearRecentMovies)
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal)

                    if viewModel.recentMovies.isEmpty {
                        Text("Здесь появятся фильмы, карточки которых вы недавно открывали.")
                            .font(.subheadline)
                            .foregroundStyle(Color("SecondaryText"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .frame(maxWidth: .infinity, minHeight: 80)
                    } else {
                        movieCarousel(viewModel.recentMovies)
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.bottom, 14)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func movieCarousel(_ movies: [Movie]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(movies) { movie in
                    NavigationLink(value: movie) {
                        VStack(alignment: .leading, spacing: 6) {
                            MoviePoster(name: movie.posterName, posterPath: movie.posterPath,
                                        pixelSize: 360)
                                .frame(width: 116, height: 174)
                            Text(movie.title)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(2, reservesSpace: true)
                            HStack {
                                Text(movie.year.map(String.init) ?? "—")
                                Spacer()
                                Label(movie.rating.formatted(.number.precision(.fractionLength(1))),
                                      systemImage: "star.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                            .font(.caption)
                            .foregroundStyle(Color("SecondaryText"))
                        }
                        .frame(width: 116)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private func submitSearch() {
        isSearchFocused = false
        viewModel.search()
    }
}
