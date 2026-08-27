import SwiftUI

struct HomeView: View {
    let mode: Book.Mode
    let names: UserNames
    let computed: BookComputedState
    let onOpenPayment: (String) -> Void
    let onOpenBorrow: () -> Void
    let onOpenRepay: (BorrowWithProgress) -> Void
    let onDelete: (Entry) -> Void
    let onShowReset: () -> Void
    let onShowAllHistory: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch mode {
            case .split:
                splitModeContent
            case .debt:
                debtModeContent
            }
        }
        .padding(16)
    }

    // MARK: - 差額モード

    private var splitModeContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            diffCard
                .padding(.bottom, 14)

            sectionLabel("支払いを追加")

            HStack(spacing: 10) {
                ForEach(["A", "B"], id: \.self) { user in
                    Button {
                        onOpenPayment(user)
                    } label: {
                        HStack(spacing: 8) {
                            Text("＋").font(.system(size: 22))
                            Text("\(names[user]) 持ち").font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Theme.userColor(user), in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Theme.userColor(user).opacity(0.3), radius: 10, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 24)

            if computed.allCur.isEmpty {
                emptyState(systemName: "note.text", title: "まだ記録がありません", subtitle: "上のボタンから追加してね")
            } else {
                sectionLabel("最近の履歴")
                ForEach(computed.allCur.prefix(4)) { entry in
                    EntryRowView(
                        entry: entry,
                        names: names,
                        isCompleted: computed.completedBorrowIds.contains(entry.id),
                        onDelete: { onDelete(entry) }
                    )
                    .padding(.bottom, 8)
                }
                if computed.allCur.count > 4 {
                    Button(action: onShowAllHistory) {
                        Text("全ての履歴を見る（\(computed.allCur.count) 件）")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "#DDDDDD"), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
        }
    }

    private var diffCard: some View {
        VStack(spacing: 10) {
            Text("現在の差額")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textMuted)

            if computed.diff == 0 {
                HStack(spacing: 8) {
                    Text("フラット！")
                    Image(systemName: "checkmark.seal.fill")
                }
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(Theme.colorRepay)
                Text("ふたりとも同じ金額です")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textFaint)
                    .padding(.top, 4)
            } else {
                let positive = computed.diff > 0
                let color = positive ? Theme.colorA : Theme.colorB
                let heavyName = positive ? names.a : names.b
                let lightName = positive ? names.b : names.a

                Text("\(heavyName) の方が多く持っています")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.1), in: Capsule())

                Text(Formatting.yen(computed.diff))
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(color)
                    .padding(.top, 6)

                (
                    Text("\(lightName) → \(heavyName) に\n")
                    + Text(Formatting.yen(abs(computed.diff) / 2)).fontWeight(.bold).foregroundColor(Theme.textSecondary)
                    + Text(" 渡すとフラットになります")
                )
                .font(.system(size: 12))
                .foregroundStyle(Theme.textFaint)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
            }

            Button(action: onShowReset) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                    Text("リセット")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.textMuted)
                .padding(.horizontal, 20)
                .padding(.vertical, 7)
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(hex: "#E0DDD8"), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 28)
        .padding(.bottom, 22)
        .padding(.horizontal, 24)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.06), radius: 20, y: 2)
    }

    // MARK: - 借りモード

    private var debtModeContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("返済中 \(computed.activeBorrows.count)件")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.textMuted)
                Spacer()
                Button(action: onOpenBorrow) {
                    HStack(spacing: 6) {
                        Image(systemName: "yensign.circle.fill").font(.system(size: 18))
                        Text("借りる").font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(Theme.colorBorrow, in: RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Theme.colorBorrow.opacity(0.25), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 12)

            if computed.activeBorrows.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 36)).foregroundStyle(Theme.colorRepay).padding(.bottom, 8)
                    Text("借りなし！")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.colorRepay)
                    Text("現在、借りている記録はありません")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textFaint)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 1)
            } else {
                ForEach(computed.activeBorrows) { borrow in
                    BorrowCardView(
                        borrow: borrow,
                        names: names,
                        onRepay: { onOpenRepay(borrow) },
                        onDelete: { onDelete(borrow.entry) }
                    )
                    .padding(.bottom, 10)
                }
            }
        }
    }

    // MARK: - shared

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Theme.textMuted)
            .padding(.leading, 4)
            .padding(.bottom, 8)
    }

    private func emptyState(systemName: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemName).font(.system(size: 36)).foregroundStyle(Theme.textFaint).padding(.bottom, 4)
            Text(title).font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
            Text(subtitle).font(.system(size: 12)).foregroundStyle(Theme.textFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 1)
    }
}
