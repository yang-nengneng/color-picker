import Foundation

struct CapturedColor: Codable, Identifiable, Equatable {
    let id: UUID
    let hex: String
    let timestamp: Date

    init(hex: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.hex = hex
        self.timestamp = timestamp
    }
}
