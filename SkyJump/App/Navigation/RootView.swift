import SwiftUI

/// Корінь інтерфейсу: стек екранів і модальне вікно прив'язані до стану роутера.
struct RootView: View {
    @Bindable var router: AppRouter
    let factory: ScreenFactory

    var body: some View {
        NavigationStack(path: $router.path) {
            factory.makeLevelList()
                .navigationDestination(for: Route.self) { route in
                    factory.makeView(for: route)
                }
        }
        .sheet(item: $router.sheet) { sheet in
            factory.makeView(for: sheet)
                .tint(Theme.accent)
        }
        .tint(Theme.accent)
    }
}
