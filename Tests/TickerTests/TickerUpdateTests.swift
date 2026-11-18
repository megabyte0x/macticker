import Testing
@testable import Ticker

@Test func updatesRequireANewerVersionWithTheExpectedDMG() throws {
    let release = TickerUpdate.Release(tag_name: "v1.10", assets: [.init(name: "Ticker.dmg")])
    #expect(try release.isNewer(than: "1.9.8"))
    #expect(try !release.isNewer(than: "1.10.0"))
    #expect(try !release.isNewer(than: "1.10.1"))
    #expect(release.downloadURL.absoluteString == "https://github.com/megabyte0x/macticker/releases/download/v1.10/Ticker.dmg")

    let missingDMG = TickerUpdate.Release(tag_name: "v1.10.1", assets: [.init(name: "test.dmg")])
    #expect(throws: TickerUpdate.Failure.missingDMG) { try missingDMG.isNewer(than: "1.10.0") }

    let prerelease = TickerUpdate.Release(tag_name: "v1.11.0-beta", assets: [.init(name: "Ticker.dmg")])
    #expect(throws: TickerUpdate.Failure.invalidVersion) { try prerelease.isNewer(than: "1.10.0") }
}
