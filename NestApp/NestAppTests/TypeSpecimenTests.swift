import NestKit
import SwiftUI
import Testing
@testable import NestApp

@MainActor
struct TypeSpecimenTests {
    @Test func theSpecimenShowsEveryStyleInOrder() {
        #expect(TypeSpecimen().styles == NestFont.styles)
    }

    @Test func theSpecimenRenders() throws {
        let renderer = ImageRenderer(content: TypeSpecimen())
        let image = try #require(renderer.nsImage)
        #expect(image.size.width > 0)
        #expect(image.size.height > 0)
    }
}
