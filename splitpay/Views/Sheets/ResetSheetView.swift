import SwiftUI

struct ResetSheetView: View {
    let mode: Book.Mode
    let names: UserNames
    let totA: Double
    let totB: Double
    let activeBorrowCount: Int
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var description: String {
        if mode == .debt {
            return "返済中 \(activeBorrowCount)件 の状況が履歴に残ります。"
        } else {
            return "リセット時点の状況（\(names.a) \(Formatting.yen(totA)) / \(names.b) \(Formatting.yen(totB))）が履歴に残ります。"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                Text("リセット")
            }
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(Theme.textPrimary)
            .padding(.bottom, 10)

            (
                Text("現在の状況をリセットします。\n")
                + Text("履歴は消えません。").fontWeight(.bold).foregroundColor(Theme.textPrimary)
                + Text("\n\(description)")
            )
            .font(.system(size: 14))
            .foregroundStyle(Theme.textSecondary)
            .lineSpacing(6)
            .padding(.bottom, 20)

            HStack(spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Text("キャンセル")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.background, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Button(action: onConfirm) {
                    Text("リセットする")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.colorA, in: RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Theme.colorA.opacity(0.3), radius: 10, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(Color.white)
    }
}
