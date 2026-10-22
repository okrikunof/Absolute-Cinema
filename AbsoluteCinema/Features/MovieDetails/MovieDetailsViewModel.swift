import Foundation
import Observation

@MainActor
@Observable
final class MovieDetailsViewModel {
    private(set) var movie: Movie
    var draftRating = 0
    var comment = ""
    var storageError: String?
    private(set) var savedRating: SavedRating?
    private(set) var saveMessage: String?
    private(set) var isWatchlisted = false
    private(set) var isLoadingDetails = false
    private(set) var detailsError: String?
    private(set) var detailsRequestID = 0
    private(set) var isSendingRating = false
    private(set) var ratingSendError: String?
    private(set) var ratingSendMessage: String?
    private var sentRating: Int?
    @ObservationIgnored private var ratingSendTask: Task<Void, Never>?
    private let client: TMDBClient
    private let ratings: RatingRepository
    private let watchlist: WatchlistRepository
    private var didLoadRating = false
    private var didLoadDetails = false

    init(movie: Movie, ratings: RatingRepository, watchlist: WatchlistRepository,
         client: TMDBClient) {
        self.movie = movie
        self.ratings = ratings
        self.watchlist = watchlist
        self.client = client
    }

    var repositoryRevision: Int { ratings.revision }
    var watchlistRevision: Int { watchlist.revision }
    var canRate: Bool { movie.hasDetails }
    var canToggleWatchlist: Bool { movie.hasDetails || isWatchlisted }
    var canSendRating: Bool {
        guard let savedRating else { return false }
        return !isSendingRating && sentRating != savedRating.rating
    }

    var hasChanges: Bool {
        return draftRating != (savedRating?.rating ?? 0)
            || comment != (savedRating?.comment ?? "")
    }

    var canSave: Bool {
        return canRate && (1...10).contains(draftRating) && hasChanges
    }

    var metadata: String {
        let year = movie.year.map(String.init) ?? "Год не указан"
        if let runtime = movie.runtime {
            return "\(year) · \(runtime / 60) ч \(runtime % 60) мин"
        }
        return year
    }

    func loadDetails() async {
        guard !didLoadDetails else { return }
        isLoadingDetails = true
        detailsError = nil
        do {
            let loaded = try await client.movie(id: movie.id)
            try Task.checkCancellation()
            movie = loaded
            didLoadDetails = true
            isLoadingDetails = false
        } catch {
            guard !Task.isCancelled else { return }
            isLoadingDetails = false
            detailsError = (error as? TMDBError)?.errorDescription
                ?? "Не удалось обновить сведения о фильме."
        }
    }

    func retryDetails() {
        detailsRequestID += 1
    }

    func sendSavedRating() {
        guard canSendRating, let savedRating else { return }
        let rating = savedRating.rating
        isSendingRating = true
        ratingSendError = nil
        ratingSendMessage = nil
        ratingSendTask = Task {
            do {
                let result = try await client.sendRating(movieID: movie.id, rating: rating)
                try Task.checkCancellation()
                sentRating = rating
                ratingSendMessage = result.message(rating: rating)
                isSendingRating = false
                ratingSendTask = nil
            } catch {
                guard !Task.isCancelled else { return }
                isSendingRating = false
                ratingSendTask = nil
                ratingSendError = (error as? TMDBError)?.errorDescription
                    ?? "Не удалось отправить оценку в TMDB. Повторите отправку."
            }
        }
    }

    func cancelSendingRating() {
        ratingSendTask?.cancel()
        ratingSendTask = nil
        isSendingRating = false
    }

    func loadRating() {
        // повторное обновление не должно стирать ещё не сохранённый комментарий
        if didLoadRating && hasChanges { return }
        do {
            let previousRating = savedRating?.rating
            savedRating = try ratings.rating(for: movie.id)
            if previousRating != savedRating?.rating {
                ratingSendError = nil
                ratingSendMessage = nil
            }
            // Если сеть недоступна, сохранённый снимок заменит краткий результат поиска.
            if !movie.hasDetails, let savedRating {
                movie = savedRating.movie
            }
            draftRating = savedRating?.rating ?? 0
            comment = savedRating?.comment ?? ""
            didLoadRating = true
            storageError = nil
        } catch {
            storageError = "Не удалось прочитать вашу оценку."
        }
    }

    func loadWatchlist() {
        do {
            let savedMovie = try watchlist.movie(for: movie.id)
            isWatchlisted = savedMovie != nil
            if !movie.hasDetails, let savedMovie {
                movie = savedMovie
            }
        } catch {
            storageError = "Не удалось прочитать список желаемого."
        }
    }

    func toggleWatchlist() {
        guard canToggleWatchlist else { return }
        do {
            if isWatchlisted {
                try watchlist.remove(movieID: movie.id)
            } else {
                try watchlist.add(movie)
            }
            isWatchlisted.toggle()
            storageError = nil
        } catch {
            storageError = "Не удалось изменить список желаемого."
        }
    }

    func save() -> Bool {
        guard canSave else { return false }
        do {
            savedRating = try ratings.save(movie: movie, rating: draftRating, comment: comment)
            ratingSendError = nil
            if sentRating != savedRating?.rating { ratingSendMessage = nil }
            saveMessage = "Оценка и комментарий сохранены"
            storageError = nil
            return true
        } catch {
            storageError = "Не удалось сохранить оценку. Изменения остались в форме."
            return false
        }
    }

    func discardRatingChanges() {
        draftRating = savedRating?.rating ?? 0
        comment = savedRating?.comment ?? ""
    }

    func removeRating() {
        do {
            try ratings.remove(movieID: movie.id)
            cancelSendingRating()
            sentRating = nil
            ratingSendError = nil
            ratingSendMessage = nil
            savedRating = nil
            draftRating = 0
            comment = ""
            saveMessage = nil
            storageError = nil
        } catch {
            storageError = "Не удалось удалить оценку."
        }
    }
}
