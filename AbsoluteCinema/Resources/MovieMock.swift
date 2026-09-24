import Foundation

enum MovieMock {
    /// Снимок GET /3/movie/62?language=ru-RU от 24.09.2026.
    /// Исходный ответ: space-odyssey.json. Сетевых вызовов нет.
    static let spaceOdyssey = Movie(
        id: 62,
        title: "2001 год: Космическая одиссея",
        originalTitle: "2001: A Space Odyssey",
        year: 1968,
        runtime: 149,
        overview: "Экипаж космического корабля «Дискавери» — капитаны Дэйв Боумэн, Фрэнк Пул и их бортовой компьютер HAL 9000 — должны исследовать район галактики и понять, почему инопланетяне следят за Землей. На этом пути их ждет множество неожиданных открытий.",
        genres: ["фантастика", "детектив", "приключения"],
        rating: 8.044,
        voteCount: 12960,
        posterAssetName: "SpaceOdyssey"
    )
}
