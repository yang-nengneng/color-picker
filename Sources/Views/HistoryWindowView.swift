import SwiftUI

let timeFormatter: RelativeDateTimeFormatter = {
    let f = RelativeDateTimeFormatter()
    f.locale = Locale(identifier: "zh_CN")
    return f
}()

// MARK: - 历史记录色块

struct HistoryColorBlock: View {
    let color: CapturedColor
    let formattedValue: String
    let textColor: Color
    let isCopied: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        let bgColor = Color(nsColor: ColorConversion.nsColor(from: color.hex))

        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(bgColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
                .shadow(color: bgColor.opacity(isHovered ? 0.35 : 0.12), radius: isHovered ? 6 : 3, y: isHovered ? 3 : 1)
                .frame(height: 44)
                .scaleEffect(isHovered ? 1.01 : 1.0)

            HStack(spacing: 6) {
                Text(formattedValue)
                    .font(.system(.body, design: .monospaced, weight: .medium))
                    .foregroundColor(textColor)

                Text("· \(timeFormatter.localizedString(for: color.timestamp, relativeTo: Date()))")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(textColor.opacity(0.6))

                Spacer()

                if isCopied {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(textColor)
                }
            }
            .padding(.horizontal, 14)
        }
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture { onCopy() }
        .contextMenu {
            Button("复制") { onCopy() }
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
            Divider()
            Button("删除") { onDelete() }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
