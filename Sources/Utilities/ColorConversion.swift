import AppKit

enum ColorConversion {

    /// NSColor 转规范的 hex 字符串（#RRGGBB）
    static func hex(from color: NSColor) -> String {
        guard let rgb = color.usingColorSpace(.sRGB) else {
            return "#000000"
        }
        let r = Int(round(rgb.redComponent * 255))
        let g = Int(round(rgb.greenComponent * 255))
        let b = Int(round(rgb.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    /// 将 hex 字符串解析为 NSColor（sRGB）
    static func nsColor(from hex: String) -> NSColor {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6,
              let value = UInt32(cleaned, radix: 16) else {
            return NSColor.black
        }
        let r = CGFloat((value >> 16) & 0xFF) / 255.0
        let g = CGFloat((value >> 8) & 0xFF) / 255.0
        let b = CGFloat(value & 0xFF) / 255.0
        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }

    /// 按指定格式格式化 hex 值
    static func format(hex: String, as format: ColorFormat) -> String {
        switch format {
        case .hex:
            return hex
        case .rgb:
            return rgbString(from: hex)
        case .hsl:
            return hslString(from: hex)
        }
    }

    /// hex → rgb(R, G, B)
    static func rgbString(from hex: String) -> String {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6,
              let value = UInt32(cleaned, radix: 16) else {
            return "rgb(0, 0, 0)"
        }
        let r = Int((value >> 16) & 0xFF)
        let g = Int((value >> 8) & 0xFF)
        let b = Int(value & 0xFF)
        return "rgb(\(r), \(g), \(b))"
    }

    /// hex → hsl(H, S%, L%)
    static func hslString(from hex: String) -> String {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6,
              let value = UInt32(cleaned, radix: 16) else {
            return "hsl(0, 0%, 0%)"
        }
        let r = CGFloat((value >> 16) & 0xFF) / 255.0
        let g = CGFloat((value >> 8) & 0xFF) / 255.0
        let b = CGFloat(value & 0xFF) / 255.0

        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)
        let delta = maxVal - minVal

        let l = (maxVal + minVal) / 2.0

        var h: CGFloat = 0
        var s: CGFloat = 0

        if delta != 0 {
            s = l > 0.5 ? delta / (2.0 - maxVal - minVal) : delta / (maxVal + minVal)
            if maxVal == r {
                h = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
            } else if maxVal == g {
                h = (b - r) / delta + 2
            } else {
                h = (r - g) / delta + 4
            }
            h *= 60
            if h < 0 { h += 360 }
        }

        return String(format: "hsl(%.0f, %.0f%%, %.0f%%)", round(h), round(s * 100), round(l * 100))
    }

    /// 根据背景 hex 计算对比文字颜色（白或黑）
    static func contrastingTextColor(for hex: String) -> NSColor {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6,
              let value = UInt32(cleaned, radix: 16) else {
            return NSColor.white
        }
        let r = CGFloat((value >> 16) & 0xFF) / 255.0
        let g = CGFloat((value >> 8) & 0xFF) / 255.0
        let b = CGFloat(value & 0xFF) / 255.0

        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return luminance > 0.5 ? NSColor.black : NSColor.white
    }
}
