//
//  SkyJumpApp.swift
//  SkyJump
//
//  Created by Єгор Єсипович on 29.09.2026.
//

import SwiftUI

@main
struct SkyJumpApp: App {
    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            DemoView(viewModel: dependencies.makeDemoViewModel())
        }
    }
}
