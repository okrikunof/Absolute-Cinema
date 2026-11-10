import SwiftUI

struct RatingsView: View {
    let viewModel: RatingsViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Сортировка", selection: Binding(
                    get: { viewModel.sortOrder },
                    set: { viewModel.setSortOrder($0) }
                )) {
                    ForEach(RatingSortOrder.allCases) { order in
                        Text(order.title).tag(order)
                    }
                }
                .pickerStyle(.menu)
                Spacer()
            }
            .padding(.horizontal)

            if let message = viewModel.errorMessage {
                ErrorNotice(message: message, retry: viewModel.reload)
            }
            if viewModel.entries.isEmpty, viewModel.errorMessage == nil {
                ContentUnavailableView("Пока нет оценок", systemImage: "star",
                                       description: Text("Найдите фильм и сохраните свою оценку в его карточке."))
            } else {
                List(viewModel.entries) { entry in
                    NavigationLink(value: entry.movie) {
                        RatedMovieRow(entry: entry)
                    }
                    .accessibilityIdentifier("ratings.movie.\(entry.movie.id)")
                    .listRowBackground(Color("Background"))
                    .swipeActions {
                        Button("Убрать оценку", role: .destructive) { viewModel.remove(entry) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Background"))
        .navigationTitle("Мои оценки")
        .onAppear { viewModel.reload() }
        .onChange(of: viewModel.repositoryRevision) { _, _ in viewModel.reload() }
    }
}

private struct RatedMovieRow: View {
    let entry: SavedRating

    var body: some View {
        HStack(spacing: 12) {
            MoviePoster(name: entry.movie.posterName, posterPath: entry.movie.posterPath,
                        pixelSize: 270)
                .frame(width: 60, height: 90)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.movie.title)
                    .font(.headline)
                Text(entry.movie.year.map(String.init) ?? "Год не указан")
                    .font(.subheadline)
                    .foregroundStyle(Color("SecondaryText"))
                Text("TMDB: \(entry.movie.rating.formatted(.number.precision(.fractionLength(1)))) / 10")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }

            Spacer(minLength: 4)

            VStack(spacing: 12) {
                Text("Моя оценка")
                    .font(.caption2)
                    .foregroundStyle(Color("SecondaryText"))
                Text("\(entry.rating)")
                    .font(.headline.bold())
                    .foregroundStyle(RatingColors.color(for: entry.rating))
                    .frame(width: 36, height: 36)
                    .background(RatingColors.color(for: entry.rating).opacity(0.16), in: Circle())
                    .overlay {
                        Circle().strokeBorder(RatingColors.color(for: entry.rating), lineWidth: 1)
                    }
                Text("из 10")
                    .font(.caption2)
                    .foregroundStyle(Color("SecondaryText"))
            }
            .fixedSize()
        }
        .padding(.vertical, 6)
    }
}
