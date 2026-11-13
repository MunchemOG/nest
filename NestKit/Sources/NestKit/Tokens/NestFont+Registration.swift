import CoreText
import Foundation

extension NestFont {
    /// The bundled font files, for places that load fonts by file (such as a web view).
    public static var bundledFontURLs: [URL] {
        Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? []
    }

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
