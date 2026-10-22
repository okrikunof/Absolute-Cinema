import SwiftUI

// Общее оформление постера для поиска, карточки и списка оценок
struct MoviePoster: View {
    let name: String?
    var posterPath: String? = nil
    var pixelSize: CGFloat = 900
    @State private var viewModel = MoviePosterViewModel()

    private struct PosterRequest: Hashable {
        let name: String?
        let posterPath: String?
        let pixelSize: CGFloat
    }

    var body: some View {
        Group {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                // Заглушка остаётся и при отсутствии постера, и при ошибке загрузки.
                ZStack {
                    Color("Surface")
                    Image(systemName: "film")
                        .font(.title2)
                        .foregroundStyle(Color("SecondaryText"))
                }
                .aspectRatio(2.0 / 3.0, contentMode: .fit)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityHidden(true)
        .task(id: PosterRequest(name: name, posterPath: posterPath, pixelSize: pixelSize)) {
            await viewModel.load(name: name, posterPath: posterPath, pixelSize: pixelSize)
        }
    }
}

struct MovieRow: View {
    let movie: Movie

    var body: some View {
        HStack(spacing: 14) {
            MoviePoster(name: movie.posterName, posterPath: movie.posterPath, pixelSize: 270)
                .frame(width: 54, height: 81)
            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title).font(.headline)
                Text(movie.year.map(String.init) ?? "Год не указан")
                    .font(.caption)
                Text("TMDB: \(movie.rating.formatted(.number.precision(.fractionLength(1)))) / 10")
                    .font(.caption)
            }
            .foregroundStyle(Color("PrimaryText"))
        }
        .padding(.vertical, 4)
    }
}
