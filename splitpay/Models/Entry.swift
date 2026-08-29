import Foundation

/// 履歴の1件を表す。Web版と同様、typeによってpayment/borrow/repayment/resetの
/// いずれかとして扱う（フィールドはtypeごとに使うものだけが入る）。
struct Entry: Identifiable, Equatable {
    enum Kind: String {
        case payment
        case borrow
        case repayment
        case repay // 旧スキーマ互換（Web版参照）
        case reset

        var isRepayment: Bool { self == .repayment || self == .repay }
    }

    var id: String
    var bookId: String
    var type: Kind
    var user: String?       // payment用: "A" | "B"
    var borrower: String?   // borrow用: "A" | "B"
    var borrowId: String?   // repayment用: 対象のborrow.id
    var amount: Double?     // payment/borrow/repaymentで使用
    var memo: String?
    var date: String        // ISO8601
    var snapshot: [String: Double]?  // reset用: {totA, totB} または {debt} など

    /// dateのパース結果。ソート等で繰り返し使われるため、毎回パースし直さず
    /// init時に一度だけ計算して保持する。
    let dateValue: Date

    init?(dict: [String: Any]) {
        guard let id = dict["id"] as? String,
              let bookId = dict["bookId"] as? String,
              let typeString = dict["type"] as? String,
              let date = dict["date"] as? String else { return nil }
        guard let kind = Kind(rawValue: typeString) else {
            print("Entry: 未知のtype '\(typeString)' (id: \(id)) を無視しました")
            return nil
        }
        self.id = id
        self.bookId = bookId
        self.type = kind
        self.date = date
        self.dateValue = Formatting.parseISODate(date) ?? .distantPast
        self.user = dict["user"] as? String
        self.borrower = dict["borrower"] as? String
        self.borrowId = dict["borrowId"] as? String
        self.memo = dict["memo"] as? String
        if let amount = dict["amount"] as? NSNumber {
            self.amount = amount.doubleValue
        } else {
            self.amount = nil
        }
        if let snap = dict["snapshot"] as? [String: Any] {
            var result: [String: Double] = [:]
            for (k, v) in snap {
                if let n = v as? NSNumber { result[k] = n.doubleValue }
            }
            self.snapshot = result
        } else {
            self.snapshot = nil
        }
    }

    init(id: String, bookId: String, type: Kind, user: String? = nil, borrower: String? = nil,
         borrowId: String? = nil, amount: Double? = nil, memo: String? = nil, date: String,
         snapshot: [String: Double]? = nil) {
        self.id = id
        self.bookId = bookId
        self.type = type
        self.user = user
        self.borrower = borrower
        self.borrowId = borrowId
        self.amount = amount
        self.memo = memo
        self.date = date
        self.dateValue = Formatting.parseISODate(date) ?? .distantPast
        self.snapshot = snapshot
    }

    var asDict: [String: Any] {
        var dict: [String: Any] = ["id": id, "bookId": bookId, "type": type.rawValue, "date": date]
        if let user { dict["user"] = user }
        if let borrower { dict["borrower"] = borrower }
        if let borrowId { dict["borrowId"] = borrowId }
        if let amount { dict["amount"] = amount }
        if let memo { dict["memo"] = memo }
        if let snapshot { dict["snapshot"] = snapshot }
        return dict
    }
}

/// 借りモードで、返済状況を計算した後のborrowエントリ
struct BorrowWithProgress: Identifiable, Equatable {
    var entry: Entry
    var repaid: Double
    var remaining: Double

    var id: String { entry.id }
    var borrower: String { entry.borrower ?? "" }
    var amount: Double { entry.amount ?? 0 }
    var memo: String? { entry.memo }
    var date: String { entry.date }
}
