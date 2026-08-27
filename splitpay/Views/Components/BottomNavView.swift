import SwiftUI

struct BottomNavView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { t in
                Button {
                    selectedTab = t
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: t.icon)
                            .font(.system(size: 20))
                            .opacity(selectedTab == t ? 1 : 0.35)
                        Text(t.label)
                            .font(.system(size: 10, weight: selectedTab == t ? .bold : .regular))
                            .foregroundStyle(selectedTab == t ? Theme.textPrimary : Theme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
                }
            }
        }
        .background(
            Color.white
                .overlay(alignment: .top) {
                    Rectangle().fill(Theme.border).frame(height: 1)
                }
        )
    }
}
