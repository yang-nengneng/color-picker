import AppKit

final class ColorSamplerService {

    func sample(completion: @escaping (CapturedColor?) -> Void) {
        let sampler = NSColorSampler()

        sampler.show { selectedColor in
            guard let color = selectedColor else {
                completion(nil)
                return
            }
            let hex = ColorConversion.hex(from: color)
            let captured = CapturedColor(hex: hex)

            let value = ColorStore.shared.formattedValue(for: hex)
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(value, forType: .string)

            ColorStore.shared.addToHistory(captured)

            DispatchQueue.main.async {
                completion(captured)
            }
        }
    }
}
