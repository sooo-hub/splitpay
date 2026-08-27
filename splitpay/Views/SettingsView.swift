import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: FirestoreStore
    @Binding var bookId: String

    @State private var isEditingNames = false
    @State private var editA = ""
    @State private var editB = ""

    @State private var newBookName = ""
    @State private var newBookMode: Book.Mode = .split

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("ユーザー名")
            namesCard
                .padding(.bottom, 16)

            sectionLabel("ページ一覧")
            ForEach(store.books) { book in
                bookRow(book)
                    .padding(.bottom, 8)
            }

            addBookCard
                .padding(.top, 8)
        }
        .padding(16)
    }

    // MARK: - Names

    private var namesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isEditingNames {
                nameEditRow(user: "A", text: $editA, placeholder: "例: たろう")
                nameEditRow(user: "B", text: $editB, placeholder: "例: はなこ")

                HStack(spacing: 8) {
                    Button {
                        isEditingNames = false
                    } label: {
                        Text("キャンセル")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.background, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)

                    Button(action: saveNames) {
                        Text("保存")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.textPrimary, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                nameDisplayRow(user: "A")
                nameDisplayRow(user: "B")

                Button {
                    editA = store.names.a
                    editB = store.names.b
                    isEditingNames = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                        Text("名前を編集")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "#444444"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.background, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 1)
    }

    private func nameDisplayRow(user: String) -> some View {
        HStack(spacing: 10) {
            userBadge(user)
            Text(store.names[user])
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
        }
    }

    private func nameEditRow(user: String, text: Binding<String>, placeholder: String) -> some View {
        HStack(spacing: 10) {
            userBadge(user)
            TextField(placeholder, text: text)
                .font(.system(size: 16))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.border, lineWidth: 1.5))
        }
    }

    private func userBadge(_ user: String) -> some View {
        Text(user)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(Theme.userColor(user), in: RoundedRectangle(cornerRadius: 8))
    }

    private func saveNames() {
        let a = editA.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = editB.trimmingCharacters(in: .whitespacesAndNewlines)
        store.saveNames(UserNames(a: a.isEmpty ? "A" : a, b: b.isEmpty ? "B" : b))
        isEditingNames = false
    }

    // MARK: - Books

    private func bookRow(_ book: Book) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(book.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(book.mode == .debt ? "借り" : "差額")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(book.mode == .debt ? Theme.colorBorrow : Theme.colorB)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(book.mode == .debt ? Theme.colorBorrow.opacity(0.1) : Color(hex: "#E8F4FF"), in: Capsule())
                }
                Text("\(store.entries.filter { $0.bookId == book.id }.count) 件の記録")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)
            }
            Spacer()
            Button {
                deleteBook(book)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 15))
                    .foregroundStyle(store.books.count <= 1 ? Color(hex: "#E0DDD8") : Theme.colorA)
                    .padding(8)
            }
            .buttonStyle(.plain)
            .disabled(store.books.count <= 1)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(bookId == book.id ? Theme.textPrimary : Color.clear)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 1.5))
        }
        .shadow(color: .black.opacity(0.05), radius: 6, y: 1)
    }

    private func deleteBook(_ book: Book) {
        guard store.books.count > 1 else { return }
        let remaining = store.books.filter { $0.id != book.id }
        store.saveBooks(remaining)
        store.saveEntries(store.entries.filter { $0.bookId != book.id })
        if bookId == book.id {
            bookId = remaining.first?.id ?? Book.defaultBook.id
        }
    }

    // MARK: - Add Book

    private var addBookCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("新しいページを追加")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textMuted)

            HStack(spacing: 8) {
                modeButton(.split, label: "差額", color: Theme.colorB, tintBg: Color(hex: "#E8F4FF"))
                modeButton(.debt, label: "借り", color: Theme.colorBorrow, tintBg: Theme.colorBorrow.opacity(0.08))
            }

            HStack(spacing: 8) {
                TextField("例: 旅行費、外食...", text: $newBookName)
                    .font(.system(size: 16))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Theme.background, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.border, lineWidth: 1.5))
                    .onSubmit(addBook)

                Button(action: addBook) {
                    Text("追加")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.textPrimary, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 1)
    }

    private func modeButton(_ mode: Book.Mode, label: String, color: Color, tintBg: Color) -> some View {
        let selected = newBookMode == mode
        return Button {
            newBookMode = mode
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(selected ? color : Theme.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selected ? tintBg : Color.white, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(selected ? color : Theme.border, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private func addBook() {
        let trimmed = newBookName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let book = Book(id: Formatting.generateId(), name: trimmed, mode: newBookMode)
        store.saveBooks(store.books + [book])
        newBookName = ""
        newBookMode = .split
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Theme.textMuted)
            .padding(.leading, 4)
            .padding(.bottom, 8)
    }
}
