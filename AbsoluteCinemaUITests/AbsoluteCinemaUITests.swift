import XCTest

final class AbsoluteCinemaUITests: XCTestCase {
    @MainActor
    func testSearchAndSaveRatingWithComment() {
        let app = launchApp()

        let query = app.textFields["search.query"]
        XCTAssertTrue(query.waitForExistence(timeout: 10))
        query.tap()
        query.typeText("Odyssey")
        tap(app.buttons["search.submit"], in: app)

        tap(app.buttons["search.result.62"], in: app)
        tap(app.buttons["details.editRating"], in: app)
        chooseRating(8, in: app)
        let comment = app.textViews["rating.comment"]
        XCTAssertTrue(comment.waitForExistence(timeout: 5))
        comment.tap()
        comment.typeText("Great movie")
        tap(app.buttons["rating.save"], in: app)

        assertSavedRating(8, comment: "Great movie", in: app)
        app.tabBars.buttons["Мои оценки"].tap()
        tap(app.buttons["ratings.movie.62"], in: app)
        assertSavedRating(8, comment: "Great movie", in: app)
    }

    @MainActor
    func testCancelEditingKeepsSavedRatingAndComment() {
        let app = launchApp()
        tap(app.tabBars.buttons["Мои оценки"], in: app)
        tap(app.buttons["ratings.movie.603"], in: app)
        assertSavedRating(8, comment: "Matrix baseline", in: app)
        tap(app.buttons["details.editRating"], in: app)

        chooseRating(5, in: app)
        let comment = app.textViews["rating.comment"]
        XCTAssertTrue(comment.waitForExistence(timeout: 5))
        comment.tap()
        let oldText = comment.value as? String ?? ""
        // Дописываем текст без очистки поля, чтобы тест не зависел от положения курсора
        comment.typeText("Unsaved changes")
        XCTAssertNotEqual(comment.value as? String, oldText)
        XCTAssertTrue((comment.value as? String ?? "").contains("Unsaved changes"))
        tap(app.buttons["rating.cancel"], in: app)

        assertSavedRating(8, comment: "Matrix baseline", in: app)
        tap(app.buttons["details.editRating"], in: app)
        let savedRating = app.buttons["rating.value.8"]
        XCTAssertTrue(savedRating.waitForExistence(timeout: 5))
        XCTAssertTrue(savedRating.isSelected)
        XCTAssertFalse(app.buttons["rating.value.5"].isSelected)
        XCTAssertEqual(app.textViews["rating.comment"].value as? String, "Matrix baseline")
        XCTAssertFalse(app.buttons["rating.save"].isEnabled)
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        return app
    }

    @MainActor
    private func chooseRating(_ rating: Int, in app: XCUIApplication) {
        let button = app.buttons["rating.value.\(rating)"]
        tap(button, in: app)
        XCTAssertTrue(button.isSelected)
    }

    @MainActor
    private func assertSavedRating(_ rating: Int, comment: String, in app: XCUIApplication) {
        let value = app.staticTexts["details.savedRating"]
        XCTAssertTrue(value.waitForExistence(timeout: 5))
        XCTAssertEqual(value.label, "Моя оценка: \(rating) из 10")
        XCTAssertFalse(app.staticTexts["details.savedComment"].exists)
        tap(app.buttons["details.editRating"], in: app)
        let editor = app.textViews["rating.comment"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertEqual(editor.value as? String, comment)
        tap(app.buttons["rating.cancel"], in: app)
    }

    @MainActor
    private func tap(_ element: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Не найден элемент: \(element)")
        // Прокручиваем форму, если кнопку закрывает клавиатура или она за краем экрана
        for _ in 0..<5 {
            if element.isHittable { break }
            let form = app.collectionViews.firstMatch
            if form.exists && form.isHittable {
                form.swipeUp()
            } else {
                app.swipeUp()
            }
        }
        XCTAssertTrue(element.isEnabled && element.isHittable,
                      "Элемент должен быть доступен для нажатия: \(element)")
        element.tap()
    }
}
