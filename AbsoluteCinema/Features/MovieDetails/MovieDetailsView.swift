import SwiftUI

struct MovieDetailsView: View {
    @State private var viewModel: MovieDetailsViewModel
    @State private var showsRatingEditor = false

    init(viewModel: MovieDetailsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                let movie = viewModel.movie
                MoviePoster(name: movie.posterName, posterPath: movie.posterPath)
                    .frame(height: 280)
                    .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 8) {
                    Text(movie.title).font(.title2.bold())
                    Text(movie.originalTitle).font(.subheadline)
                        .foregroundStyle(Color("SecondaryText"))
                    Text(viewModel.metadata).font(.subheadline)
                    Text(movie.genres.isEmpty ? "Жанры не указаны" : movie.genres.joined(separator: " · "))
                        .font(.subheadline).foregroundStyle(Color("SecondaryText"))
                }
                HStack {
                    Label(movie.voteCount > 0
                          ? movie.rating.formatted(.number.precision(.fractionLength(1))) : "Нет оценок",
                          systemImage: "star.fill")
                        .foregroundStyle(Color.accentColor)
                    Text("TMDB · \(movie.voteCount.formatted()) голосов")
                        .foregroundStyle(Color("SecondaryText"))
                }
                .font(.subheadline)

                if viewModel.isLoadingDetails {
                    ProgressView("Загружаем сведения…")
                }
                if let message = viewModel.detailsError {
                    ErrorNotice(message: message, retry: viewModel.retryDetails)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Button(viewModel.savedRating == nil ? "Оценить" : "Изменить оценку") {
                        showsRatingEditor = true
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundStyle(Color("Background"))
                    .disabled(!viewModel.canRate)
                    .accessibilityIdentifier("details.editRating")

                    Button(action: viewModel.toggleWatchlist) {
                        Label(viewModel.isWatchlisted ? "Убрать из желаемого" : "Хочу посмотреть",
                              systemImage: viewModel.isWatchlisted ? "bookmark.fill" : "bookmark")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.canToggleWatchlist)

                    if !viewModel.canRate {
                        Text("Сохранение станет доступно после загрузки полной карточки.")
                            .font(.caption).foregroundStyle(Color("SecondaryText"))
                    }

                    if let saved = viewModel.savedRating {
                        Text("Моя оценка: \(saved.rating) из 10").font(.headline)
                            .accessibilityIdentifier("details.savedRating")
                        if !saved.comment.isEmpty {
                            Text(saved.comment)
                                .accessibilityIdentifier("details.savedComment")
                        }
                        Text("Дата оценки: \(saved.ratedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption).foregroundStyle(Color("SecondaryText"))
                        Button(action: viewModel.sendSavedRating) {
                            HStack {
                                if viewModel.isSendingRating { ProgressView() }
                                Text(viewModel.isSendingRating ? "Отправляем оценку…" : "Отправить оценку в TMDB")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendRating)
                        Text("В гостевую сессию TMDB отправляется только число. Комментарий остаётся на устройстве.")
                            .font(.caption).foregroundStyle(Color("SecondaryText"))
                        if let message = viewModel.ratingSendError {
                            ErrorNotice(message: message, retry: viewModel.sendSavedRating)
                        }
                        if let message = viewModel.ratingSendMessage {
                            Text(message).font(.caption).foregroundStyle(Color("SecondaryText"))
                        }
                        Button("Убрать оценку и комментарий", role: .destructive,
                               action: viewModel.removeRating)
                    }
                    if let message = viewModel.saveMessage {
                        Text(message).font(.caption).foregroundStyle(Color("SecondaryText"))
                    }
                }
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Text("Описание").font(.headline)
                    Text(movie.overview.isEmpty ? "Описание пока отсутствует." : movie.overview)
                        .lineSpacing(4)
                }

            }
            .padding(20)
            .frame(maxWidth: 600, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color("Background"))
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Карточка фильма")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadRating()
            viewModel.loadWatchlist()
        }
        .task(id: viewModel.detailsRequestID) { await viewModel.loadDetails() }
        .onDisappear { viewModel.cancelSendingRating() }
        .onChange(of: viewModel.repositoryRevision) { _, _ in viewModel.loadRating() }
        .onChange(of: viewModel.watchlistRevision) { _, _ in viewModel.loadWatchlist() }
        .sheet(isPresented: $showsRatingEditor, onDismiss: viewModel.discardRatingChanges) {
            RatingEditorView(viewModel: viewModel)
        }
        .alert("Не удалось выполнить действие", isPresented: Binding(
            get: { viewModel.storageError != nil && !showsRatingEditor },
            set: { if !$0 { viewModel.storageError = nil } }
        )) {
            Button("Понятно", role: .cancel) { viewModel.storageError = nil }
        } message: {
            Text(viewModel.storageError ?? "")
        }
    }
}
