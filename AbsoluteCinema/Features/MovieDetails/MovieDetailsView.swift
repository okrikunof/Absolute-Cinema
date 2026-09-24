import SwiftUI

struct MovieDetailsView: View {
    @State private var viewModel: MovieDetailsViewModel

    init(viewModel: MovieDetailsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    Label("FILMGRAPH", systemImage: "film")
                        .font(.caption.weight(.bold)).tracking(3)
                    Spacer()
                    Text("О фильме").font(.caption)
                        .foregroundStyle(Color("SecondaryText"))
                }

                Image(viewModel.movie.posterAssetName)
                    .resizable().scaledToFit().frame(maxWidth: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.4), radius: 24, y: 12)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Постер: \(viewModel.movie.title)")

                VStack(alignment: .leading, spacing: 10) {
                    Text(viewModel.metadata)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Color.accentColor)
                    Text(viewModel.movie.title)
                        .font(.largeTitle.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(viewModel.movie.originalTitle)
                        .font(.subheadline).foregroundStyle(Color("SecondaryText"))
                    Text(viewModel.movie.genres.joined(separator: " · "))
                        .font(.subheadline).foregroundStyle(Color("SecondaryText"))
                }

                HStack(spacing: 16) {
                    Label(viewModel.formattedRating, systemImage: "star.fill")
                        .font(.title2.bold()).foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Рейтинг TMDB").font(.subheadline.weight(.semibold))
                        Text("\(viewModel.movie.voteCount.formatted()) голосов · из 10")
                            .font(.caption).foregroundStyle(Color("SecondaryText"))
                    }
                    Spacer(minLength: 0)
                }
                .padding(18)
                .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 16))

                collection

                VStack(alignment: .leading, spacing: 12) {
                    Text("О фильме").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                    Text(viewModel.movie.overview)
                        .font(.body).lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Данные и постер: TMDB").font(.caption.weight(.semibold))
                    Text("This product uses the TMDB API but is not endorsed or certified by TMDB.")
                        .font(.caption2)
                }
                .foregroundStyle(Color("SecondaryText"))
            }
            .padding(24).frame(maxWidth: 600).frame(maxWidth: .infinity)
        }
        .background(Color("Background"))
        .foregroundStyle(Color("PrimaryText"))
        .preferredColorScheme(.dark)
    }

    private var collection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let status = viewModel.collectionStatus {
                Label("В моей коллекции", systemImage: "checkmark.circle.fill")
                    .font(.headline).foregroundStyle(Color.accentColor)
                Menu {
                    ForEach(MovieDetailsViewModel.CollectionStatus.allCases, id: \.self) { value in
                        Button(value.rawValue) { viewModel.setStatus(value) }
                    }
                } label: {
                    HStack {
                        Text(status.rawValue)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .padding(16)
                    .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 14))
                }
                .accessibilityLabel("Статус: \(status.rawValue). Изменить")
            } else {
                Button(action: viewModel.addToWatchlist) {
                    Label("Хочу посмотреть", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color("Background"))
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
            }

            ViewThatFits(in: .horizontal) {
                HStack { ratingLabel; Spacer(); ratingMenu }
                VStack(alignment: .leading, spacing: 12) { ratingLabel; ratingMenu }
            }

            if viewModel.collectionStatus != nil {
                Button("Удалить из коллекции", role: .destructive, action: viewModel.removeFromCollection)
                    .font(.subheadline).padding(.vertical, 8)
            }
        }
    }

    private var ratingLabel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Моя оценка").font(.headline)
            Text(viewModel.userRating.map { "\($0) из 10" } ?? "Пока без оценки")
                .font(.subheadline).foregroundStyle(Color("SecondaryText"))
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var ratingMenu: some View {
        Menu {
            ForEach(1...10, id: \.self) { rating in
                Button("\(rating) из 10") { viewModel.rate(rating) }
            }
            if viewModel.userRating != nil {
                Button("Убрать оценку", action: viewModel.clearRating)
            }
        } label: {
            Text(viewModel.userRating == nil ? "Оценить" : "Изменить")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Color("Surface"), in: Capsule())
        }
        .accessibilityLabel("Изменить мою оценку")
    }
}

#Preview {
    MovieDetailsView(viewModel: MovieDetailsViewModel(movie: MovieMock.spaceOdyssey))
}
