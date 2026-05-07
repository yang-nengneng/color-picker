import SwiftUI

struct GroupPickerPopover: View {
    let color: CapturedColor
    let groups: [FavoriteGroup]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("添加到收藏分组")
                .font(.headline)
                .padding(.bottom, 4)

            ForEach(groups) { group in
                Button {
                    ColorStore.shared.addToFavorites(color, groupId: group.id)
                    dismiss()
                } label: {
                    Label(group.name, systemImage: "folder")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 2)
            }

            Divider()

            Button {
                ColorStore.shared.createGroup(name: "新分组")
                if let newGroup = ColorStore.shared.favoriteGroups.last {
                    ColorStore.shared.addToFavorites(color, groupId: newGroup.id)
                }
                dismiss()
            } label: {
                Label("新建分组...", systemImage: "plus")
            }
            .buttonStyle(.plain)
            .padding(.vertical, 2)
        }
        .padding()
        .frame(width: 200)
    }
}
