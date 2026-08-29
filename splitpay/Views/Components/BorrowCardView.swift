import SwiftUI

/// 借りモードのアクティブな借りを表示するカード。Web版のBorrowCardに対応。
struct BorrowCardView: View {
    let borrow: BorrowWithProgress
    let names: UserNames
    let onRepay: () -> Void
    let onDelete: () -> Void

    private var progressPercent: Double {
        guard borrow.amount > 0 else { return 0 }
        return min(1, borrow.repaid / borrow.amount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        UserAvatarView(name: names[borrow.borrower], color: Theme.colorBorrow, size: 26, fontSize: 12, cornerRadius: 7)
                        Text("\(names[borrow.borrower]) が借りた")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    if let memo = borrow.memo, !memo.isEmpty {
                        Text(memo)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textMuted)
                            .padding(.leading, 34)
                    }
                }
                Spacer(minLength: 0)
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "#DDDDDD"))
                        .padding(4)
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("残り")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textMuted)
                    Text(Formatting.yen(borrow.remaining))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Theme.colorBorrow)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("元金 / 返済済み")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textMuted)
                    Text("\(Formatting.yen(borrow.amount)) / \(Formatting.yen(borrow.repaid))")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            if borrow.repaid > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8).fill(Theme.background)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.colorRepay)
                            .frame(width: geo.size.width * progressPercent)
                    }
                }
                .frame(height: 6)
            }

            Button(action: onRepay) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("返した")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Theme.colorRepay, in: RoundedRectangle(cornerRadius: 12))
                .shadow(color: Theme.colorRepay.opacity(0.25), radius: 8, y: 3)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .cardStyle(cornerRadius: 16, shadowOpacity: 0.07, shadowRadius: 12, shadowY: 2)
    }
}
