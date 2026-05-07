import SwiftUI
import AppKit

struct PaletteTabView: View {
    @ObservedObject private var store = ColorStore.shared
    @State private var presetCategory: String = "Material Design"
    @State private var hoveredHex: String?

    private let service = ColorPaletteService.shared

    var body: some View {
        VStack(spacing: 0) {
            // 悬浮预览区
            ZStack {
                if let hex = hoveredHex {
                    CompactPalettePreview(hex: hex)
                        .transition(.opacity.animation(.easeInOut(duration: 0.12)))
                } else {
                    Text("悬停色块预览")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.35))
                        .transition(.opacity.animation(.easeInOut(duration: 0.12)))
                }
            }
            .frame(height: 52)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.04))
            )
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider().padding(.horizontal, 14)

            // 标题栏
            HStack {
                Text("预设色板")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            // 分类标签
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    let categories = service.presets.map { $0.name }
                    ForEach(categories, id: \.self) { cat in
                        Button {
                            presetCategory = cat
                        } label: {
                            Text(cat)
                                .font(.system(size: 10, weight: presetCategory == cat ? .semibold : .regular))
                                .foregroundColor(presetCategory == cat ? .white : .secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    presetCategory == cat
                                        ? RoundedRectangle(cornerRadius: 5).fill(Color.accentColor)
                                        : RoundedRectangle(cornerRadius: 5).fill(Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
            }
            .padding(.vertical, 8)

            Divider().padding(.horizontal, 14)

            // 色板网格
            if let category = service.presets.first(where: { $0.name == presetCategory }) {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        ForEach(category.palettes) { palette in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(palette.name)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 2)

                                HStack(spacing: 3) {
                                    ForEach(palette.colors, id: \.self) { hex in
                                        PaletteColorBlock(hex: hex)
                                            .onTapGesture {
                                                let value = store.formattedValue(for: hex)
                                                NSPasteboard.general.declareTypes([.string], owner: nil)
                                                NSPasteboard.general.setString(value, forType: .string)
                                                store.addToHistory(CapturedColor(hex: hex))
                                            }
                                            .onHover { hovering in
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    hoveredHex = hovering ? hex : nil
                                                }
                                            }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                }
            }
        }
    }
}

// MARK: - 色块组件

struct PaletteColorBlock: View {
    let hex: String
    @State private var isHovered = false

    var body: some View {
        let bgColor = Color(nsColor: ColorConversion.nsColor(from: hex))

        RoundedRectangle(cornerRadius: 4)
            .fill(bgColor)
            .frame(height: 28)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white, lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(isHovered ? 0.15 : 0.05), radius: isHovered ? 6 : 2, y: 2)
            .scaleEffect(isHovered ? 1.08 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in isHovered = hovering }
    }
}

// MARK: - 紧凑预览

struct CompactPalettePreview: View {
    let hex: String

    var body: some View {
        let bgColor = Color(nsColor: ColorConversion.nsColor(from: hex))
        let textColor = Color(nsColor: ColorConversion.contrastingTextColor(for: hex))

        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(bgColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: bgColor.opacity(0.35), radius: 8, y: 3)

            HStack {
                Text(ColorStore.shared.formattedValue(for: hex))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(textColor)
                Spacer()
            }
            .padding(.horizontal, 14)
        }
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            let value = ColorStore.shared.formattedValue(for: hex)
            NSPasteboard.general.declareTypes([.string], owner: nil)
            NSPasteboard.general.setString(value, forType: .string)
            ColorStore.shared.addToHistory(CapturedColor(hex: hex))
        }
    }
}
