import Darwin
import Foundation

enum TickerUpdate {
    private static let repository = "megabyte0x/macticker"
    private static let assetName = "Ticker.dmg"
    private static let developerID = """
        anchor apple generic and certificate leaf[subject.OU] = "9UR77TD484" \
        and certificate leaf[field.1.2.840.113635.100.6.1.13] exists
        """

    struct Release: Decodable {
        let tag_name: String
        let assets: [Asset]

        struct Asset: Decodable { let name: String }

        var downloadURL: URL {
            URL(string: "https://github.com/\(TickerUpdate.repository)/releases/download")!
                .appendingPathComponent(tag_name)
                .appendingPathComponent(TickerUpdate.assetName)
        }

        func isNewer(than installed: String) throws -> Bool {
            guard let current = TickerUpdate.version(installed), let latest = TickerUpdate.version(tag_name) else {
                throw Failure.invalidVersion
            }
            guard current.lexicographicallyPrecedes(latest) else { return false }
            guard assets.contains(where: { $0.name == TickerUpdate.assetName }) else { throw Failure.missingDMG }
            return true
        }
    }

    static func latest(after installed: String) async throws -> Release? {
        let url = URL(string: "https://api.github.com/repos/\(repository)/releases/latest")!
        let (data, response) = try await URLSession.shared.data(from: url)
        let status = (response as? HTTPURLResponse)?.statusCode
        if status == 404 { return nil }
        guard status == 200 else { throw Failure.download }
        let release = try JSONDecoder().decode(Release.self, from: data)
        return try release.isNewer(than: installed) ? release : nil
    }

    @concurrent static func install(_ release: Release, at installed: URL) async throws {
        guard installed.pathExtension == "app", FileManager.default.isWritableFile(atPath: installed.deletingLastPathComponent().path) else {
            throw Failure.notWritable
        }
        let (image, response) = try await URLSession.shared.download(from: release.downloadURL)
        defer { try? FileManager.default.removeItem(at: image) }
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw Failure.download }
        try installImage(image, version: release.tag_name, at: installed)
    }

    static func installImage(_ image: URL, version expected: String, at installed: URL) throws {
        try run("/usr/bin/codesign", ["--verify", "--strict", "-R=\(developerID) and notarized", image.path], failure: .untrusted)
        try run("/usr/sbin/spctl", ["--assess", "--type", "open", "--context", "context:primary-signature", image.path], failure: .untrusted)

        let files = FileManager.default
        let work = try files.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: installed, create: true)
        defer { try? files.removeItem(at: work) }
        let mount = work.appendingPathComponent("disk", isDirectory: true)
        try files.createDirectory(at: mount, withIntermediateDirectories: false)
        try run("/usr/bin/hdiutil", ["attach", "-readonly", "-nobrowse", "-noautoopen", "-mountpoint", mount.path, image.path], failure: .invalidDMG)
        let staged = work.appendingPathComponent("Ticker.app", isDirectory: true)
        do {
            defer { try? run("/usr/bin/hdiutil", ["detach", mount.path], failure: .invalidDMG) }
            try files.copyItem(at: mount.appendingPathComponent("Ticker.app"), to: staged)
        }

        let requirement = "identifier \"com.megabyte.ticker\" and \(developerID)"
        try run("/usr/bin/codesign", ["--verify", "--strict", "-R=\(requirement)", staged.path], failure: .untrusted)
        guard let bundled = Bundle(url: staged)?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              let expectedVersion = version(expected), version(bundled) == expectedVersion else { throw Failure.invalidVersion }
        // Swap on the same volume so a failed replacement leaves the installed app intact.
        guard renamex_np(staged.path, installed.path, UInt32(RENAME_SWAP)) == 0 else { throw Failure.notWritable }
    }

    private static func version(_ value: String) -> [Int]? {
        let parts = (value.hasPrefix("v") ? value.dropFirst() : value[...]).split(separator: ".", omittingEmptySubsequences: false)
        guard (2...3).contains(parts.count) else { return nil }
        let numbers = parts.compactMap { part in part.allSatisfy { $0.isASCII && $0.isNumber } ? Int(part) : nil }
        guard numbers.count == parts.count else { return nil }
        return numbers.count == 2 ? numbers + [0] : numbers
    }

    private static func run(_ executable: String, _ arguments: [String], failure: Failure) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw failure }
    }

    enum Failure: LocalizedError {
        case download, invalidVersion, missingDMG, notWritable, untrusted, invalidDMG

        var errorDescription: String? {
            switch self {
            case .download: "GitHub didn’t return the release or download. Try again later."
            case .invalidVersion: "The release version couldn’t be verified."
            case .missingDMG: "The latest release doesn’t include Ticker.dmg yet."
            case .notWritable: "Ticker couldn’t replace itself. Move it to Applications or install the update manually."
            case .untrusted: "The update couldn’t be verified as a notarized Ticker release."
            case .invalidDMG: "The update disk image couldn’t be opened."
            }
        }
    }
}
