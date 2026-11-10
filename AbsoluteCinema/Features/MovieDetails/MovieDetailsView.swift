import SwiftUI

struct MovieDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MovieDetailsViewModel
    @State private var showsRatingEditor = false

    init(viewModel: MovieDetailsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                movieHeader
                detailsStatus
                personalRating
                Divider()
                movieOverview
            }
            .padding(20)
            .frame(maxWidth: 600, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color("Background"))
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Карточка фильма")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }, label: {
                    Image(systemName: "chevron.left")
                        .frame(minWidth: 44, minHeight: 44)
                })
                .accessibilityLabel("Назад")
            }
        }
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

    @ViewBuilder
    private var movieHeader: some View {
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
    }

    @ViewBuilder
    private var detailsStatus: some View {
        if viewModel.isLoadingDetails {
            ProgressView("Загружаем сведения…")
        }
        if let message = viewModel.detailsError {
            ErrorNotice(message: message, retry: viewModel.retryDetails)
        }
    }

    private var personalRating: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    showsRatingEditor = true
                } label: {
                    Label(viewModel.savedRating == nil ? "Оценить" : "Изменить",
                          systemImage: "star")
                        .frame(maxWidth: .infinity, minHeight: 32)
                }
                .buttonStyle(.borderedProminent)
                .foregroundStyle(Color("Background"))
                .disabled(!viewModel.canRate)
                .accessibilityIdentifier("details.editRating")

                Button(action: viewModel.toggleWatchlist) {
                    Label(viewModel.isWatchlisted ? "В списке" : "Смотреть",
                          systemImage: viewModel.isWatchlisted ? "bookmark.fill" : "bookmark")
                        .frame(maxWidth: .infinity, minHeight: 32)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canToggleWatchlist)
                .accessibilityLabel(viewModel.isWatchlisted ? "Убрать из желаемого" : "Хочу посмотреть")
                .accessibilityIdentifier("details.watchlist")
            }

            if !viewModel.canRate {
                Text("Сохранение станет доступно после загрузки полной карточки.")
                    .font(.caption).foregroundStyle(Color("SecondaryText"))
            }

            if let saved = viewModel.savedRating {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Моя оценка: \(saved.rating) из 10").font(.headline)
                        .accessibilityIdentifier("details.savedRating")
                    Text(saved.ratedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption).foregroundStyle(Color("SecondaryText"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 16))

                ratingSubmission
            }
            if let message = viewModel.saveMessage {
                Text(message).font(.caption).foregroundStyle(Color("SecondaryText"))
            }
        }
    }

    @ViewBuilder
    private var ratingSubmission: some View {
        Button(action: viewModel.sendSavedRating) {
            HStack {
                if viewModel.isSendingRating { ProgressView() }
                Text(viewModel.isSendingRating ? "Отправляем…" : "Отправить в TMDB")
            }
        }
        .buttonStyle(.bordered)
        .font(.subheadline)
        .disabled(!viewModel.canSendRating)
        if let message = viewModel.ratingSendError {
            ErrorNotice(message: message, retry: viewModel.sendSavedRating)
        }
        if let message = viewModel.ratingSendMessage {
            Text(message).font(.caption).foregroundStyle(Color("SecondaryText"))
        }
    }

    private var movieOverview: some View {
        let movie = viewModel.movie
        return VStack(alignment: .leading, spacing: 10) {
            Text("Описание").font(.headline)
            Text(movie.overview.isEmpty ? "Описание пока отсутствует." : movie.overview)
                .lineSpacing(4)
        }
    }
}
