import Foundation

struct Memo: Identifiable, Equatable {
    var id: String
    var text: String
    var date: String

    init(id: String, text: String, date: String) {
        self.id = id
        self.text = text
        self.date = date
    }

    init?(dict: [String: Any]) {
        guard let id = dict["id"] as? String,
              let text = dict["text"] as? String,
              let date = dict["date"] as? String else { return nil }
        self.id = id
        self.text = text
        self.date = date
    }

    var asDict: [String: Any] {
        ["id": id, "text": text, "date": date]
    }
}
