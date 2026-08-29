import SwiftUI

/// ユーザー名の頭文字を色付き丸背景に乗せたアバター。
/// EntryRowView(支払い行)・BorrowCardViewで共通使用する。
struct UserAvatarView: View {
    let name: String
    let color: Color
    var size: CGFloat = 28
    var fontSize: CGFloat = 11
    var cornerRadius: CGFloat = 8

    var body: some View {
        Text(name.uppercased().first.map(String.init) ?? "?")
            .font(.system(size: fontSize, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}
