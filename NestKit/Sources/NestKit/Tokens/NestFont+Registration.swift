import CoreText
import Foundation

extension NestFont {
    /// Makes the bundled font files available to this process. Safe to call more than once.
    public static func registerBundledFonts() throws {
        guard let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts"), !urls.isEmpty else {
            throw CocoaError(.fileNoSuchFile)
        }
        for url in urls {
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) { continue }
            guard let failure = error?.takeRetainedValue() else { continue }
            if CFErrorGetCode(failure) == CTFontManagerError.alreadyRegistered.rawValue { continue }
            throw failure
        }
    }
}
