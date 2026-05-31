import SwiftUI

public extension Color {
    /// Hex initializer supporting 12-bit (`#RGB`), 24-bit (`#RRGGBB`),
    /// and 32-bit (`#AARRGGBB`) strings. Leading `#` optional.
    init(hex: String) {
        let raw = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: raw).scanHexInt64(&value)

        let a, r, g, b: UInt64
        switch raw.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255,
                            (value >> 8) * 17,
                            (value >> 4 & 0xF) * 17,
                            (value & 0xF) * 17)
        case 6: // RRGGBB (24-bit)
            (a, r, g, b) = (255,
                            value >> 16,
                            value >> 8 & 0xFF,
                            value & 0xFF)
        case 8: // AARRGGBB (32-bit)
            (a, r, g, b) = (value >> 24,
                            value >> 16 & 0xFF,
                            value >> 8 & 0xFF,
                            value & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
