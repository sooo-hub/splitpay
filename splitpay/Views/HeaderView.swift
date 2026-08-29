import SwiftUI

struct HeaderView: View {
    let books: [Book]
    @Binding var selectedBookId: String
    let lastSync: Date?
    let onRefresh: () -> Void

    private var syncLabel: String {
        guard let lastSync else { return "更新" }
        return Formatting.time(lastSync)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("かんたん家計簿")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button(action: onRefresh) {
                    Text("↻ \(syncLabel)")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.background, in: RoundedRectangle(cornerRadius: 8))
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(books) { book in
                        Button {
                            selectedBookId = book.id
                        } label: {
                            Text(book.name)
                                .font(.system(size: 13, weight: selectedBookId == book.id ? .bold : .regular))
                                .foregroundStyle(selectedBookId == book.id ? Theme.textPrimary : Theme.textMuted)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    selectedBookId == book.id ? Theme.background : Color.clear,
                                    in: UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 8)
                                )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .background(
            Color.white
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Theme.border).frame(height: 1)
                }
        )
    }
}
