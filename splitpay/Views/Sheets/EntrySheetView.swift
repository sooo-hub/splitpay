import SwiftUI

/// 支払い/借りる/返済 いずれの記録も、この1つのドロワーで入力する(Web版と同様)。
struct EntrySheetView: View {
    let sheet: ActiveEntrySheet
    let bookId: String
    let names: UserNames
    let onSubmit: (Entry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var borrower = "A"
    @State private var amountText = ""
    @State private var memo = ""
    @State private var isSubmitting = false
    @AppStorage(EntryInputOrder.storageKey) private var inputOrderRaw = EntryInputOrder.amountFirst.rawValue

    private enum Field: Hashable {
        case amount, memo
    }
    @FocusState private var focusedField: Field?

    private var isMemoFirst: Bool {
        inputOrderRaw == EntryInputOrder.memoFirst.rawValue
    }

    /// キーボードの「＜ ＞」で辿る順序。表示順(記録の入力順設定)と一致させる
    private var fieldOrder: [Field] {
        isMemoFirst ? [.memo, .amount] : [.amount, .memo]
    }

    private func moveFocus(by offset: Int) {
        guard let current = focusedField, let idx = fieldOrder.firstIndex(of: current) else { return }
        let newIdx = idx + offset
        guard fieldOrder.indices.contains(newIdx) else { return }
        focusedField = fieldOrder[newIdx]
    }

    /// メモのEnter、または金額欄側の完了ボタンから呼ばれる。
    /// まだ次のフィールドが残っていればそちらへフォーカスを移し、
    /// 最後のフィールドなら入力を確定して記録する。
    private func handleReturnOrDone(from field: Field) {
        guard let idx = fieldOrder.firstIndex(of: field) else { return }
        if idx < fieldOrder.count - 1 {
            moveFocus(by: 1)
        } else {
            focusedField = nil
            submit()
        }
    }

    private var isEditing: Bool {
        if case .edit = sheet { return true }
        return false
    }

    /// sheetが表すEntry.Kind(+ payment時のuser)。色・アイコンのマッピングは
    /// すべてこの1組の値から導出し、新規作成(.payment/.borrow/.repay)と
    /// 編集(.edit)とで別々に定義しない。
    private var resolvedKind: (kind: Entry.Kind, user: String?) {
        switch sheet {
        case .payment(let user): return (.payment, user)
        case .borrow: return (.borrow, nil)
        case .repay: return (.repayment, nil)
        case .edit(let entry): return (entry.type, entry.user)
        }
    }

    private func accentColor(for kind: Entry.Kind, user: String?) -> Color {
        switch kind {
        case .payment: return Theme.userColor(user ?? "A")
        case .borrow: return Theme.colorBorrow
        case .repayment, .repay: return Theme.colorRepay
        case .reset: return Theme.textMuted
        }
    }

    private var color: Color {
        accentColor(for: resolvedKind.kind, user: resolvedKind.user)
    }

    private var title: String {
        switch sheet {
        case .payment(let user): return "\(names[user]) の支払いを記録"
        case .borrow: return "借りる記録"
        case .repay: return "返済を記録"
        case .edit: return "記録を編集"
        }
    }

    private var amountValue: Int? {
        Int(amountText)
    }

    /// 支払いはユーザーの頭文字アバター、それ以外は種別アイコンで、
    /// どの入力かをタイトル横で色付きバッジとして示す
    @ViewBuilder
    private var headerBadge: some View {
        let (kind, user) = resolvedKind
        switch kind {
        case .payment:
            UserAvatarView(name: names[user ?? "A"], color: color, size: 30, fontSize: 12, cornerRadius: 9)
        case .borrow:
            headerIconBadge(systemName: "yensign.circle.fill")
        case .repayment, .repay:
            headerIconBadge(systemName: "checkmark.circle.fill")
        case .reset:
            headerIconBadge(systemName: "arrow.clockwise")
        }
    }

    private func headerIconBadge(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(color, in: RoundedRectangle(cornerRadius: 9))
    }

    var body: some View {
        ScrollView {
            // フォーカスの有無でレイアウトを切り替えると要素の位置がガクッと動いて
            // 不自然になるため、常に上詰めの同じ配置で固定する
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    headerBadge
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(.bottom, 16)

                if case .borrow = sheet {
                    borrowerPicker
                        .padding(.bottom, 16)
                }

                if case .repay(let borrow) = sheet {
                    repayTargetCard(borrow)
                        .padding(.bottom, 16)
                }

                if isMemoFirst {
                    memoField
                        .padding(.bottom, 14)
                    amountField
                        .padding(.bottom, 22)
                } else {
                    amountField
                        .padding(.bottom, 14)
                    memoField
                        .padding(.bottom, 22)
                }

                submitButton
                    .padding(.bottom, 10)

                cancelButton
            }
            .padding(24)
        }
        .background(Color.white)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    moveFocus(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(focusedField == fieldOrder.first)

                Button {
                    moveFocus(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(focusedField == fieldOrder.last)

                Spacer()

                Button("完了") {
                    if let field = focusedField {
                        handleReturnOrDone(from: field)
                    }
                }
                .font(.system(size: 15, weight: .semibold))
            }
        }
        .onAppear {
            if case .repay(let borrow) = sheet {
                amountText = String(Int(borrow.remaining))
            }
            if case .edit(let entry) = sheet {
                if let amount = entry.amount {
                    amountText = String(Int(amount))
                }
                memo = entry.memo ?? ""
                borrower = entry.borrower ?? "A"
            }
            // 開いた瞬間からキーボードを表示し、すぐ入力できるようにする
            // (シートはフォーカスにより画面上部近くまで広がるが許容する)
            focusedField = fieldOrder.first
        }
    }

    private var borrowerPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("借りた人")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textMuted)
            HStack(spacing: 8) {
                ForEach(["A", "B"], id: \.self) { user in
                    let selected = borrower == user
                    Button {
                        borrower = user
                    } label: {
                        Text(names[user])
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(selected ? Theme.colorBorrow : Theme.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selected ? Theme.colorBorrow.opacity(0.08) : Color.white, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(selected ? Theme.colorBorrow : Theme.border, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func repayTargetCard(_ borrow: BorrowWithProgress) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("返済対象")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.colorBorrow)
            Text("\(names[borrow.borrower]) · 残り \(Formatting.yen(borrow.remaining))")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            if let memo = borrow.memo, !memo.isEmpty {
                Text(memo)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#FFF8F2"), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.colorBorrow.opacity(0.3), lineWidth: 1))
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("金額 *")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textMuted)
            HStack(spacing: 4) {
                Text("¥")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.textMuted)
                TextField("0", text: $amountText)
                    .keyboardType(.numberPad)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .focused($focusedField, equals: .amount)
                    .onChange(of: amountText) { _, newValue in
                        amountText = newValue.filter { $0.isNumber }
                    }
            }
            .padding(14)
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(color, lineWidth: 2))
        }
    }

