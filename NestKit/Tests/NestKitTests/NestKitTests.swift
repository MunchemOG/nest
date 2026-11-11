import Testing
@testable import NestKit

struct NestKitTests {
    @Test func packageIsNamedNestKit() {
        #expect(NestKit.name == "NestKit")
    }
}
