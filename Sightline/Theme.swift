import SwiftUI

// MARK: - Hex helper
extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// Dynamic color that adapts to light / dark automatically.
private func dyn(_ light: String, _ dark: String) -> Color {
    Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light))
    })
}

// MARK: - Palette (mirrors the Sightline prototype)
enum Theme {
    static let bg        = dyn("E7EDE9", "070C0A")
    static let surface   = dyn("FFFFFF", "111A16")
    static let surface2  = dyn("F4F8F6", "16211C")
    static let surface3  = dyn("EAF1EE", "1C2822")

    static let ink       = dyn("12201B", "EAF2ED")
    static let muted     = dyn("5C6B64", "95A69D")
    static let faint     = dyn("8A988F", "66766D")
    static let line      = dyn("E2E9E5", "233029")
    static let lineStrong = dyn("D3DDD8", "2C3B33")

    static let accent    = dyn("0E7C66", "3ACAA4")
    static let accentInk = dyn("0A5C4C", "7FE3C9")
    static let accentSoft = dyn("D6EDE5", "153029")

    static let good      = dyn("15954A", "3DBE72")
    static let goodSoft  = dyn("D6EFDE", "13291B")
    static let warn      = dyn("C07B00", "E5A83B")
    static let warnSoft  = dyn("F6E7C8", "2E2410")
    static let bad       = dyn("D6402C", "F06A55")
    static let badSoft   = dyn("F7DDD7", "301712")

    // Hero card: a fixed, deep green in BOTH themes so dark mode isn't a neon
    // block. White text always sits on this, so it doesn't follow the palette.
    static let heroTop = Color(hex: "0E7C66")
    static let heroBottom = Color(hex: "084638")
    static var heroGradient: LinearGradient {
        LinearGradient(colors: [heroTop, heroBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // Type
    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Currency formatting (AUD, en-AU)
enum Money {
    static func aud(_ value: Double, decimals: Int = 0) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "AUD"
        f.currencySymbol = "$"
        f.locale = Locale(identifier: "en_AU")
        f.maximumFractionDigits = decimals
        f.minimumFractionDigits = decimals
        return f.string(from: NSNumber(value: value)) ?? "$0"
    }
}
