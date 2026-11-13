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
        .defaultSize(width: NestSpace.s10 * 10, height: NestSpace.s10 * 7)
        .commands {
            CommandMenu("Go") { GoMenuItems() }
        }
        #if DEBUG
        .commands {
            CommandMenu("Debug") { GalleryMenuItem() }
        }
        #endif

        #if DEBUG
        Window("Component Gallery", id: ComponentGallery.windowID) {
            ComponentGallery()
        }
        #endif
    }
}
