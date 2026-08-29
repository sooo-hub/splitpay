import SwiftUI

/// 「キャンセル / 確定」の横並びボタン。ResetSheetView・DeleteConfirmSheetViewで共通使用する。
struct ConfirmationButtonsView: View {
    let confirmLabel: String
    var confirmColor: Color = Theme.colorA
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onCancel) {
                Text("キャンセル")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.background, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Button(action: onConfirm) {
                Text(confirmLabel)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(confirmColor, in: RoundedRectangle(cornerRadius: 14))
                    .shadow(color: confirmColor.opacity(0.3), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
        }
    }
}
