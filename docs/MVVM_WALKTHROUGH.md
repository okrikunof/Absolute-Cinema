# Как сохранение оценки связано с MVVM

Разбор текущего сетевого MVP на 22 октября 2026 года. Путь локального сохранения сохранился после подключения TMDB.

## От карточки до базы

1. [Кнопка «Оценить»](../AbsoluteCinema/Features/MovieDetails/MovieDetailsView.swift) открывает форму RatingEditorView.
   Пользователь выбирает число в [RatingEditorView.swift](../AbsoluteCinema/Features/MovieDetails/RatingEditorView.swift).
   Привязка `$viewModel.draftRating` записывает выбор в свойство ViewModel. В этот момент база не меняется.
2. Аналогично [TextEditor](../AbsoluteCinema/Features/MovieDetails/RatingEditorView.swift) меняет `viewModel.comment`.
3. [Кнопка сохранения](../AbsoluteCinema/Features/MovieDetails/RatingEditorView.swift) вызывает `viewModel.save()`.
   View знает, какое действие произошло, и передаёт его ViewModel.
4. [MovieDetailsViewModel.save()](../AbsoluteCinema/Features/MovieDetails/MovieDetailsViewModel.swift) проверяет `canSave` и вызывает репозиторий.
   После успеха он обновляет сохранённую оценку и возвращает true: форма закрывается. После ошибки форма остаётся открытой с сообщением.
5. [RatingRepository.save()](../AbsoluteCinema/Data/Repositories/RatingRepository.swift) находит запись по ID, меняет её или создаёт новую.
   Вызов `context.save()` записывает изменения через SwiftData. При ошибке `rollback()` откатывает несохранённые изменения контекста.
6. Репозиторий возвращает обычную структуру SavedRating. ViewModel сохраняет её в `savedRating`, и SwiftUI обновляет зависимые элементы карточки.

Получается один путь: действие пользователя → View → ViewModel → RatingRepository → SwiftData.
Результат проходит обратно через состояние ViewModel к View.

## Что означают незнакомые конструкции

| Конструкция в проекте | Роль в этом сценарии |
| --- | --- |
| `@Observable` у ViewModel | Позволяет SwiftUI отслеживать изменения свойств, которые читает интерфейс |
| `@State private var viewModel` в карточке | Карточка владеет своим экземпляром ViewModel; ViewModel вкладок принадлежат ContentView |
| `@Bindable var viewModel` в форме | Форма использует существующую ViewModel карточки и получает привязки к её свойствам |
| `$viewModel.comment` | Связывает текстовое поле со свойством ViewModel для чтения и изменения |
| `private(set)` | Другой объект может прочитать свойство, но меняет его только сам владелец |
| `throws`, `try`, `do/catch` | Метод может завершиться ошибкой; вызывающий код обрабатывает этот случай |
| `@Model` у RatedMovie | Делает класс сохраняемой моделью SwiftData |
| `@Attribute(.unique)` у movieID | Задаёт уникальность ID в хранилище |
| `@MainActor` | Ограничивает работу с объектом главным actor, связанным с главным потоком приложения |

## Два состояния оценки

`draftRating` и `comment` — то, что пользователь сейчас редактирует.
`savedRating` — последняя прочитанная или успешно сохранённая запись.
Их сравнение в [hasChanges](../AbsoluteCinema/Features/MovieDetails/MovieDetailsViewModel.swift) позволяет включить сохранение только при изменениях.
Разделение также сохраняет ввод пользователя, если запись в базу завершилась ошибкой.

`RatedMovie` представляет запись базы, `Movie` — сведения о фильме, `SavedRating` — результат чтения оценки вместе со сведениями о фильме.
[snapshot](../AbsoluteCinema/Data/Persistence/RatedMovie.swift) переводит сохраняемый объект в обычную структуру для экрана.

## Кто создаёт объекты и обновляет список

[AbsoluteCinemaApp.swift](../AbsoluteCinema/AbsoluteCinemaApp.swift) создаёт ModelContainer и общие RatingRepository и WatchlistRepository.
ContentView передаёт репозитории ViewModel карточки и списков, поэтому они обращаются к одному хранилищу.

При появлении карточки [onAppear](../AbsoluteCinema/Features/MovieDetails/MovieDetailsView.swift) вызывает `loadRating()` и `loadWatchlist()`.
После записи репозиторий увеличивает `revision`; [RatingsView](../AbsoluteCinema/Features/Ratings/RatingsView.swift) замечает изменение и вызывает `reload()`.
[RatingsViewModel.reload()](../AbsoluteCinema/Features/Ratings/RatingsViewModel.swift) перечитывает записи, и список отображает новое состояние.
`revision` — обычное число для уведомления об изменениях, введённое в этом проекте; это не специальный механизм SwiftData.

Для знакомства с кодом достаточно пройти этот сценарий в указанном порядке, начиная с уже знакомой кнопки во View.
TMDBClient уже загружает поиск и подробности. ViewModel карточки хранит загруженный Movie, а локальный путь сохранения остаётся прежним.

## Как работает «Хочу посмотреть»

Кнопка карточки вызывает `toggleWatchlist()` в той же ViewModel. Он обращается к WatchlistRepository, который сохраняет или удаляет WatchlistMovie.
У этой модели нет обязательной личной оценки. WatchlistViewModel читает фильмы для списка; его revision обновляется независимо от репозитория оценок.
Список передаёт сохранённый Movie в навигацию, поэтому карточка не зависит от наличия фильма в моковом массиве.

## Сеть и фоновое чтение

SearchView передаёт действие SearchViewModel.search(), который запускает Task и вызывает TMDBClient.searchMovies(). При открытии карточки .task вызывает loadDetails(). Новый фильм доступен для сохранения после полной загрузки; существующий локальный снимок позволяет работать при ошибке сети.

RatingsViewModel.reload() теперь вызывает ratingsInBackground(), а WatchlistViewModel — moviesInBackground(). Репозитории создают SavedMoviesReader в Task.detached; его отдельный ModelContext читает SwiftData и возвращает обычные Sendable-снимки. После проверки отмены ViewModel обновляет интерфейс на MainActor. Отмена не прерывает уже начатый detached-запрос, но препятствует применению его результата.

Кнопка sendSavedRating() отдельно отправляет сохранённое число в TMDB. Она не сохраняет комментарий на сервере и не заменяет локальный save().

Поведение отмены описано по коду. UI-тест 22 октября упал при подготовке текста до отмены; результаты проверки см. в CURRENT_AUDIT.md.
