import Foundation
import Combine

enum HistoryRetention: String, CaseIterable, Codable {
    case week
    case month
    case threeMonths
    case unlimited

    var label: String {
        switch self {
        case .week: "一周"
        case .month: "一个月"
        case .threeMonths: "三个月"
        case .unlimited: "无限"
        }
    }

    var timeInterval: TimeInterval? {
        switch self {
        case .week: 7 * 24 * 3600
        case .month: 30 * 24 * 3600
        case .threeMonths: 90 * 24 * 3600
        case .unlimited: nil
        }
    }
}

final class ColorStore: ObservableObject {
    static let shared = ColorStore()

    private let historyKey = "colorHistory"
    private let favoritesKey = "favoriteGroups"
    private let defaultFormatKey = "defaultFormat"
    private let retentionKey = "historyRetention"

    @Published var history: [CapturedColor] = []
    @Published var favoriteGroups: [FavoriteGroup] = []
    @Published var defaultFormat: ColorFormat = .hex
    @Published var historyRetention: HistoryRetention = .week {
        didSet {
            UserDefaults.standard.set(historyRetention.rawValue, forKey: retentionKey)
            pruneHistory()
        }
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        load()
        pruneHistory()
    }

    // MARK: - 历史记录

    func addToHistory(_ color: CapturedColor) {
        // 去重：已有相同 hex 则移到最前
        history.removeAll { $0.hex == color.hex }
        history.insert(color, at: 0)
        pruneHistory()
        saveHistory()
    }

    func removeFromHistory(_ color: CapturedColor) {
        history.removeAll { $0.id == color.id }
        saveHistory()
    }

    func moveToFront(_ color: CapturedColor) {
        history.removeAll { $0.id == color.id }
        history.insert(color, at: 0)
        saveHistory()
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    func pruneHistory() {
        guard let interval = historyRetention.timeInterval else { return }
        let cutoff = Date().addingTimeInterval(-interval)
        history = history.filter { $0.timestamp > cutoff }
        saveHistory()
    }

    // MARK: - 收藏管理

    func addToFavorites(_ color: CapturedColor, groupId: UUID) {
        guard let index = favoriteGroups.firstIndex(where: { $0.id == groupId }) else { return }
        guard !favoriteGroups[index].colors.contains(where: { $0.hex == color.hex }) else { return }
        favoriteGroups[index].colors.insert(color, at: 0)
        saveFavorites()
    }

    func removeFromFavorites(_ color: CapturedColor, groupId: UUID) {
        guard let index = favoriteGroups.firstIndex(where: { $0.id == groupId }) else { return }
        favoriteGroups[index].colors.removeAll { $0.id == color.id }
        saveFavorites()
    }

    func moveColor(_ color: CapturedColor, from sourceGroupId: UUID, to targetGroupId: UUID) {
        removeFromFavorites(color, groupId: sourceGroupId)
        addToFavorites(color, groupId: targetGroupId)
    }

    func createGroup(name: String) {
        let group = FavoriteGroup(name: name)
        favoriteGroups.append(group)
        saveFavorites()
    }

    func deleteGroup(_ group: FavoriteGroup) {
        favoriteGroups.removeAll { $0.id == group.id }
        if favoriteGroups.isEmpty {
            favoriteGroups.append(.defaultGroup())
        }
        saveFavorites()
    }

    func renameGroup(_ group: FavoriteGroup, to name: String) {
        guard let index = favoriteGroups.firstIndex(where: { $0.id == group.id }) else { return }
        favoriteGroups[index].name = name
        saveFavorites()
    }

    // MARK: - 格式

    func setDefaultFormat(_ format: ColorFormat) {
        defaultFormat = format
        UserDefaults.standard.set(format.rawValue, forKey: defaultFormatKey)
    }

    func formattedValue(for hex: String) -> String {
        ColorConversion.format(hex: hex, as: defaultFormat)
    }

    // MARK: - 持久化

    private func load() {
        if let raw = UserDefaults.standard.string(forKey: defaultFormatKey),
           let format = ColorFormat(rawValue: raw) {
            defaultFormat = format
        }

        if let raw = UserDefaults.standard.string(forKey: retentionKey),
           let retention = HistoryRetention(rawValue: raw) {
            historyRetention = retention
        }

        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? decoder.decode([CapturedColor].self, from: data) {
            history = decoded
        }

        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let decoded = try? decoder.decode([FavoriteGroup].self, from: data) {
            favoriteGroups = decoded
        }
        if favoriteGroups.isEmpty {
            favoriteGroups = [.defaultGroup()]
        }
    }

    private func saveHistory() {
        guard let data = try? encoder.encode(history) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }

    private func saveFavorites() {
        guard let data = try? encoder.encode(favoriteGroups) else { return }
        UserDefaults.standard.set(data, forKey: favoritesKey)
    }
}
