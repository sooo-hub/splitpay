import SwiftUI

struct DeleteConfirmSheetView: View {
    let entry: Entry
    let names: UserNames
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "trash.fill")
                Text("記録を削除")
            }
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(Theme.textPrimary)
            .padding(.bottom, 10)

            summaryCard
                .padding(.bottom, 20)

            Text("この記録を削除しますか？この操作は取り消せません。")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .padding(.bottom, 20)

            ConfirmationButtonsView(confirmLabel: "削除する", onCancel: { dismiss() }, onConfirm: onConfirm)
        }
        .padding(24)
        .background(Color.white)
    }

    @ViewBuilder
    private var summaryCard: some View {
        if entry.type == .reset {
            VStack(alignment: .leading, spacing: 4) {
                Text("リセット履歴")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "#C05000"))
                Text(Formatting.shortDate(entry.date))
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#C08060"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(hex: "#FFF8F0"), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "#FFE0C8"), lineWidth: 1))
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text(Formatting.yen(entry.amount ?? 0))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var subtitle: String {
        let dateStr = Formatting.shortDate(entry.date)
        let kindLabel: String
        switch entry.type {
        case .borrow:
            kindLabel = "\(entry.borrower.map { names[$0] } ?? "")が借りる"
        case .repayment, .repay:
            kindLabel = "返済"
        default:
            kindLabel = entry.user.map { names[$0] } ?? ""
        }
        let memoSuffix: String
        if let memo = entry.memo, !memo.isEmpty {
            memoSuffix = " · \(memo)"
        } else {
            memoSuffix = ""
        }
        return "\(dateStr) · \(kindLabel)\(memoSuffix)"
    }
}
