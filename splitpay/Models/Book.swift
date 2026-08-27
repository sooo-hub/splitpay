import Foundation

/// 「ページ」= 割り勘の集計単位（差額モード / 借りモード）
struct Book: Identifiable, Equatable {
    enum Mode: String {
        case split
        case debt
    }

    var id: String
    var name: String
    var mode: Mode

    init(id: String, name: String, mode: Mode) {
        self.id = id
        self.name = name
        self.mode = mode
    }

    init?(dict: [String: Any]) {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String else { return nil }
        let modeString = dict["mode"] as? String ?? "split"
        self.id = id
        self.name = name
        self.mode = Mode(rawValue: modeString) ?? .split
    }

    var asDict: [String: Any] {
        ["id": id, "name": name, "mode": mode.rawValue]
    }

    static let defaultBook = Book(id: "b1", name: "日常費", mode: .split)
}
