import SwiftUI
import KeyboardShortcuts

enum PanelTab: Int, CaseIterable {
    case picker
    case palette
    case history
    case favorites

    var icon: String {
        switch self {
        case .picker: "eyedropper"
        case .palette: "paintpalette"
        case .history: "clock"
        case .favorites: "star"
        }
    }

    var title: String {
        switch self {
        case .picker: "取色"
        case .palette: "调色"
        case .history: "历史"
        case .favorites: "收藏"
        }
    }
}

// MARK: - 主视图

struct ColorPanelView: View {
    @ObservedObject private var store = ColorStore.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var tab: PanelTab = .picker
    @State private var showCopied = false
    @State private var copiedHex: String?
    @State private var renameGroup: FavoriteGroup?
    @State private var renameText = ""
    @State private var showNewGroup = false
    @State private var newGroupName = ""
    @State private var pendingColorForNewGroup: CapturedColor?
    @State private var showDeleteConfirm = false
    @State private var showClearHistoryAlert = false
    @State private var pendingDeleteGroup: FavoriteGroup?

    private let sampler = ColorSamplerService()

    @State private var shortcutString: String = KeyboardShortcuts.getShortcut(for: .pickColor)?.description ?? "⌘⇧C"

    var body: some View {
        VStack(spacing: 0) {
            // 内容区
            ZStack {
                pickerTab
                    .opacity(tab == .picker ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: tab)

                paletteTab
                    .opacity(tab == .palette ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: tab)

                historyTab
                    .opacity(tab == .history ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: tab)

                favoritesTab
                    .opacity(tab == .favorites ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: tab)
            }

            // 底部 Tab 栏
            Divider()
            HStack(spacing: 0) {
                ForEach(PanelTab.allCases, id: \.rawValue) { item in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { tab = item }
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: item.icon)
                                .font(.system(size: 14, weight: tab == item ? .semibold : .regular))
                            Text(item.title)
                                .font(.system(size: 9, weight: tab == item ? .semibold : .regular))
                        }
                        .foregroundColor(tab == item ? .accentColor : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 2)
            .padding(.bottom, 4)
        }
        .frame(width: 280, height: 560)
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) { pendingDeleteGroup = nil }
            Button("删除", role: .destructive) {
                if let group = pendingDeleteGroup {
                    store.deleteGroup(group)
                    if favGroupId == group.id {
                        favGroupId = store.favoriteGroups.first?.id
                    }
                }
                pendingDeleteGroup = nil
            }
        } message: {
            if let group = pendingDeleteGroup {
                Text("确定要删除「\(group.name)」分组及其所有颜色吗？")
            }
        }
        .alert("确认清除", isPresented: $showClearHistoryAlert) {
            Button("取消", role: .cancel) {}
            Button("清除", role: .destructive) { store.clearHistory() }
        } message: {
            Text("确定要清除全部历史记录吗？此操作不可撤销。")
        }
        .preferredColorScheme(theme.colorScheme)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("KeyboardShortcuts_shortcutByNameDidChange"))) { notification in
            guard (notification.userInfo?["name"] as? KeyboardShortcuts.Name) == .pickColor else { return }
            shortcutString = KeyboardShortcuts.getShortcut(for: .pickColor)?.description ?? "⌘⇧C"
        }
    }

    // MARK: - 取色页

    @State private var hoveredColor: CapturedColor?
    @State private var hoveredFromScheme = false

    private var pickerTab: some View {
        VStack(spacing: 0) {
            // 取色按钮区
            VStack(spacing: 4) {
                HStack {
                    Button {
                        NSApp.sendAction(#selector(AppDelegate.openImagePalette), to: NSApp.delegate, from: nil)
                    } label: {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    SettingsLink {
                        Image(systemName: "gearshape")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)

                PickCircleButton(action: performSample)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .padding(.bottom, 12)

            Divider().padding(.horizontal, 16)

            VStack(spacing: 0) {
                // 格式选择
                HStack(spacing: 8) {
                    Text("格式")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 1) {
                        ForEach(ColorFormat.allCases, id: \.self) { format in
                            Button {
                                store.setDefaultFormat(format)
                            } label: {
                                Text(format.rawValue)
                                    .font(.system(size: 10, weight: store.defaultFormat == format ? .semibold : .regular))
                                    .foregroundColor(store.defaultFormat == format ? .white : .secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(
                                        store.defaultFormat == format
                                            ? RoundedRectangle(cornerRadius: 5).fill(Color.accentColor)
                                            : RoundedRectangle(cornerRadius: 5).fill(Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(2)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.07)))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Divider().padding(.horizontal, 16)

                // 悬浮预览区（固定高度防止闪烁）
                ZStack {
                    if let color = hoveredColor {
                        CompactColorPreview(
                            color: color,
                            formattedValue: store.formattedValue(for: color.hex),
                            showTime: !hoveredFromScheme,
                            copiedHex: $copiedHex,
                            showCopied: $showCopied
                        )
                        .transition(.opacity.animation(.easeInOut(duration: 0.12)))
                    } else {
                        VStack(spacing: 4) {
                            Text("\(shortcutString) 取色")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary.opacity(0.6))
                            Text("悬停色块预览")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.3))
                        }
                        .transition(.opacity.animation(.easeInOut(duration: 0.12)))
                    }
                }
                .frame(height: 68)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.04))
                )
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 8)

                // 最近取色
                let recent = Array(store.history.prefix(12))
                VStack(spacing: 6) {
                    HStack {
                        Text("最近")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                    }

                    if recent.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "circle.grid.2x2")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary.opacity(0.2))
                            Text("取色后显示")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    } else {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6),
                            spacing: 8
                        ) {
                            ForEach(recent) { color in
                                ColorDot(
                                    color: color,
                                    isActive: copiedHex == color.hex,
                                    onTap: {
                                        copyToClipboard(hex: color.hex)
                                        store.moveToFront(color)
                                        copiedHex = color.hex
                                        showCopied = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            if copiedHex == color.hex { showCopied = false; copiedHex = nil }
                                        }
                                    }
                                )
                                .contextMenu { colorContextMenu(for: color) }
                                .onHover { hovering in
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        hoveredColor = hovering ? color : nil
                                        hoveredFromScheme = false
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.03))
                )
                .padding(.horizontal, 12)
            }

            // 配色方案
            VStack(spacing: 6) {
                HStack {
                    Text("配色方案")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                if store.history.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "paintpalette")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary.opacity(0.2))
                        Text("取色后显示")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                } else {
                    SchemePickerView(onHoverColor: { color in
                        hoveredColor = color
                        hoveredFromScheme = color != nil
                    })
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.03))
            )
            .padding(.horizontal, 12)
            .padding(.top, 10)

            Spacer(minLength: 0)
        }
    }

    // MARK: - 调色板页

    private var paletteTab: some View {
        PaletteTabView()
    }

    // MARK: - 历史页

    private var historyTab: some View {
        VStack(spacing: 0) {
            // 页头
            HStack {
                Text("历史记录")
                    .font(.system(size: 12, weight: .semibold))
                if !store.history.isEmpty {
                    Text("\(store.history.count)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.primary.opacity(0.07))
                        )
                }
                Spacer()
                if !store.history.isEmpty {
                    Button("清除") {
                        showClearHistoryAlert = true
                    }
                    .font(.system(size: 11))
                    .buttonStyle(SmallActionButtonStyle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            if store.history.isEmpty {
                emptyState(icon: "clock.badge.questionmark", text: "暂无记录")
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 6) {
                        ForEach(store.history) { color in
                            CompactColorRow(color: color, formattedValue: store.formattedValue(for: color.hex), onCopy: {
                                copyToClipboard(hex: color.hex)
                            }, menu: {
                                Button("复制") { copyToClipboard(hex: color.hex) }
                                Menu("添加到收藏分组") {
                                    ForEach(store.favoriteGroups) { group in
                                        Button(group.name) {
                                            ColorStore.shared.addToFavorites(color, groupId: group.id)
                                        }
                                    }
                                    Divider()
                                    Button("新建分组...") {
                                        pendingColorForNewGroup = color
                                        newGroupName = ""
                                        showNewGroup = true
                                    }
                                }
                                Divider()
                                Button("删除") {
                                    withAnimation { store.removeFromHistory(color) }
                                }
                            })
                            .padding(.horizontal, 14)
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
        }
    }

    // MARK: - 收藏页

    @State private var favGroupId: UUID?

    private var favoritesTab: some View {
        VStack(spacing: 0) {
            HStack {
                Text("收藏")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Button {
                    pendingColorForNewGroup = nil
                    newGroupName = ""
                    showNewGroup = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(SubtleIconButtonStyle())
                .popover(isPresented: $showNewGroup) {
                    NewGroupPopover(
                        name: $newGroupName,
                        onConfirm: {
                            let name = newGroupName.trimmingCharacters(in: .whitespaces)
                            if !name.isEmpty {
                                store.createGroup(name: name)
                                if let color = pendingColorForNewGroup,
                                   let newGroup = store.favoriteGroups.last {
                                    store.addToFavorites(color, groupId: newGroup.id)
                                }
                                favGroupId = store.favoriteGroups.last?.id
                            }
                            newGroupName = ""
                            pendingColorForNewGroup = nil
                            showNewGroup = false
                        },
                        onCancel: {
                            newGroupName = ""
                            pendingColorForNewGroup = nil
                            showNewGroup = false
                        }
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // 分组标签
            if !store.favoriteGroups.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(store.favoriteGroups) { group in
                            Button {
                                favGroupId = group.id
                            } label: {
                                Text(group.name)
                                    .font(.system(size: 10, weight: favGroupId == group.id ? .semibold : .regular))
                                    .foregroundColor(favGroupId == group.id ? .white : .secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        favGroupId == group.id
                                            ? RoundedRectangle(cornerRadius: 5).fill(Color.accentColor)
                                            : RoundedRectangle(cornerRadius: 5).fill(Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                            .popover(isPresented: Binding(
                                get: { renameGroup?.id == group.id },
                                set: { if !$0 { renameGroup = nil } }
                            )) {
                                VStack(spacing: 12) {
                                    Text("重命名分组")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.primary)
                                    TextField("输入名称", text: $renameText)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 13))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.primary.opacity(0.06))
                                        )
                                        .frame(width: 180)
                                        .onSubmit {
                                            let name = renameText.trimmingCharacters(in: .whitespaces)
                                            if !name.isEmpty {
                                                store.renameGroup(group, to: name)
                                            }
                                            renameGroup = nil
                                        }
                                    HStack(spacing: 8) {
                                        Spacer()
                                        Button("取消") { renameGroup = nil }
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                            .buttonStyle(.plain)
                                        Button("保存") {
                                            let name = renameText.trimmingCharacters(in: .whitespaces)
                                            if !name.isEmpty {
                                                store.renameGroup(group, to: name)
                                            }
                                            renameGroup = nil
                                        }
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 5)
                                        .background(
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(Color.accentColor)
                                        )
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(14)
                            }
                            .contextMenu {
                                if group.name != "默认收藏" {
                                    Button("重命名") {
                                        renameGroup = group
                                        renameText = group.name
                                    }
                                    Divider()
                                    Button("删除分组") {
                                        if group.colors.isEmpty {
                                            store.deleteGroup(group)
                                            if favGroupId == group.id {
                                                favGroupId = store.favoriteGroups.first?.id
                                            }
                                        } else {
                                            pendingDeleteGroup = group
                                            showDeleteConfirm = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                }
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.03))

                Divider()
            }

            if let groupId = favGroupId,
               let group = store.favoriteGroups.first(where: { $0.id == groupId }) {
                if group.colors.isEmpty {
                    emptyState(icon: "star.slash", text: "暂无收藏")
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 6) {
                            ForEach(group.colors) { color in
                                CompactColorRow(color: color, formattedValue: store.formattedValue(for: color.hex), showTime: false, onCopy: {
                                    copyToClipboard(hex: color.hex)
                                }, menu: {
                                    Button("复制") { copyToClipboard(hex: color.hex) }
                                    Menu("移动到分组") {
                                        ForEach(store.favoriteGroups) { g in
                                            if g.id != groupId {
                                                Button(g.name) {
                                                    store.moveColor(color, from: groupId, to: g.id)
                                                }
                                            }
                                        }
                                    }
                                    Divider()
                                    Button("从收藏中删除") {
                                        store.removeFromFavorites(color, groupId: groupId)
                                    }
                                })
                                .padding(.horizontal, 14)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                }
            } else {
                emptyState(icon: "folder", text: "选择分组")
            }
        }
        .onAppear {
            if favGroupId == nil {
                favGroupId = store.favoriteGroups.first?.id
            }
        }
    }

    // MARK: - 取色操作

    private func performSample() {
        MenuBarControllerRef?.closePopover()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            sampler.sample { _ in
                guard let latest = store.history.first else { return }
                DispatchQueue.main.async {
                    showCopied = true
                    copiedHex = latest.hex
                    MenuBarControllerRef?.showPopover()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showCopied = false
                        copiedHex = nil
                    }
                }
            }
        }
    }

    private func copyToClipboard(hex: String) {
        let value = store.formattedValue(for: hex)
        NSPasteboard.general.declareTypes([.string], owner: nil)
        NSPasteboard.general.setString(value, forType: .string)
    }

    private func colorContextMenu(for color: CapturedColor) -> some View {
        Group {
            Button("复制") {
                copyToClipboard(hex: color.hex)
            }
            Menu("添加到收藏分组") {
                ForEach(store.favoriteGroups) { group in
                    Button(group.name) {
                        ColorStore.shared.addToFavorites(color, groupId: group.id)
                    }
                }
                Divider()
                Button("新建分组...") {
                    store.createGroup(name: "新分组")
                    if let newGroup = store.favoriteGroups.last {
                        store.addToFavorites(color, groupId: newGroup.id)
                    }
                }
            }
        }
    }

    private func emptyState(icon: String, text: String) -> some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.secondary.opacity(0.25))
                Text(text)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

// MARK: - 紧凑色块预览

struct CompactColorPreview: View {
    let color: CapturedColor
    let formattedValue: String
    var showTime: Bool = true
    @Binding var copiedHex: String?
    @Binding var showCopied: Bool

    var body: some View {
        let hex = color.hex
        let bgColor = Color(nsColor: ColorConversion.nsColor(from: hex))

        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(bgColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: bgColor.opacity(0.35), radius: 8, y: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text(formattedValue)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(nsColor: ColorConversion.contrastingTextColor(for: hex)))

                HStack(spacing: 6) {
                    if showTime {
                        Text("· \(timeFormatter.localizedString(for: color.timestamp, relativeTo: Date()))")
                            .font(.system(size: 10))
                            .foregroundColor(Color(nsColor: ColorConversion.contrastingTextColor(for: hex)).opacity(0.6))
                    }

                    if showCopied, copiedHex == hex {
                        Text("已复制")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color(nsColor: ColorConversion.contrastingTextColor(for: hex)).opacity(0.8))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(RoundedRectangle(cornerRadius: 3).fill(Color.black.opacity(0.12)))
                    }
                }
            }
            .padding(.horizontal, 14)
        }
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            NSPasteboard.general.declareTypes([.string], owner: nil)
            NSPasteboard.general.setString(formattedValue, forType: .string)
            copiedHex = hex
            showCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if copiedHex == hex { showCopied = false; copiedHex = nil }
            }
        }
        .contextMenu {
            Button("复制") {
                NSPasteboard.general.declareTypes([.string], owner: nil)
                NSPasteboard.general.setString(formattedValue, forType: .string)
            }
            Menu("添加到收藏分组") {
                ForEach(ColorStore.shared.favoriteGroups) { group in
                    Button(group.name) {
                        ColorStore.shared.addToFavorites(color, groupId: group.id)
                    }
                }
                Divider()
                Button("新建分组...") {
                    ColorStore.shared.createGroup(name: "新分组")
                    if let newGroup = ColorStore.shared.favoriteGroups.last {
                        ColorStore.shared.addToFavorites(color, groupId: newGroup.id)
                    }
                }
            }
        }
    }
}

// MARK: - 取色圆点

struct ColorDot: View {
    let color: CapturedColor
    let isActive: Bool
    let onTap: () -> Void
    @State private var isHovered = false

    var body: some View {
        let hex = color.hex
        let bgColor = Color(nsColor: ColorConversion.nsColor(from: hex))

        Circle()
            .fill(bgColor)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(isHovered ? 0.2 : 0.1), radius: isHovered ? 6 : 3, y: 2)
            .aspectRatio(1, contentMode: .fit)
            .scaleEffect(isHovered ? 1.12 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onTapGesture { onTap() }
            .onHover { hovering in isHovered = hovering }
    }
}

// MARK: - 紧凑色块行

struct CompactColorRow<M: View>: View {
    let color: CapturedColor
    let formattedValue: String
    let onCopy: () -> Void
    let menu: M
    var showTime: Bool = true
    @State private var isHovered = false

    init(color: CapturedColor, formattedValue: String, showTime: Bool = true, onCopy: @escaping () -> Void, @ViewBuilder menu: () -> M) {
        self.color = color
        self.formattedValue = formattedValue
        self.showTime = showTime
        self.onCopy = onCopy
        self.menu = menu()
    }

    var body: some View {
        let hex = color.hex
        let bgColor = Color(nsColor: ColorConversion.nsColor(from: hex))
        let textColor = Color(nsColor: ColorConversion.contrastingTextColor(for: hex))

        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(bgColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(isHovered ? 0.12 : 0.04), radius: isHovered ? 8 : 4, y: 3)
                .frame(height: showTime ? 42 : 36)
                .scaleEffect(isHovered ? 1.02 : 1.0)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedValue)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(textColor)
                    if showTime {
                        Text(timeFormatter.localizedString(for: color.timestamp, relativeTo: Date()))
                            .font(.system(size: 10))
                            .foregroundColor(textColor.opacity(0.55))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 14)
        }
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture { onCopy() }
        .contextMenu { menu }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) { isHovered = hovering }
        }
    }
}