    private var memoField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("メモ（任意）")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textMuted)
            TextField("例: スーパー、ガソリン代...", text: $memo)
                .font(.system(size: 16))
                .padding(12)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 1.5))
                .focused($focusedField, equals: .memo)
                .submitLabel(fieldOrder.last == .memo ? .done : .next)
                .onSubmit {
                    handleReturnOrDone(from: .memo)
                }
        }
    }

    private var submitButton: some View {
        let enabled = amountValue != nil && (amountValue ?? 0) > 0 && !isSubmitting
        return Button(action: submit) {
            Text(isSubmitting ? "記録中…" : (isEditing ? "更新する ✓" : "記録する ✓"))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(enabled ? color : Color(hex: "#E0DDD8"), in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: enabled ? color.opacity(0.3) : .clear, radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private var cancelButton: some View {
        Button {
            dismiss()
        } label: {
            Text("キャンセル")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func submit() {
        guard let n = amountValue, n > 0 else { return }
        isSubmitting = true
        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry: Entry
        switch sheet {
        case .payment(let user):
            entry = Entry(id: Formatting.generateId(), bookId: bookId, type: .payment, user: user,
                           amount: Double(n), memo: trimmedMemo, date: Formatting.nowISOString())
        case .borrow:
            entry = Entry(id: Formatting.generateId(), bookId: bookId, type: .borrow, borrower: borrower,
                           amount: Double(n), memo: trimmedMemo, date: Formatting.nowISOString())
        case .repay(let borrow):
            entry = Entry(id: Formatting.generateId(), bookId: bookId, type: .repayment, borrowId: borrow.id,
                           amount: Double(n), memo: trimmedMemo, date: Formatting.nowISOString())
        case .edit(let original):
            // id/日付/種別/当事者情報は元のまま、金額とメモだけを差し替える
            entry = Entry(id: original.id, bookId: original.bookId, type: original.type,
                           user: original.user, borrower: original.borrower, borrowId: original.borrowId,
                           amount: Double(n), memo: trimmedMemo, date: original.date, snapshot: original.snapshot)
        }
        onSubmit(entry)
        isSubmitting = false
    }
}
