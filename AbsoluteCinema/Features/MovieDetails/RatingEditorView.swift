import SwiftUI

struct RatingEditorView: View {
    @Bindable var viewModel: MovieDetailsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmsDeletion = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(viewModel.movie.title).font(.title2.bold())
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ваша оценка").font(.headline)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                            ForEach(1...10, id: \.self) { rating in
                                let isSelected = viewModel.draftRating == rating
                                let ratingColor = RatingColors.color(for: rating)
                                Button {
                                    viewModel.draftRating = rating
                                } label: {
                                    Text("\(rating)")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, minHeight: 48)
                                        .foregroundStyle(isSelected ? Color("Background") : Color("PrimaryText"))
                                        .background(
                                            isSelected ? ratingColor : Color("Surface"),
                                            in: RoundedRectangle(cornerRadius: 12)
                                        )
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(ratingColor, lineWidth: isSelected ? 2 : 0)
                                        }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(rating) из 10")
                                .accessibilityAddTraits(isSelected ? .isSelected : [])
                                .accessibilityIdentifier("rating.value.\(rating)")
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Комментарий").font(.headline)
                        Text("Что запомнилось? Необязательно.")
                            .font(.subheadline).foregroundStyle(Color("SecondaryText"))
                        TextEditor(text: $viewModel.comment)
                            .frame(minHeight: 130)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("Мой комментарий о фильме")
                            .accessibilityIdentifier("rating.comment")
                    }
                    if let message = viewModel.storageError {
                        Text(message).font(.subheadline).foregroundStyle(.red)
                    }
                    if viewModel.savedRating != nil {
                        Button("Удалить оценку и комментарий", role: .destructive) {
                            confirmsDeletion = true
                        }
                        .font(.subheadline)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("details.deleteRating")
                    }
                }
                .padding(20)
            }
            .background(Color("Background"))
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Оценить фильм")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                        .accessibilityIdentifier("rating.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        if viewModel.save() { dismiss() }
                    }
                    .disabled(!viewModel.canSave)
                    .accessibilityIdentifier("rating.save")
                }
            }
            .confirmationDialog("Удалить оценку и комментарий?", isPresented: $confirmsDeletion,
                                titleVisibility: .visible) {
                Button("Удалить", role: .destructive) {
                    viewModel.removeRating()
                    if viewModel.savedRating == nil { dismiss() }
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Фильм останется в списке «Хочу посмотреть», если вы его туда добавили.")
            }
        }
    }

}
