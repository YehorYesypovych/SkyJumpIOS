import SwiftUI

/// Модальний редактор рівня. Кнопки «Скасувати» і «Зберегти» — у тулбарі,
/// тому клавіатура ніколи не закриває завершення введення.
struct LevelEditorView: View {
    @State private var viewModel: LevelEditorViewModel
    @FocusState private var isNameFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(viewModel: LevelEditorViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Назва рівня", text: $viewModel.draft.name)
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit { isNameFocused = false }
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Text("Назва")
                } footer: {
                    if let message = viewModel.validationMessage {
                        Label(message, systemImage: "exclamationmark.circle")
                            .foregroundStyle(.orange)
                            .transition(messageTransition)
                            .id(message)
                    }
                }

                Section("Параметри") {
                    Stepper(value: $viewModel.draft.platformCount,
                            in: LevelPreset.platformCountRange) {
                        LabeledContent("Платформ", value: "\(viewModel.draft.platformCount)")
                    }

                    Picker("Складність", selection: $viewModel.draft.difficulty) {
                        ForEach(LevelDifficulty.allCases) { difficulty in
                            Text(difficulty.title).tag(difficulty)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    LabeledContent("Seed", value: "\(viewModel.draft.seed)")
                    Button("Новий seed", systemImage: "dice") {
                        viewModel.regenerateSeed()
                    }
                } header: {
                    Text("Генерація")
                } footer: {
                    Text("Однаковий seed дає однакове розташування платформ.")
                }
            }
            .appBackground()
            .animation(reduceMotion ? nil : .snappy, value: viewModel.validationMessage)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(viewModel.title)
            // великий заголовок під тулбаром: на вузьких екранах (iPhone 17e) inline-заголовок
            // між «Скасувати» і «Зберегти» обрізався
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { viewModel.cancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Зберегти") { viewModel.save() }
                        .disabled(!viewModel.canSave)
                }
            }
            .onAppear {
                if viewModel.mode == .create {
                    isNameFocused = true
                }
            }
        }
        .interactiveDismissDisabled(viewModel.hasChanges)
    }

    private var messageTransition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity)
    }
}

#Preview("Створення") {
    @Previewable @State var router = AppRouter()
    LevelEditorView(viewModel: LevelEditorViewModel(mode: .create,
                                                    library: LevelLibrary(),
                                                    navigator: router))
}

#Preview("Редагування") {
    @Previewable @State var router = AppRouter()
    let library = LevelLibrary()
    LevelEditorView(viewModel: LevelEditorViewModel(mode: .edit(library.levels[0].id),
                                                    library: library,
                                                    navigator: router))
}
