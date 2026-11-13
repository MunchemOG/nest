import NestKit
import SwiftUI
import Testing
@testable import NestApp

@MainActor
struct ChatTests {
    @Test(arguments: Bird.allCases)
    func aBirdSpeaksInItsOwnTint(_ bird: Bird) {
        let sender = ChatSender.bird(bird)
        #expect(sender.fill == bird.tint)
        #expect(sender.alignment == .leading)
        #expect(sender.bird == bird)
    }

    @Test func youSpeakOnTheRight() {
        #expect(ChatSender.you.fill == .surface2)
        #expect(ChatSender.you.alignment == .trailing)
        #expect(ChatSender.you.bird == nil)
    }

    @Test func typingDotsStepInTurn() {
        #expect(TypingDots.brightDot(phase: 0) == 0)
        #expect(TypingDots.brightDot(phase: 1) == 1)
        #expect(TypingDots.brightDot(phase: 2) == 2)
        #expect(TypingDots.phases.count == 3)
    }

    @Test func typingDotsHoldStillUnderReducedMotion() {
        #expect(TypingDots.steps(reduceMotion: false))
        #expect(!TypingDots.steps(reduceMotion: true))
    }

    @Test func anEmptyDraftCannotBeSent() {
        #expect(!ChatDraft(text: "").canSend)
        #expect(!ChatDraft(text: "  \n ").canSend)
        #expect(ChatDraft(text: "Swift, build N1-15").canSend)
    }

    @Test func sendingHandsOverTrimmedTextAndClears() {
        var draft = ChatDraft(text: "  Swift, build N1-15 \n")
        #expect(draft.send() == "Swift, build N1-15")
        #expect(draft.text.isEmpty)
        #expect(draft.send() == nil)
    }

    @Test(arguments: Bird.allCases)
    func everyBirdBubbleMatchesItsSnapshot(_ bird: Bird) throws {
        let message = ChatMessage(id: "1", sender: .bird(bird), text: "Moved swerve-pod-v4.step to Robotics / CAD.")
        try Snapshot.expect(ChatBubble(message).frame(width: NestSpace.s10 * 3), named: "chat-\(bird)")
    }

    @Test func yourBubbleMatchesItsSnapshot() throws {
        let message = ChatMessage(id: "2", sender: .you, text: "Focus mode for two hours, please.")
        try Snapshot.expect(ChatBubble(message).frame(width: NestSpace.s10 * 3), named: "chat-you")
    }

    @Test func typingMatchesItsSnapshot() throws {
        try Snapshot.expect(TypingBubble(.swift).frame(width: NestSpace.s10 * 3), named: "chat-typing")
    }

    @Test func theComposerMatchesItsSnapshot() throws {
        let empty = ChatComposer(draft: .constant(ChatDraft()), placeholder: "Ask the flock") { _ in }
        try Snapshot.expect(empty.frame(width: NestSpace.s10 * 3), named: "chat-composer-empty", rendering: .window)
        let filled = ChatComposer(draft: .constant(ChatDraft(text: "Swift, build N1-15")), placeholder: "Ask the flock") { _ in }
        try Snapshot.expect(filled.frame(width: NestSpace.s10 * 3), named: "chat-composer-filled", rendering: .window)
    }
}
