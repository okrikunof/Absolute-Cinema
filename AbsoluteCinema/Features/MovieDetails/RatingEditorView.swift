import SwiftUI

struct RatingEditorView: View {
    @Bindable var viewModel: MovieDetailsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Моя оценка") {
                    Picker("Оценка", selection: $viewModel.draftRating) {
                        Text("Не выбрана").tag(0)
                        ForEach(1...10, id: \.self) { rating in
                            Text("\(rating) из 10").tag(rating)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("rating.value")
                    .accessibilityValue(viewModel.draftRating == 0
                                        ? "Не выбрана" : "\(viewModel.draftRating) из 10")
                }
                Section("Комментарий (необязательно)") {
                    TextEditor(text: $viewModel.comment)
                        .frame(minHeight: 100)
                        .accessibilityLabel("Мой комментарий о фильме")
                        .accessibilityIdentifier("rating.comment")
                }
                if let message = viewModel.storageError {
                    Section {
                        Text(message).foregroundStyle(.red)
                    }
                }
                Section {
                    Button("Сохранить оценку") {
                        if viewModel.save() { dismiss() }
                    }
                    .disabled(!viewModel.canSave)
                    .accessibilityIdentifier("rating.save")
                    Button("Отмена", role: .cancel) { dismiss() }
                        .accessibilityIdentifier("rating.cancel")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Оценить фильм")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
