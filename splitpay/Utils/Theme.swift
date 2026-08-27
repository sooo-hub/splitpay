import SwiftUI

/// Web版 (splitpay.jsx) のカラーパレットをそのまま踏襲。
enum Theme {
    static let colorA = Color(hex: "#FF5133")
    static let colorB = Color(hex: "#2563EB")
    static let colorBorrow = Color(hex: "#F97316")
    static let colorRepay = Color(hex: "#22C55E")
    static let background = Color(hex: "#F5F3EE")

    static let textPrimary = Color(hex: "#1A1A1A")
    static let textSecondary = Color(hex: "#888888")
    static let textMuted = Color(hex: "#AAAAAA")
    static let textFaint = Color(hex: "#BBBBBB")
    static let border = Color(hex: "#EDE9E2")
    static let cardBackground = Color.white

    static func userColor(_ user: String) -> Color {
        user == "A" ? colorA : colorB
    }
}

extension Color {
    /// "#RRGGBB" 形式の文字列からColorを生成する
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255
        let b = Double(rgbValue & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
