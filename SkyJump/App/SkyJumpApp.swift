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

    var body: some Scene {
        WindowGroup {
            RootView(router: router,
                     factory: ScreenFactory(dependencies: dependencies, navigator: router))
        }
    }
}
