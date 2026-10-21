import AppKit
import SwiftUI

@main
struct Preview {
    @MainActor static func main() async throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        let defaults = UserDefaults(suiteName: "com.megabyte.ticker.site-preview")!
        defaults.removePersistentDomain(forName: "com.megabyte.ticker.site-preview")
        let store = TokenStore(defaults: defaults)
        await store.refresh()
        let view = NSHostingView(rootView: TickerView(store: store).background(Color(nsColor: .windowBackgroundColor)))
        view.appearance = NSAppearance(named: .aqua)
        view.frame = NSRect(origin: .zero, size: view.fittingSize)
        view.layoutSubtreeIfNeeded()
        let size = view.fittingSize
        view.frame = NSRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .borderless, backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: .aqua)
        window.contentView = view
        view.layoutSubtreeIfNeeded()
        let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
        view.cacheDisplay(in: view.bounds, to: rep)
        try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
        print("Rendered native TickerView: \(Int(size.width)) × \(Int(size.height)) points; menu title: \(store.menuTitle)")
    }
}
