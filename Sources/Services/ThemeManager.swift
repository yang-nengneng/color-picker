import SwiftUI
import AppKit

enum AppTheme: String, CaseIterable, Codable {
    case system
    case light
    case dark

    var label: String {
        switch self {
        case .system: "跟随系统"
        case .light: "浅色"
        case .dark: "深色"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var theme: AppTheme = .system {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: "appTheme")
            apply()
        }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: "appTheme"),
           let saved = AppTheme(rawValue: raw) {
            theme = saved
        }
        apply()
    }

    var colorScheme: ColorScheme? {
        theme.colorScheme
    }

    private func apply() {
        let appearance: NSAppearance? = switch theme {
        case .dark: NSAppearance(named: .darkAqua)
        case .light: NSAppearance(named: .aqua)
        case .system: nil
        }
        NSApp.appearance = appearance
        // 刷新所有已打开窗口
        for window in NSApp.windows {
            window.appearance = appearance
            window.contentView?.needsDisplay = true
        }
    }
}
