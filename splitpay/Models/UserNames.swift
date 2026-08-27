import Foundation

/// 「A」「B」2人のユーザー名（Web版の names ステートに相当）
struct UserNames: Equatable {
    var a: String = "A"
    var b: String = "B"

    /// Web版の `names[entry.user] || entry.user` に合わせ、"A"/"B"以外の値が来た場合は
    /// その生の文字列をそのまま返す(未知のユーザーキーでもクラッシュ・空表示させない)。
    subscript(user: String) -> String {
        switch user {
        case "A": return a
        case "B": return b
        default: return user
        }
    }

    init(a: String = "A", b: String = "B") {
        self.a = a
        self.b = b
    }

    init?(dict: [String: Any]) {
        guard let a = dict["A"] as? String, let b = dict["B"] as? String else { return nil }
        self.a = a
        self.b = b
    }

    var asDict: [String: Any] {
        ["A": a, "B": b]
    }
}
