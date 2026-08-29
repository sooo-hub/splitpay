import SwiftUI

enum AppTab: String, CaseIterable {
    case home
    case history
    case memo
    case books

    /// SF Symbol名。絵文字だとフォントによってはtofu(「？」)表示になるため、
    /// システムフォントに組み込まれているSF Symbolsを使用する。
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .history: return "list.bullet.clipboard.fill"
        case .memo: return "note.text"
        case .books: return "gearshape.fill"
        }
    }

    var label: String {
        switch self {
        case .home: return "ホーム"
        case .history: return "履歴"
        case .memo: return "メモ"
        case .books: return "設定"
        }
    }
}

/// 金額入力ドロワー(支払い/借りる/返済/既存記録の編集)の対象
enum ActiveEntrySheet: Identifiable, Equatable {
    case payment(user: String)
    case borrow
    case repay(BorrowWithProgress)
    case edit(Entry)

    var id: String {
        switch self {
        case .payment(let user): return "payment-\(user)"
        case .borrow: return "borrow"
        case .repay(let b): return "repay-\(b.id)"
        case .edit(let entry): return "edit-\(entry.id)"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var store: FirestoreStore
    @EnvironmentObject private var authService: AuthService

    @State private var bookId: String = Book.defaultBook.id
    @State private var tab: AppTab = .home
    @State private var activeSheet: ActiveEntrySheet?
    @State private var showReset = false
    @State private var deleteTarget: Entry?

    private var computed: BookComputedState {
        WarikanCalculator.compute(entries: store.entries, bookId: bookId)
    }

    private var currentBook: Book? {
        store.books.first { $0.id == bookId }
    }

    private var curMode: Book.Mode {
        currentBook?.mode ?? .split
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if store.isLoading {
                ProgressView("読み込み中…")
                    .tint(Theme.textMuted)
                    .foregroundStyle(Theme.textMuted)
            } else {
                VStack(spacing: 0) {
                    HeaderView(
                        books: store.books,
                        selectedBookId: $bookId,
                        lastSync: store.lastSync,
                        onRefresh: { store.refresh() }
                    )

                    ScrollView {
                        content
                            .padding(.bottom, 90)
                    }
                }

                VStack {
                    Spacer()
                    BottomNavView(selectedTab: $tab)
                }
                .ignoresSafeArea(.keyboard)
            }
        }
        .onAppear(perform: syncBookIdIfNeeded)
        .onChange(of: store.books) { _, _ in syncBookIdIfNeeded() }
        .sheet(item: $activeSheet) { sheet in
            EntrySheetView(
                sheet: sheet,
                bookId: bookId,
                names: store.names,
                onSubmit: { entry in
                    if store.entries.contains(where: { $0.id == entry.id }) {
                        // 既存記録の編集: 元の位置のまま内容を差し替える
                        store.saveEntries(store.entries.map { $0.id == entry.id ? entry : $0 })
                    } else {
                        store.saveEntries([entry] + store.entries)
                    }
                    activeSheet = nil
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showReset) {
            ResetSheetView(
                mode: curMode,
                names: store.names,
                totA: computed.totA,
                totB: computed.totB,
                activeBorrowCount: computed.activeBorrows.count,
                onConfirm: performReset
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
        }
        .sheet(item: $deleteTarget) { entry in
            DeleteConfirmSheetView(
                entry: entry,
                names: store.names,
                onConfirm: {
                    store.saveEntries(store.entries.filter { $0.id != entry.id })
                    deleteTarget = nil
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .home:
            HomeView(
                mode: curMode,
                names: store.names,
                computed: computed,
                onOpenPayment: { user in activeSheet = .payment(user: user) },
                onOpenBorrow: { activeSheet = .borrow },
                onOpenRepay: { borrow in activeSheet = .repay(borrow) },
                onDelete: { entry in deleteTarget = entry },
                onEdit: { entry in activeSheet = .edit(entry) },
                onShowReset: { showReset = true },
                onShowAllHistory: { tab = .history }
            )
        case .history:
            HistoryView(
                entries: computed.allCur,
                names: store.names,
                completedBorrowIds: computed.completedBorrowIds,
                onDelete: { entry in deleteTarget = entry },
                onEdit: { entry in activeSheet = .edit(entry) }
            )
        case .memo:
            MemoView(store: store)
        case .books:
            SettingsView(store: store, bookId: $bookId)
        }
    }

    private func syncBookIdIfNeeded() {
        guard !store.books.isEmpty else { return }
        if !store.books.contains(where: { $0.id == bookId }) {
            bookId = store.books.first?.id ?? Book.defaultBook.id
        }
    }

    private func performReset() {
        let snapshot: [String: Double]
        if curMode == .debt {
            snapshot = ["activeBorrows": Double(computed.activeBorrows.count)]
        } else {
            snapshot = ["totA": computed.totA, "totB": computed.totB]
        }
        let resetEntry = Entry(
            id: Formatting.generateId(),
            bookId: bookId,
            type: .reset,
            date: Formatting.nowISOString(),
            snapshot: snapshot
        )
        store.saveEntries([resetEntry] + store.entries)
        showReset = false
    }
}

#Preview {
    ContentView()
        .environmentObject(FirestoreStore())
        .environmentObject(AuthService())
}
