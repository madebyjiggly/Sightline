import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case home, calendar, goals, cards
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home:     return "Home"
        case .calendar: return "Calendar"
        case .goals:    return "Goals"
        case .cards:    return "Cards"
        }
    }
    var icon: String {
        switch self {
        case .home:     return "house.fill"
        case .calendar: return "calendar"
        case .goals:    return "target"
        case .cards:    return "creditcard.fill"
        }
    }
}

/// A floating glass tab bar with a spring-sliding selection pill and bouncing icons.
struct FloatingTabBar: View {
    @Binding var selection: AppTab
    @Namespace private var pillNamespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                let selected = tab == selection
                Button {
                    guard !selected else { return }
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) { selection = tab }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 19, weight: .semibold))
                            .symbolEffect(.bounce, value: selected)
                        Text(tab.title)
                            .font(.system(size: 10.5, weight: selected ? .bold : .semibold))
                    }
                    .foregroundStyle(selected ? Theme.accentInk : Theme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background {
                        if selected {
                            Capsule()
                                .fill(Theme.accentSoft)
                                .matchedGeometryEffect(id: "selection-pill", in: pillNamespace)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Theme.line.opacity(0.75), lineWidth: 1))
        .cardShadow(1.4)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
        // Soft fade so scrolling content settles gently beneath the bar.
        .background(
            LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg.opacity(0.9)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
