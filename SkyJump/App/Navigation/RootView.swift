import SwiftUI

/// Корінь інтерфейсу: стек екранів і модальне вікно прив'язані до стану роутера.
struct RootView: View {
    @Bindable var router: AppRouter
    let factory: ScreenFactory
    /// Обрана тема, скін і слід — тема застосовується до всіх екранів.
    let cosmetics: CosmeticsSettings

    var body: some View {
        NavigationStack(path: $router.path) {
            factory.makeLevelList()
                .navigationDestination(for: Route.self) { route in
                    factory.makeView(for: route)
                }
        }
        .sheet(item: $router.sheet) { sheet in
            factory.makeView(for: sheet)
                .worldTheme(cosmetics.theme)
        }
        // меню, гра й системні елементи підлаштовуються під обрану тему
        .worldTheme(cosmetics.theme)
    }
}
