//
//  SkyJumpApp.swift
//  SkyJump
//
//  Created by Єгор Єсипович on 29.09.2026.
//

import SwiftUI

@main
struct SkyJumpApp: App {
    @State private var router = AppRouter()
    private let dependencies = AppDependencies.live()

    init() {
        // більший кеш для мережі: логотипи радіостанцій не завантажуються щоразу заново
        URLCache.shared = URLCache(memoryCapacity: 20 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024)
    }

    var body: some Scene {
        WindowGroup {
            RootView(router: router,
                     factory: ScreenFactory(dependencies: dependencies, navigator: router))
        }
    }
}
