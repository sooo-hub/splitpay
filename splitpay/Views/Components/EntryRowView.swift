import SwiftUI

/// 履歴の1行(ホーム最近の履歴/履歴タブ共通)。Web版のEntryRowに対応。
struct EntryRowView: View {
    let entry: Entry
    let names: UserNames
    let isCompleted: Bool
    let onDelete: () -> Void

    var body: some View {
        switch entry.type {
        case .reset:
            resetRow
        case .borrow:
            borrowRow
        case .repayment, .repay:
            repaymentRow
        case .payment:
            paymentRow
        }
    }

    // MARK: - reset

    /// Web版 (splitpay.jsx) は保存時に `snapshot.activeBorrows` を書き込む一方、
    /// 表示時には `snapshot.debt` を見ておりキーが一致せず常に¥0/¥0表示になるバグがある。
    /// このバグは踏襲せず、実際に保存されているキー `activeBorrows` で正しく判定する。
    private var isDebtReset: Bool {
        entry.snapshot?["activeBorrows"] != nil
    }

    private var resetRow: some View {
        HStack(spacing: 10) {
            iconBox(systemName: "arrow.clockwise", background: Color(hex: "#FF9A6C"))
            VStack(alignment: .leading, spacing: 1) {
                Text("リセット")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "#C05000"))
                Text(resetSubtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "#C08060"))
            }
            Spacer(minLength: 0)
            deleteButton(color: Color(hex: "#E0C0A0"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(hex: "#FFF8F0"))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#FFE0C8"), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var resetSubtitle: String {
        let dateStr = Formatting.shortDate(entry.date)
        if isDebtReset {
            let count = Int(entry.snapshot?["activeBorrows"] ?? 0)
            return "\(dateStr) · 返済中 \(count)件"
        } else {
            let totA = entry.snapshot?["totA"] ?? 0
            let totB = entry.snapshot?["totB"] ?? 0
            return "\(dateStr) · \(names.a) \(Formatting.yen(totA)) / \(names.b) \(Formatting.yen(totB))"
        }
    }

    // MARK: - borrow

    private var borrowRow: some View {
        HStack(spacing: 10) {
            iconBox(systemName: "yensign.circle.fill", background: isCompleted ? Color(hex: "#AAAAAA") : Theme.colorBorrow)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(Formatting.yen(entry.amount ?? 0))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    if isCompleted {
                        Text("完済")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.colorRepay)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Theme.colorRepay.opacity(0.1), in: Capsule())
                    }
                }
                Text(borrowSubtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
            deleteButton(color: Color(hex: "#CCCCCC"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 1)
    }

    private var borrowSubtitle: String {
        let borrowerName = entry.borrower.map { names[$0] } ?? ""
        return "\(Formatting.shortDate(entry.date)) · \(borrowerName)が借りる\(memoSuffix(entry))"
    }

    // MARK: - repayment

    private var repaymentRow: some View {
        HStack(spacing: 10) {
            iconBox(systemName: "checkmark.circle.fill", background: Theme.colorRepay)
            VStack(alignment: .leading, spacing: 1) {
                Text(Formatting.yen(entry.amount ?? 0))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(Formatting.shortDate(entry.date)) · 返済\(memoSuffix(entry))")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
            deleteButton(color: Color(hex: "#CCCCCC"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 1)
    }

    // MARK: - payment

    private var paymentRow: some View {
        let user = entry.user ?? "A"
        let color = Theme.userColor(user)
        let initial = names[user].uppercased().first.map(String.init) ?? "?"
        return HStack(spacing: 10) {
            Text(initial)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color, in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 1) {
                Text(Formatting.yen(entry.amount ?? 0))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(Formatting.shortDate(entry.date)) · \(names[user])\(memoSuffix(entry))")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
            deleteButton(color: Color(hex: "#CCCCCC"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 1)
    }

    // MARK: - shared pieces

    private func iconBox(systemName: String, background: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(background, in: RoundedRectangle(cornerRadius: 8))
    }

    /// 強制アンラップ(`entry.memo!`)を避け、BorrowCardViewと同様に
    /// `if let memo, !memo.isEmpty` パターンでmemoが有効な場合のみ" · memo"を返す。
    private func memoSuffix(_ entry: Entry) -> String {
        if let memo = entry.memo, !memo.isEmpty {
            return " · \(memo)"
        }
        return ""
    }

    private func deleteButton(color: Color) -> some View {
        Button(action: onDelete) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
                .padding(6)
        }
        .buttonStyle(.plain)
    }
}
