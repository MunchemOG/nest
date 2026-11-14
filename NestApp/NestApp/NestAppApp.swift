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
    @State private var auto: AutoPresence?

    init() {
        let home = HomeModel()
        home.pings = CriticalPings(send: SystemNotifications.post)
        _home = State(initialValue: home)
        let presence = PresenceSwitch(model: home)
        _presence = State(initialValue: presence)
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            let swift = SwiftOnThisMac()
            presence.tellSwift = swift.hear
            swift.start { event in await home.receive(event) }
            let auto = AutoPresence(presence: presence, log: SwiftOnThisMac.activity, messages: { ClaudeHistory().yourMessages() })
            auto.start()
            _auto = State(initialValue: auto)
        }
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
            PresenceMenu(presence: presence, auto: auto)
        }

        Window("Swift", id: SwiftMiniWindow.id) {
            SwiftMiniWindow(home: home)
        }
        .windowStyle(.hiddenTitleBar)
        .windowLevel(.floating)
        .defaultSize(width: NestSpace.s10 * 3 + NestSpace.s8, height: NestSpace.s10 * 4)
        .defaultPosition(.topTrailing)

        #if DEBUG
        Window("Component Gallery", id: ComponentGallery.windowID) {
            ComponentGallery()
        }
        #endif
    }
}