// MARK: - 按钮样式

struct SubtleIconButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isHovered ? .primary : .secondary)
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
            .onHover { hovering in isHovered = hovering }
    }
}

struct SmallActionButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(isHovered ? .primary : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
            )
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in isHovered = hovering }
    }
}

// MARK: - 取色圆形按钮

// MARK: - 配色方案选择器（嵌入取色页）

struct SchemePickerView: View {
    @ObservedObject private var store = ColorStore.shared
    @State private var schemeType: SchemeType = .complementary
    var onHoverColor: ((CapturedColor?) -> Void)?

    private var baseColorHex: String {
        store.history.first?.hex ?? "#FF6B35"
    }

    var body: some View {
        let schemeColors = ColorPaletteService.shared.generateScheme(baseHex: baseColorHex, type: schemeType)

        VStack(spacing: 6) {
            Divider()

            // 基色 + 方案切换
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(nsColor: ColorConversion.nsColor(from: baseColorHex)))
                    .frame(width: 16, height: 16)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.2), lineWidth: 0.5))

                Text(baseColorHex)
                    .font(.system(size: 10, design: .monospaced))

                Spacer()

                ForEach(SchemeType.allCases, id: \.rawValue) { type in
                    Button {
                        schemeType = type
                    } label: {
                        Text(type.label)
                            .font(.system(size: 9, weight: schemeType == type ? .semibold : .regular))
                            .foregroundColor(schemeType == type ? .white : .secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                schemeType == type
                                    ? RoundedRectangle(cornerRadius: 4).fill(Color.accentColor)
                                    : RoundedRectangle(cornerRadius: 4).fill(Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // 方案色板列表（可滚动）
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 3) {
                    ForEach(schemeColors, id: \.self) { hex in
                        SchemeColorRow(hex: hex, onHover: { hovering in
                            onHoverColor?(hovering ? CapturedColor(hex: hex) : nil)
                        })
                    }
                }
            }
            .frame(maxHeight: 160)
        }
    }
}

