import Foundation
import FirebaseFirestore

/// Web版 (splitpay.jsx) が使う `warikan/shared` からコピーした
/// `warikan/app` ドキュメントをリアルタイム購読・更新する。
/// 2026-08-28時点でWeb版と1回だけ内容をコピーし、以後はこのアプリ専用のデータとして分離管理する
/// (Web版の変更はこちらに反映されず、このアプリの変更もWeb版には反映されない)。
/// データ構造はWeb版に完全準拠:
///   warikan/app = { books: [...], entries: [...], names: {A,B}, memos: [...] }
@MainActor
final class FirestoreStore: ObservableObject {
    @Published var books: [Book] = [Book.defaultBook]
    @Published var entries: [Entry] = []
    @Published var names: UserNames = UserNames()
    @Published var memos: [Memo] = []
    @Published var isLoading = true
    @Published var lastSync: Date?

    private let docRef = Firestore.firestore().collection("warikan").document("app")
    private var listener: ListenerRegistration?

    func start() {
        guard listener == nil else { return }
        listener = docRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error {
                print("FirestoreStore: snapshotリスナーでエラーが発生しました: \(error.localizedDescription)")
            }
            if let data = snapshot?.data() {
                if let booksRaw = data["books"] as? [[String: Any]] {
                    let parsed = booksRaw.compactMap { Book(dict: $0) }
                    if !parsed.isEmpty { self.books = parsed }
                }
                if let entriesRaw = data["entries"] as? [[String: Any]] {
                    self.entries = entriesRaw.compactMap { Entry(dict: $0) }
                }
                if let namesRaw = data["names"] as? [String: Any], let parsed = UserNames(dict: namesRaw) {
                    self.names = parsed
                }
                if let memosRaw = data["memos"] as? [[String: Any]] {
                    self.memos = memosRaw.compactMap { Memo(dict: $0) }
                }
            }
            self.lastSync = Date()
            self.isLoading = false
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func refresh() {
        lastSync = Date()
    }

    // MARK: - Save (Web版 saveBooks/saveEntries/saveNames/saveMemos に対応)

    func saveBooks(_ newBooks: [Book]) {
        books = newBooks
        docRef.setData(["books": newBooks.map { $0.asDict }], merge: true)
    }

    func saveEntries(_ newEntries: [Entry]) {
        entries = newEntries
        docRef.setData(["entries": newEntries.map { $0.asDict }], merge: true)
    }

    func saveNames(_ newNames: UserNames) {
        names = newNames
        docRef.setData(["names": newNames.asDict], merge: true)
    }

    func saveMemos(_ newMemos: [Memo]) {
        memos = newMemos
        docRef.setData(["memos": newMemos.map { $0.asDict }], merge: true)
    }
}
