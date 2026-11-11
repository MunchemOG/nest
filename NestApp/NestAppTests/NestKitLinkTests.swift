import Testing
import NestKit

struct NestKitLinkTests {
    @Test func appTestsCanUseNestKit() {
        #expect(NestKit.name == "NestKit")
    }
}
