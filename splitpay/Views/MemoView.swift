import SwiftUI

struct MemoView: View {
    @ObservedObject var store: FirestoreStore

    @State private var newMemoText = ""
    @State private var editingMemo: Memo?
    @State private var editText = ""
    @State private var isSubmitting = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            inputCard
                .padding(.bottom, 16)

            if store.memos.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "note.text").font(.system(size: 36)).foregroundStyle(Theme.textFaint).padding(.bottom, 4)
                    Text("まだメモがありません")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textFaint)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                ForEach(store.memos) { memo in
                    memoCard(memo)
                        .padding(.bottom, 10)
                }
            }
        }
        .padding(16)
    }

    private var inputCard: some View {
        VStack(spacing: 10) {
            TextEditor(text: $newMemoText)
                .focused($isInputFocused)
                .font(.system(size: 15))
                .frame(minHeight: 70)
                .padding(8)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 1.5))
                .scrollContentBackground(.hidden)
                .overlay(alignment: .topLeading) {
                    if newMemoText.isEmpty {
                        Text("メモを入力…")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.textFaint)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }

            Button(action: addMemo) {
                Text(isSubmitting ? "保存中…" : "＋ 追加")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        newMemoText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color(hex: "#E0DDD8") : Theme.textPrimary,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
            }
            .buttonStyle(.plain)
            .disabled(newMemoText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 1)
    }

    private func memoCard(_ memo: Memo) -> some View {
        Group {
            if editingMemo?.id == memo.id {
                VStack(spacing: 10) {
                    TextEditor(text: $editText)
                        .font(.system(size: 15))
                        .frame(minHeight: 70)
                        .padding(8)
                        .background(Theme.background, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.textPrimary, lineWidth: 1.5))
                        .scrollContentBackground(.hidden)

                    HStack(spacing: 8) {
                        Button {
                            editingMemo = nil
                        } label: {
                            Text("キャンセル")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Theme.background, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)

                        Button(action: saveEditedMemo) {
                            Text("保存")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Theme.textPrimary, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.05), radius: 6, y: 1)
            } else {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(memo.text)
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.textPrimary)
                        Text(Formatting.shortDate(memo.date))
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textFaint)
                    }
                    Spacer(minLength: 0)
                    VStack(spacing: 4) {
                        Button {
                            editingMemo = memo
                            editText = memo.text
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "#CCCCCC"))
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                        Button {
                            deleteMemo(memo)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "#CCCCCC"))
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.05), radius: 6, y: 1)
            }
        }
    }

    private func addMemo() {
        let trimmed = newMemoText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSubmitting = true
        let memo = Memo(id: Formatting.generateId(), text: trimmed, date: Formatting.nowISOString())
        store.saveMemos([memo] + store.memos)
        newMemoText = ""
        isSubmitting = false
    }

    private func saveEditedMemo() {
        guard let editingMemo, !editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let updated = store.memos.map { m -> Memo in
            guard m.id == editingMemo.id else { return m }
            var copy = m
            copy.text = editText.trimmingCharacters(in: .whitespacesAndNewlines)
            return copy
        }
        store.saveMemos(updated)
        self.editingMemo = nil
    }

    private func deleteMemo(_ memo: Memo) {
        store.saveMemos(store.memos.filter { $0.id != memo.id })
    }
}
