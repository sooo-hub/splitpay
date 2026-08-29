import Foundation

/// Web版 (splitpay.jsx) の App() コンポーネント内で行っている派生計算(useMemo相当)を
/// そのままSwiftに移植したもの。
struct WarikanCalculator {
    /// 選択中のbookに紐づく履歴(新しい順)・差額・借り一覧などをまとめて計算する。
    static func compute(entries: [Entry], bookId: String) -> BookComputedState {
        // allCur: 対象bookの履歴を新しい順(date降順)に並べたもの
        let allCur = entries
            .filter { $0.bookId == bookId }
            .sorted { $0.dateValue > $1.dateValue }

        // allCurは新しい順なので、先頭から探して最初に見つかる reset が「直近のリセット」。
        // そのリセットより新しい(= indexが小さい)ものだけを「集計対象」とする。
        let activeEntries: [Entry]
        if let resetIndex = allCur.firstIndex(where: { $0.type == .reset }) {
            activeEntries = Array(allCur.prefix(resetIndex))
        } else {
            activeEntries = allCur
        }

        // 差額モード
        let totA = activeEntries
            .filter { $0.user == "A" && $0.type != .reset }
            .reduce(0) { $0 + ($1.amount ?? 0) }
        let totB = activeEntries
            .filter { $0.user == "B" && $0.type != .reset }
            .reduce(0) { $0 + ($1.amount ?? 0) }
        let diff = totA - totB

        // 借りモード
        // borrowId毎の返済合計を1回の走査で事前に集計しておくことで、
        // borrow件数 × entries件数のO(n*m)を避けてO(n)にする。
        func repaidByBorrowId(in pool: [Entry]) -> [String: Double] {
            pool.reduce(into: [String: Double]()) { dict, entry in
                guard entry.type.isRepayment, let borrowId = entry.borrowId else { return }
                dict[borrowId, default: 0] += entry.amount ?? 0
            }
        }

        func remaining(of borrow: Entry, repaidById: [String: Double]) -> BorrowWithProgress {
            let repaid = repaidById[borrow.id] ?? 0
            let amount = borrow.amount ?? 0
            return BorrowWithProgress(entry: borrow, repaid: repaid, remaining: amount - repaid)
        }

        let activeRepaidById = repaidByBorrowId(in: activeEntries)
        let borrowsInPeriod = activeEntries
            .filter { $0.type == .borrow }
            .map { remaining(of: $0, repaidById: activeRepaidById) }
        let activeBorrows = borrowsInPeriod.filter { $0.remaining > 0 }

        // completedBorrowIds は allCur 全体(リセットをまたいでも)で判定する。
        // 履歴タブでリセット前の完済も正しく「完済」表示するため。
        let allRepaidById = repaidByBorrowId(in: allCur)
        let completedBorrowIds = Set(
            allCur
                .filter { $0.type == .borrow }
                .map { remaining(of: $0, repaidById: allRepaidById) }
                .filter { $0.remaining <= 0 }
                .map { $0.id }
        )

        return BookComputedState(
            allCur: allCur,
            activeEntries: activeEntries,
            totA: totA,
            totB: totB,
            diff: diff,
            activeBorrows: activeBorrows,
            completedBorrowIds: completedBorrowIds
        )
    }
}

struct BookComputedState {
    var allCur: [Entry] = []
    var activeEntries: [Entry] = []
    var totA: Double = 0
    var totB: Double = 0
    var diff: Double = 0
    var activeBorrows: [BorrowWithProgress] = []
    var completedBorrowIds: Set<String> = []
}
