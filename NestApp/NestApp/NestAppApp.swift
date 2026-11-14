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
    @State private var home: HomeModel
    @State private var presence: PresenceSwitch

    init() {
        let home = HomeModel()
        _home = State(initialValue: home)
        _presence = State(initialValue: PresenceSwitch(model: home))
        do {
            try NestFont.registerBundledFonts()
        } catch {
            Logger(subsystem: "Nest", category: "fonts").error("Bundled fonts did not register: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(home: home)
        }
        .defaultSize(width: NestSpace.s10 * 12, height: NestSpace.s10 * 7)
        .commands {
            CommandMenu("Go") { GoMenuItems() }
        }
        #if DEBUG
        .commands {
            CommandMenu("Debug") { GalleryMenuItem() }
        }
        #endif

        MenuBarExtra("Nest", image: "mark-menubar") {
            PresenceMenu(presence: presence)
        }

        #if DEBUG
        Window("Component Gallery", id: ComponentGallery.windowID) {
            ComponentGallery()
        }
        #endif
    }
}
