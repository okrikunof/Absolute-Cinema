import SwiftUI

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
