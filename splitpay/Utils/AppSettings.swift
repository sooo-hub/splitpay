import Foundation

/// 支払い記録ドロワーで金額とメモ、どちらの入力欄を先に表示するかの設定。
/// @AppStorage(UserDefaults)に保存するため、Firestoreとは違い端末ごとに独立して保持される。
enum EntryInputOrder: String, CaseIterable {
    case amountFirst
    case memoFirst

    static let storageKey = "entryInputOrder"

    var label: String {
        switch self {
        case .amountFirst: return "金額が先"
        case .memoFirst: return "メモが先"
        }
    }
}
