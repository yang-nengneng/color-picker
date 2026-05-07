import Foundation

struct PresetPalette: Codable, Identifiable {
    let id: UUID
    let name: String
    let colors: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.colors = try container.decode([String].self, forKey: .colors)
    }

    init(name: String, colors: [String]) {
        self.id = UUID()
        self.name = name
        self.colors = colors
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case colors
    }
}

struct PresetCategory: Codable, Identifiable {
    let name: String
    let palettes: [PresetPalette]
    var id: String { name }
}
