import Foundation
import CoreGraphics
import AppKit

final class ColorPaletteService {
    static let shared = ColorPaletteService()

    private var _presets: [PresetCategory]?
    var presets: [PresetCategory] {
        if let cached = _presets { return cached }
        _presets = loadPresets()
        return _presets ?? []
    }

    private init() {}

    // MARK: - 配色方案生成

    func generateScheme(baseHex: String, type: SchemeType) -> [String] {
        let hsl = hexToHSL(baseHex)
        let hues: [CGFloat]

        switch type {
        case .complementary:
            hues = [hsl.h, normalizeHue(hsl.h + 180)]
        case .analogous:
            hues = [
                normalizeHue(hsl.h - 60),
                normalizeHue(hsl.h - 30),
                hsl.h,
                normalizeHue(hsl.h + 30),
                normalizeHue(hsl.h + 60)
            ]
        case .triadic:
            hues = [hsl.h, normalizeHue(hsl.h + 120), normalizeHue(hsl.h + 240)]
        case .splitComplementary:
            let comp = normalizeHue(hsl.h + 180)
            hues = [hsl.h, normalizeHue(comp - 30), comp, normalizeHue(comp + 30)]
        }

        return hues.map { hslToHex(h: $0, s: hsl.s, l: hsl.l) }
    }

    // MARK: - HSL ↔ HEX

    private typealias HSL = (h: CGFloat, s: CGFloat, l: CGFloat)

    private func hexToHSL(_ hex: String) -> HSL {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6,
              let value = UInt32(cleaned, radix: 16) else { return (0, 0, 0) }
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
        return (h, s, l)
    }

    private func hslToHex(h: CGFloat, s: CGFloat, l: CGFloat) -> String {
        let c = (1 - abs(2 * l - 1)) * s
        let x = c * (1 - abs((h / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = l - c / 2

        let (r, g, b): (CGFloat, CGFloat, CGFloat)
        switch h {
        case 0..<60: (r, g, b) = (c, x, 0)
        case 60..<120: (r, g, b) = (x, c, 0)
        case 120..<180: (r, g, b) = (0, c, x)
        case 180..<240: (r, g, b) = (0, x, c)
        case 240..<300: (r, g, b) = (x, 0, c)
        default: (r, g, b) = (c, 0, x)
        }

        let ri = Int(round((r + m) * 255))
        let gi = Int(round((g + m) * 255))
        let bi = Int(round((b + m) * 255))
        return String(format: "#%02X%02X%02X",
            max(0, min(255, ri)),
            max(0, min(255, gi)),
            max(0, min(255, bi)))
    }

    private func normalizeHue(_ h: CGFloat) -> CGFloat {
        var hue = h.truncatingRemainder(dividingBy: 360)
        if hue < 0 { hue += 360 }
        return hue
    }

    // MARK: - 预设色板

    private func loadPresets() -> [PresetCategory]? {
        guard let url = Bundle.module.url(forResource: "presets", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        struct Wrapper: Codable { let categories: [PresetCategory] }
        return (try? JSONDecoder().decode(Wrapper.self, from: data))?.categories
    }

    // MARK: - 图片取色 (K-Means)

    func extractColors(from cgImage: CGImage) -> [String] {
        let maxK = 16
        let pixels = samplePixels(from: cgImage, maxSamples: 4000)
        guard pixels.count >= 3 else { return [] }
        let k = min(maxK, pixels.count / 50)

        // k-means++ 初始化：选择相距最远的初始聚类中心
        var centroids: [(r: UInt8, g: UInt8, b: UInt8)] = [pixels.randomElement() ?? pixels[0]]
        for _ in 1..<k {
            var bestPixel = pixels[0]
            var bestDist = 0
            for p in pixels {
                let minDist = centroids.map { c in
                    let dr = Int(p.r) - Int(c.r), dg = Int(p.g) - Int(c.g), db = Int(p.b) - Int(c.b)
                    return dr * dr + dg * dg + db * db
                }.min() ?? 0
                if minDist > bestDist { bestDist = minDist; bestPixel = p }
            }
            centroids.append(bestPixel)
        }

        var clusters: [[(r: UInt8, g: UInt8, b: UInt8)]] = []
        for _ in 0..<30 {
            clusters = Array(repeating: [], count: k)
            for p in pixels {
                var best = 0
                var bestDist = Int.max
                for (i, c) in centroids.enumerated() {
                    let dr = Int(p.r) - Int(c.r)
                    let dg = Int(p.g) - Int(c.g)
                    let db = Int(p.b) - Int(c.b)
                    let dist = dr * dr + dg * dg + db * db
                    if dist < bestDist { bestDist = dist; best = i }
                }
                clusters[best].append(p)
            }
            for i in 0..<k {
                guard !clusters[i].isEmpty else { continue }
                let n = clusters[i].count
                centroids[i] = (
                    r: UInt8(clusters[i].reduce(0) { $0 + Int($1.r) } / n),
                    g: UInt8(clusters[i].reduce(0) { $0 + Int($1.g) } / n),
                    b: UInt8(clusters[i].reduce(0) { $0 + Int($1.b) } / n)
                )
            }
        }

        let sorted = clusters.enumerated().sorted { $0.element.count > $1.element.count }
        var result: [String] = []
        for (i, _) in sorted {
            let c = centroids[i]
            let hex = String(format: "#%02X%02X%02X", c.r, c.g, c.b)
            if !isSimilar(hex, toAnyIn: result, threshold: 60) {
                result.append(hex)
            }
            if result.count >= k { break }
        }
        return result
    }

    private func isSimilar(_ hex: String, toAnyIn list: [String], threshold: Int) -> Bool {
        let (r1, g1, b1) = hexToRGB(hex)
        for h in list {
            let (r2, g2, b2) = hexToRGB(h)
            let dr = Int(r1) - Int(r2)
            let dg = Int(g1) - Int(g2)
            let db = Int(b1) - Int(b2)
            if dr * dr + dg * dg + db * db < threshold * threshold {
                return true
            }
        }
        return false
    }

    private func hexToRGB(_ hex: String) -> (UInt8, UInt8, UInt8) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else {
            return (0, 0, 0)
        }
        return (
            UInt8((value >> 16) & 0xFF),
            UInt8((value >> 8) & 0xFF),
            UInt8(value & 0xFF)
        )
    }

    private func samplePixels(from cgImage: CGImage, maxSamples: Int) -> [(r: UInt8, g: UInt8, b: UInt8)] {
        let width = cgImage.width, height = cgImage.height
        let scale = max(1, max(width, height) / 200)
        let w = width / scale, h = height / scale

        guard let ctx = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let data = ctx.data else { return [] }
        let ptr = data.bindMemory(to: UInt8.self, capacity: w * h * 4)

        let total = w * h
        let step = max(1, total / maxSamples)
        var result: [(r: UInt8, g: UInt8, b: UInt8)] = []
        for i in stride(from: 0, to: total, by: step) {
            let offset = i * 4
            result.append((r: ptr[offset], g: ptr[offset + 1], b: ptr[offset + 2]))
        }
        return result
    }
}
