import SwiftUI
import AppKit
import KeyboardShortcuts

@main
struct ColorPickerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var theme = ThemeManager.shared

    var body: some Scene {
        Settings {
            SettingsView()
                .preferredColorScheme(theme.colorScheme)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let menuBar = MenuBarController()
    private let sampler = ColorSamplerService()
    private var imagePaletteWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBar.setup()
        MenuBarControllerRef = menuBar
        OpenSettingsWindow = { [weak self] in self?.openSettings() }

        KeyboardShortcuts.onKeyDown(for: .pickColor) { [weak self] in
            self?.sampleFromHotkey()
        }

        NSApp.setActivationPolicy(.accessory)
    }

    private func sampleFromHotkey() {
        sampler.sample { _ in }
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    @objc func openImagePalette() {
        if imagePaletteWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 380, height: 500),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "图片取色"
            window.contentView = NSHostingView(rootView: ImagePaletteWindow())
            window.center()
            window.isReleasedWhenClosed = false
            window.delegate = self
            imagePaletteWindow = window
        }
        imagePaletteWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            if window === imagePaletteWindow {
                imagePaletteWindow = nil
            }
        }
    }
}

var OpenSettingsWindow: (() -> Void)?
