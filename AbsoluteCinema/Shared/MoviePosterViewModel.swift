import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class MoviePosterViewModel {
    private(set) var image: UIImage?

    func load(name: String?, posterPath: String?, pixelSize: CGFloat) async {
        image = nil
        var original: UIImage?
        if let posterPath {
            let size = pixelSize <= 270 ? "w185" : "w500"
            if let url = URL(string: "https://image.tmdb.org/t/p/\(size)\(posterPath)") {
                do {
                    let (data, response) = try await URLSession.shared.data(from: url)
                    if let response = response as? HTTPURLResponse,
                       (200..<300).contains(response.statusCode) {
                        original = UIImage(data: data)
                    }
                } catch {
                    // Ошибка постера не мешает читать карточку и сохранять оценку.
                }
            }
        }
        if original == nil, let name {
            original = UIImage(named: name)
        }
        guard !Task.isCancelled, let original else { return }
        // UIKit подготавливает уменьшенное изображение в фоне
        let thumbnail = await original.byPreparingThumbnail(
            ofSize: CGSize(width: pixelSize, height: pixelSize)
        )
        guard !Task.isCancelled else { return }
        image = thumbnail ?? original
    }
}
