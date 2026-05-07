import Foundation

enum SchemeType: String, CaseIterable, Codable {
    case complementary
    case analogous
    case triadic
    case splitComplementary

    var label: String {
        switch self {
        case .complementary: "互补"
        case .analogous: "近似"
        case .triadic: "三角"
        case .splitComplementary: "分裂"
        }
    }
}
