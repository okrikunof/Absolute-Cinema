import SwiftUI

struct MoviePoster: View {
    let name: String?
    var posterPath: String?
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
