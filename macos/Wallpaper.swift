import Cocoa
import WebKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
// The shared renderer, wallpaper.html, copied into the app bundle by install.sh.
let html = try! String(contentsOf: Bundle.main.url(forResource: "wallpaper", withExtension: "html")!, encoding: .utf8)
// One wallpaper window per display, refitted whenever displays are added, removed, or change resolution.
var windows: [NSWindow] = []
func fit() {
    let screens = NSScreen.screens
    while windows.count > screens.count { windows.removeLast().close() }
    while windows.count < screens.count {
        let window = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = true
        let web = WKWebView(frame: .zero)
        web.autoresizingMask = [.width, .height]
        window.contentView = web
        web.loadHTMLString(html, baseURL: URL(string: "https://commonstudios.dk/"))
        windows.append(window)
    }
    for (window, screen) in zip(windows, screens) {
        window.setFrame(screen.frame, display: true)
        window.orderFrontRegardless()
    }
}
fit()
NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { _ in fit() }
app.run()
