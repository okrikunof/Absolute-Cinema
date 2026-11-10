import XCTest
@testable import AbsoluteCinema

final class SearchViewModelTests: XCTestCase {
    @MainActor
    func testBlankQueryDoesNotStartSearch() {
        let viewModel = SearchViewModel(client: TMDBClient(), history: RecentMoviesStore())
        for query in ["", "   ", "\n\t"] {
            viewModel.query = query
            XCTAssertFalse(viewModel.canSearch)
            viewModel.search()
            XCTAssertFalse(viewModel.isLoading)
            XCTAssertFalse(viewModel.hasSearched)
            XCTAssertTrue(viewModel.movies.isEmpty)
            XCTAssertNil(viewModel.errorMessage)
        }
    }

    @MainActor
    func testSearchAvailabilityFollowsQueryChanges() {
        let viewModel = SearchViewModel(client: TMDBClient(), history: RecentMoviesStore())
        XCTAssertFalse(viewModel.canSearch)

        viewModel.query = "  Интерстеллар  "
        XCTAssertTrue(viewModel.canSearch)
        XCTAssertEqual(viewModel.query, "  Интерстеллар  ")

        viewModel.query = "   "
        XCTAssertFalse(viewModel.canSearch)
    }
}
