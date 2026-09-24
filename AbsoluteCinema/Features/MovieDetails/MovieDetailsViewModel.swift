import Foundation
import Observation

/// Состояние одной карточки. Изменения коллекции пока живут только в памяти.
@MainActor
@Observable
final class MovieDetailsViewModel {
    enum CollectionStatus: String, CaseIterable {
        case watchlist = "Хочу посмотреть"
        case watched = "Просмотрено"
    }

    let movie: Movie
    private(set) var collectionStatus: CollectionStatus?
    private(set) var userRating: Int?

    init(movie: Movie) {
        self.movie = movie
    }

    var metadata: String {
        "\(movie.year) · \(movie.runtime / 60) ч \(movie.runtime % 60) мин"
    }

    var formattedRating: String {
        movie.rating.formatted(.number.precision(.fractionLength(1)))
    }

    func addToWatchlist() {
        guard collectionStatus == nil else { return }
        collectionStatus = .watchlist
    }

    func setStatus(_ status: CollectionStatus) {
        collectionStatus = status
        if status == .watchlist {
            userRating = nil
        }
    }

    func rate(_ value: Int) {
        guard (1...10).contains(value) else { return }
        userRating = value
        collectionStatus = .watched
    }

    func clearRating() {
        userRating = nil
    }

    func removeFromCollection() {
        collectionStatus = nil
        userRating = nil
    }
}
