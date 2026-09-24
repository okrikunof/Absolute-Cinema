import Foundation
import Testing
@testable import AbsoluteCinema

@MainActor
struct AbsoluteCinemaTests {
    @Test func ratingMarksMovieAsWatched() {
        let model = MovieDetailsViewModel(movie: MovieMock.spaceOdyssey)
        model.rate(9)
        #expect(model.userRating == 9)
        #expect(model.collectionStatus == .watched)
    }

    @Test func returningToWatchlistClearsRating() {
        let model = MovieDetailsViewModel(movie: MovieMock.spaceOdyssey)
        model.rate(8)
        model.setStatus(.watchlist)
        #expect(model.userRating == nil)
        #expect(model.collectionStatus == .watchlist)
    }

    @Test(arguments: [0, 11, -1]) func invalidRatingDoesNotChangeState(value: Int) {
        let model = MovieDetailsViewModel(movie: MovieMock.spaceOdyssey)
        model.rate(7)
        model.rate(value)
        #expect(model.userRating == 7)
        #expect(model.collectionStatus == .watched)
    }

    @Test func repeatedAddPreservesWatchedStatusAndRating() {
        let model = MovieDetailsViewModel(movie: MovieMock.spaceOdyssey)
        model.addToWatchlist()
        #expect(model.collectionStatus == .watchlist)
        model.rate(10)
        model.addToWatchlist()
        #expect(model.collectionStatus == .watched)
        #expect(model.userRating == 10)
    }

    @Test func removalClearsPersonalState() {
        let model = MovieDetailsViewModel(movie: MovieMock.spaceOdyssey)
        model.rate(6)
        model.removeFromCollection()
        #expect(model.collectionStatus == nil)
        #expect(model.userRating == nil)
    }

    @Test func clearingRatingKeepsWatchedStatus() {
        let model = MovieDetailsViewModel(movie: MovieMock.spaceOdyssey)
        model.rate(6)
        model.clearRating()
        #expect(model.collectionStatus == .watched)
        #expect(model.userRating == nil)
    }

    @Test func mockMatchesSavedAPIResponse() throws {
        let bundle = Bundle(for: BundleMarker.self)
        let url = try #require(bundle.url(forResource: "space-odyssey", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let movie = MovieMock.spaceOdyssey
        #expect(movie.id == json["id"] as? Int)
        #expect(movie.title == json["title"] as? String)
        #expect(movie.originalTitle == json["original_title"] as? String)
        #expect(movie.overview == json["overview"] as? String)
        #expect(movie.runtime == json["runtime"] as? Int)
        #expect(movie.rating == json["vote_average"] as? Double)
        #expect(movie.voteCount == json["vote_count"] as? Int)
    }
}