// MARK: - 方案色块行

struct SchemeColorRow: View {
    let hex: String
    let onHover: (Bool) -> Void

    var body: some View {
        let bgColor = Color(nsColor: ColorConversion.nsColor(from: hex))
        let textColor = Color(nsColor: ColorConversion.contrastingTextColor(for: hex))

        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(bgColor)
                .frame(height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.white, lineWidth: 1.5)
                )

            HStack {
                Text(ColorStore.shared.formattedValue(for: hex))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(textColor)
                Spacer()
            }
            .padding(.horizontal, 10)
        }
        .contentShape(RoundedRectangle(cornerRadius: 5))
            .onTapGesture {
                let value = ColorStore.shared.formattedValue(for: hex)
                NSPasteboard.general.declareTypes([.string], owner: nil)
                NSPasteboard.general.setString(value, forType: .string)
                ColorStore.shared.addToHistory(CapturedColor(hex: hex))
            }
            .contextMenu {
                Button("复制") {
                    let value = ColorStore.shared.formattedValue(for: hex)
                    NSPasteboard.general.declareTypes([.string], owner: nil)
                    NSPasteboard.general.setString(value, forType: .string)
                }
                Menu("添加到收藏分组") {
                    ForEach(ColorStore.shared.favoriteGroups) { group in
                        Button(group.name) {
                            ColorStore.shared.addToFavorites(CapturedColor(hex: hex), groupId: group.id)
                        }
                    }
                }
            }
            .onHover { hovering in onHover(hovering) }
    }
}

