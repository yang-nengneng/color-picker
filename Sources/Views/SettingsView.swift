import SwiftUI
import AppKit
import KeyboardShortcuts

struct SettingsView: View {
    @ObservedObject private var store = ColorStore.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var showClearHistoryAlert = false

    var body: some View {
        TabView {
            Form {
                Section {
                    Picker(selection: Binding(
                        get: { store.defaultFormat },
                        set: { store.setDefaultFormat($0) }
                    )) {
                        ForEach(ColorFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    } label: {
                        Label("默认颜色格式", systemImage: "paintpalette")
                    }
                    .pickerStyle(.menu)

                    Picker(selection: $theme.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { t in
                            Text(t.label).tag(t)
                        }
                    } label: {
                        Label("主题外观", systemImage: "circle.lefthalf.filled")
                    }
                    .pickerStyle(.menu)
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("通用", systemImage: "gearshape") }

            Form {
                Section {
                    LabeledContent {
                        KeyboardShortcuts.Recorder(for: .pickColor) { _ in }
                    } label: {
                        Label("取色", systemImage: "eyedropper")
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("快捷键", systemImage: "command") }

            Form {
                Section {
                    Picker(selection: $store.historyRetention) {
                        ForEach(HistoryRetention.allCases, id: \.self) { r in
                            Text(r.label).tag(r)
                        }
                    } label: {
                        Label("历史保存时长", systemImage: "calendar")
                    }
                    .pickerStyle(.menu)

                    HStack {
                        Label("取色历史", systemImage: "clock")
                        Spacer()
                        Text("\(store.history.count) 条")
                            .foregroundColor(.secondary)
                        Button("清除") {
                            showClearHistoryAlert = true
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("数据", systemImage: "folder") }

            Form {
                Section {
                    VStack(spacing: 12) {
                        let iconPath = (Bundle.main.resourcePath ?? "") + "/AppIcon.icns"
                        if let image = NSImage(contentsOfFile: iconPath) {
                            Image(nsImage: image)
                                .resizable()
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        }

                        VStack(spacing: 4) {
                            Text("ColorPicker")
                                .font(.system(size: 18, weight: .bold))
                            Text("版本 1.0")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        Text("一款轻量的 macOS 屏幕取色工具")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }

                Section {
                    HStack {
                        Spacer()
                        Button("退出 ColorPicker") {
                            NSApp.terminate(nil)
                        }
                        .controlSize(.small)
                        Spacer()
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("关于", systemImage: "info.circle") }
        }
        .frame(width: 420, height: 320)
        .onAppear {
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .alert("确认清除", isPresented: $showClearHistoryAlert) {
            Button("取消", role: .cancel) {}
            Button("清除", role: .destructive) { store.clearHistory() }
        } message: {
            Text("确定要清除全部 \(store.history.count) 条历史记录吗？此操作不可撤销。")
        }
    }
}

extension KeyboardShortcuts.Name {
    static let pickColor = Self("pickColor", default: .init(.c, modifiers: [.command, .shift]))
}
