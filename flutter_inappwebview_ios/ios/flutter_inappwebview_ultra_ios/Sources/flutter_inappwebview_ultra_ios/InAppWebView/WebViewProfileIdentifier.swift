import CryptoKit
import Foundation
import WebKit

enum WebViewProfileIdentifier {
    private static let namespace = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!

    /// Empty, whitespace, and "Default" stay on the shared jar. Trimming matches
    /// Java String.trim() so both platforms apply the same name.
    static func canonical(_ name: String?) -> String? {
        guard let raw = name else {
            return nil
        }
        var scalars = raw.unicodeScalars
        while let first = scalars.first, first.value <= 32 {
            scalars.removeFirst()
        }
        while let last = scalars.last, last.value <= 32 {
            scalars.removeLast()
        }
        let trimmed = String(scalars)
        if trimmed.isEmpty || trimmed == "Default" {
            return nil
        }
        return trimmed
    }

    static func isNamed(_ name: String?) -> Bool {
        return canonical(name) != nil
    }

    /// Same profile name always maps to the same on-disk website data store.
    @available(iOS 13.0, *)
    static func uuid(for name: String) -> UUID {
        let ns = namespace.uuid
        var data = Data([
            ns.0, ns.1, ns.2, ns.3, ns.4, ns.5, ns.6, ns.7,
            ns.8, ns.9, ns.10, ns.11, ns.12, ns.13, ns.14, ns.15
        ])
        data.append(Data("lanyue.webview.profile.\(name)".utf8))
        let digest = Array(Insecure.SHA1.hash(data: data))
        var bytes = Array(digest.prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    static func dataStore(for profileName: String?) -> WKWebsiteDataStore? {
        guard let profileName = canonical(profileName) else {
            return nil
        }
        if #available(iOS 17.0, *) {
            return WKWebsiteDataStore(forIdentifier: uuid(for: profileName))
        }
        return nil
    }
}
