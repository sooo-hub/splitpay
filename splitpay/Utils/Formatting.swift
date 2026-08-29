import Foundation

enum Formatting {
    private static let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    private static let isoFormatterWithFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    /// ¥1,234 形式（絶対値・四捨五入）
    static func yen(_ amount: Double) -> String {
        let rounded = (abs(amount)).rounded()
        let str = numberFormatter.string(from: NSNumber(value: rounded)) ?? "\(Int(rounded))"
        return "¥\(str)"
    }

    /// ISO8601文字列を "M/d" 形式で表示
    static func shortDate(_ isoString: String) -> String {
        guard let date = parseISODate(isoString) else { return "" }
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.month, .day], from: date)
        return "\(comps.month ?? 0)/\(comps.day ?? 0)"
    }

    static func parseISODate(_ isoString: String) -> Date? {
        isoFormatterWithFractional.date(from: isoString) ?? isoFormatter.date(from: isoString)
    }

    /// Date を "HH:mm" 形式で表示
    static func time(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    static func nowISOString() -> String {
        isoFormatterWithFractional.string(from: Date())
    }

    static func generateId() -> String {
        let time = String(Int(Date().timeIntervalSince1970 * 1000), radix: 36)
        let rand = String(UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "").prefix(4))
        return time + rand
    }
}
