import XCTest

final class AbsoluteCinemaUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSearchAndSaveRatingWithComment() {
        let app = launchApp()

        // Arrange: поиск использует заданный ответ, база заново создаётся в памяти.
        let query = app.textFields["search.query"]
        XCTAssertTrue(query.waitForExistence(timeout: 10))
        query.tap()
        query.typeText("Odyssey")
        tap(app.buttons["search.submit"], in: app)

        // Act: открываем найденный фильм и сохраняем личные данные через форму.
        tap(app.buttons["search.result.62"], in: app)
        tap(app.buttons["details.editRating"], in: app)
        chooseRating(8, in: app)
        let comment = app.textViews["rating.comment"]
        XCTAssertTrue(comment.waitForExistence(timeout: 5))
        comment.tap()
        comment.typeText("Great movie")
        tap(app.buttons["rating.save"], in: app)

        // Assert: проверяем результат в карточке и повторное чтение через список.
        assertSavedRating(8, comment: "Great movie", in: app)
        app.tabBars.buttons["Мои оценки"].tap()
        tap(app.buttons["ratings.movie.62"], in: app)
        assertSavedRating(8, comment: "Great movie", in: app)
    }

    @MainActor
    func testCancelEditingKeepsSavedRatingAndComment() {
        let app = launchApp()
        app.tabBars.buttons["Мои оценки"].tap()
        tap(app.buttons["ratings.movie.603"], in: app)
        assertSavedRating(8, comment: "Matrix baseline", in: app)
        tap(app.buttons["details.editRating"], in: app)

        // Меняем оба поля черновика, но не нажимаем сохранение.
        chooseRating(5, in: app)
        let comment = app.textViews["rating.comment"]
        XCTAssertTrue(comment.waitForExistence(timeout: 5))
        comment.tap()
        let oldText = comment.value as? String ?? ""
        comment.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: oldText.count))
        comment.typeText("Unsaved changes")
        XCTAssertEqual(comment.value as? String, "Unsaved changes")
        tap(app.buttons["rating.cancel"], in: app)

        // После отмены сохранённые значения должны остаться прежними.
        assertSavedRating(8, comment: "Matrix baseline", in: app)
        tap(app.buttons["details.editRating"], in: app)
        let picker = app.buttons["rating.value"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        XCTAssertEqual(picker.value as? String, "8 из 10")
        XCTAssertEqual(app.textViews["rating.comment"].value as? String, "Matrix baseline")
        XCTAssertFalse(app.buttons["rating.save"].isEnabled)
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Мои оценки"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor
    private func chooseRating(_ rating: Int, in app: XCUIApplication) {
        tap(app.buttons["rating.value"], in: app)
        tap(app.buttons["\(rating) из 10"], in: app)
        XCTAssertEqual(app.buttons["rating.value"].value as? String, "\(rating) из 10")
    }

    @MainActor
    private func assertSavedRating(_ rating: Int, comment: String, in app: XCUIApplication) {
        let value = app.staticTexts["details.savedRating"]
        XCTAssertTrue(value.waitForExistence(timeout: 5))
        XCTAssertEqual(value.label, "Моя оценка: \(rating) из 10")
        XCTAssertEqual(app.staticTexts["details.savedComment"].label, comment)
    }

    @MainActor
    private func tap(_ element: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Не найден элемент: \(element)")
        // Кнопки формы могут находиться ниже клавиатуры или края экрана.
        for _ in 0..<5 {
            if element.isHittable { break }
            let form = app.collectionViews.firstMatch
            if form.exists && form.isHittable {
                form.swipeUp()
            } else {
                app.swipeUp()
            }
        }
        let ready = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true AND hittable == true"),
            object: element
        )
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed,
                       "Элемент должен стать доступным для нажатия: \(element)")
        element.tap()
    }
}
