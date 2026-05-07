import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ImagePaletteWindow: View {
    @State private var image: NSImage?
    @State private var extractedColors: [String] = []
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            // Drop zone
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 3])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primary.opacity(isDropTargeted ? 0.06 : 0.02))
                    )

                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title)
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("拖拽图片到此处")
                            .font(.system(size: 14, weight: .medium))
                        Text("或点击选择文件 / ⌘V 粘贴")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Button("选择图片...") { selectImageFile() }
                            .controlSize(.small)
                    }
                }
            }
            .frame(height: 200)
            .padding(16)
            .onDrop(of: [.fileURL, .image], isTargeted: $isDropTargeted) { providers in
                handleDrop(providers)
                return true
            }

            if image != nil {
                Divider().padding(.horizontal, 16)
            }

            Divider().padding(.horizontal, 16)

            if !extractedColors.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("提取结果")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4),
                        spacing: 4
                    ) {
                        ForEach(Array(extractedColors.enumerated()), id: \.offset) { _, hex in
                            extractedColorBlock(hex: hex)
                        }
                    }

                    HStack(spacing: 8) {
                        Button("全部复制") {
                            let text = extractedColors.map { ColorStore.shared.formattedValue(for: $0) }.joined(separator: ", ")
                            NSPasteboard.general.declareTypes([.string], owner: nil)
                            NSPasteboard.general.setString(text, forType: .string)
                        }
                        .controlSize(.small)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            } else {
                Spacer()
            }
        }
        .frame(width: 380, height: 500)
    }

    private func extractedColorBlock(hex: String) -> some View {
        let textColor = Color(nsColor: ColorConversion.contrastingTextColor(for: hex))

        return ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: ColorConversion.nsColor(from: hex)))
                .frame(height: 40)

            Text(ColorStore.shared.formattedValue(for: hex))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(textColor)
        }
        .contentShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture {
            let value = ColorStore.shared.formattedValue(for: hex)
            NSPasteboard.general.declareTypes([.string], owner: nil)
            NSPasteboard.general.setString(value, forType: .string)
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
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil),
                       let img = NSImage(contentsOf: url) {
                        DispatchQueue.main.async {
                            self.image = img
                            self.extractColors()
                        }
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    if let data = data, let img = NSImage(data: data) {
                        DispatchQueue.main.async {
                            self.image = img
                            self.extractColors()
                        }
                    }
                }
            }
        }
    }

    private func selectImageFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url,
              let img = NSImage(contentsOf: url) else { return }
        image = img
        extractColors()
    }

    private func extractColors() {
        guard let img = image,
              let cgImage = img.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return }
        extractedColors = ColorPaletteService.shared.extractColors(from: cgImage)
    }
}
