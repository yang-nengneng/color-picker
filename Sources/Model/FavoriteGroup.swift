import Foundation

struct FavoriteGroup: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var colors: [CapturedColor]

    init(name: String, colors: [CapturedColor] = []) {
        self.id = UUID()
        self.name = name
        self.colors = colors
    }

    static func defaultGroup() -> FavoriteGroup {
        FavoriteGroup(name: "默认收藏", colors: [])
    }
}