struct PickCircleButton: View {
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                Color(red: 0.98, green: 0.3, blue: 0.3),
                                Color(red: 0.95, green: 0.6, blue: 0.1),
                                Color(red: 0.2, green: 0.75, blue: 0.3),
                                Color(red: 0.2, green: 0.5, blue: 0.95),
                                Color(red: 0.6, green: 0.3, blue: 0.9),
                                Color(red: 0.98, green: 0.3, blue: 0.3),
                            ],
                            center: .center
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(
                        color: Color(red: 0.5, green: 0.3, blue: 0.8).opacity(isHovered ? 0.5 : 0.3),
                        radius: isHovered ? 16 : 8,
                        y: isHovered ? 6 : 4
                    )

                Circle()
                    .stroke(Color.white.opacity(isHovered ? 0.35 : 0.2), lineWidth: 1.5)
                    .frame(width: 64, height: 64)

                Image(systemName: "eyedropper")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(.white)
            }
            .scaleEffect(isHovered ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - 新建分组 Popover

struct NewGroupPopover: View {
    @Binding var name: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("新建分组")
                .font(.system(size: 12, weight: .semibold))

            TextField("输入名称", text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.06))
                )
                .frame(width: 180)
                .onSubmit { onConfirm() }

            HStack(spacing: 8) {
                Spacer()
                Button("取消") { onCancel() }
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .buttonStyle(.plain)
                Button("创建") {
                    onConfirm()
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 5).fill(Color.accentColor)
                )
                .buttonStyle(.plain)
            }
        }
        .padding(14)
    }
}

var MenuBarControllerRef: MenuBarController?
