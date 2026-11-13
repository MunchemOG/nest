//
//  NestAppApp.swift
//  NestApp
//
//  Created by Mithun Dhanes on 11/10/26.
//

import NestKit
import OSLog
import SwiftUI

@main
struct NestAppApp: App {
    init() {
        do {
            try NestFont.registerBundledFonts()
        } catch {
            Logger(subsystem: "Nest", category: "fonts").error("Bundled fonts did not register: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
