import AppKit
import NestKit
import SwiftUI
import Testing
@testable import NestApp

@MainActor
struct NestPanelTests {
    @Test func solidPanelsAreSmokedGlass() {
        #expect(NestPanelKind.solid.fill == .glass)
        #expect(NestPanelKind.solid.shadow == .panel)
        #expect(NestPanelKind.solid.usesBackdropBlur)
    }

    @Test func floatingPanelsAreTheHighestLayer() {
        #expect(NestPanelKind.floating.fill == .surface3)
        #expect(NestPanelKind.floating.shadow == .popover)
        #expect(!NestPanelKind.floating.usesBackdropBlur)
    }

    @Test func escapeAndOutsideClicksClose() {
        #expect(FloatingPanelDismissal.closes(on: .escape))
        #expect(FloatingPanelDismissal.closes(on: .clickOutside))
        #expect(!FloatingPanelDismissal.closes(on: .clickInside))
        #expect(!FloatingPanelDismissal.closes(on: .otherKey))
    }

    @Test func onlyTheEscapeKeyCodeCountsAsEscape() throws {
        let escape = try #require(Self.key(53))
        let space = try #require(Self.key(49))
        #expect(FloatingPanelDismissal.Event(escape) == .escape)
        #expect(FloatingPanelDismissal.Event(space) == .otherKey)
    }

    @Test func aClickIsInsideOnlyWithinThePanelsFrame() {
        let frame = CGRect(x: 100, y: 100, width: 200, height: 100)
        #expect(FloatingPanelDismissal.Event(click: CGPoint(x: 150, y: 150), panel: frame) == .clickInside)
        #expect(FloatingPanelDismissal.Event(click: CGPoint(x: 50, y: 150), panel: frame) == .clickOutside)
        #expect(FloatingPanelDismissal.Event(click: CGPoint(x: 150, y: 250), panel: frame) == .clickOutside)
    }

    static func key(_ code: UInt16) -> NSEvent? {
        NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0,
            context: nil, characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: code
        )
    }

    final class Box {
        var isPresented = true
    }

    /// Hosts a floating panel in a real window and returns the window and a reading of `isPresented`.
    static func host(_ box: Box) -> NSWindow {
        let binding = Binding(get: { box.isPresented }, set: { box.isPresented = $0 })
        let view = Color(NestColor.surface0)
            .frame(width: NestSpace.s10 * 4, height: NestSpace.s10 * 3)
            .nestFloatingPanel(isPresented: binding) {
                Text("Two need you").nestFont(.body).frame(width: NestSpace.s10, height: NestSpace.s10)
            }
        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.makeKeyAndOrderFront(nil)
        return window
    }

    static func settle() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
    }

    @Test func escapeClosesAFloatingPanelInAWindow() throws {
        let box = Box()
        let window = Self.host(box)
        defer { window.close() }
        Self.settle()
        let escape = try #require(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber,
            context: nil, characters: "\u{1b}", charactersIgnoringModifiers: "\u{1b}", isARepeat: false, keyCode: 53
        ))
        NSApp.sendEvent(escape)
        Self.settle()
        #expect(box.isPresented == false)
    }

    @Test func aClickOutsideClosesAFloatingPanelInAWindow() throws {
        let box = Box()
        let window = Self.host(box)
        defer { window.close() }
        Self.settle()
        let corner = NSPoint(x: NestSpace.s4, y: NestSpace.s4)
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            let click = try #require(NSEvent.mouseEvent(
                with: type, location: corner, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1
            ))
            NSApp.sendEvent(click)
        }
        Self.settle()
        #expect(box.isPresented == false)
    }

    @Test func aClickInsideKeepsAFloatingPanelOpen() throws {
        let box = Box()
        let window = Self.host(box)
        defer { window.close() }
        Self.settle()
        let centre = NSPoint(x: NestSpace.s10 * 2, y: NestSpace.s10 * 1.5)
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            let click = try #require(NSEvent.mouseEvent(
                with: type, location: centre, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1
            ))
            NSApp.sendEvent(click)
        }
        Self.settle()
        #expect(box.isPresented == true)
    }

    static func rows() -> some View {
        VStack(alignment: .leading, spacing: NestSpace.s3) {
            Text("Activity").nestFont(.title).foregroundStyle(Color(NestColor.textPrimary))
            Text("Wren moved swerve-pod-v4.step to Robotics / CAD").nestFont(.bodyS).foregroundStyle(Color(NestColor.textSecondary))
        }
        .frame(width: NestSpace.s10 * 2, alignment: .leading)
    }

    @Test func everyKindMatchesItsSnapshot() throws {
        try Snapshot.expect(NestPanel(.solid) { Self.rows() }, named: "panel-solid")
        try Snapshot.expect(NestPanel(.floating) { Self.rows() }, named: "panel-floating")
    }
}
