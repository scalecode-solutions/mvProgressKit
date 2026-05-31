import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public extension Color {
    /// Blend toward white by `amount` (0 = unchanged, 1 = white). Used to turn
    /// a fill color into a clean light-shade unfilled track — a lightened
    /// pastel reads far cleaner on dark than a low-opacity saturated tint.
    func lightened(by amount: Double) -> Color {
        let c = rgbaComponents
        let f = max(0, min(1, amount))
        return Color(.sRGB,
                     red: c.r + (1 - c.r) * f,
                     green: c.g + (1 - c.g) * f,
                     blue: c.b + (1 - c.b) * f,
                     opacity: c.a)
    }

    private var rgbaComponents: (r: Double, g: Double, b: Double, a: Double) {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
        #elseif canImport(AppKit)
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? .white
        return (Double(ns.redComponent), Double(ns.greenComponent),
                Double(ns.blueComponent), Double(ns.alphaComponent))
        #else
        return (0.5, 0.5, 0.5, 1)
        #endif
    }
}
