import SwiftUI

struct HistoryView: View {
    let entries: [Entry]
    let names: UserNames
    let completedBorrowIds: Set<String>
    let onDelete: (Entry) -> Void
    let onEdit: (Entry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if entries.isEmpty {
                Text("まだ記録がありません")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textFaint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 80)
            } else {
                Text("\(entries.count) 件の記録")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.leading, 4)
                    .padding(.bottom, 10)
                ForEach(entries) { entry in
                    EntryRowView(
                        entry: entry,
                        names: names,
                        isCompleted: completedBorrowIds.contains(entry.id),
                        onDelete: { onDelete(entry) },
                        onEdit: { onEdit(entry) }
                    )
                    .padding(.bottom, 8)
                }
            }
        }
        .padding(16)
    }
}
