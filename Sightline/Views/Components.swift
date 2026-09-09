import SwiftUI

// MARK: - App background (soft gradient wash instead of a flat fill)
struct AppBackground: View {
    var body: some View {
        ZStack {
            Theme.bg
            RadialGradient(colors: [Theme.accent.opacity(0.12), .clear],
                           center: .init(x: 0.15, y: 0.05), startRadius: 0, endRadius: 420)
            RadialGradient(colors: [Theme.heroAccent.opacity(0.06), .clear],
                           center: .init(x: 0.95, y: 0.35), startRadius: 0, endRadius: 360)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Layered card shadow (tight contact + diffuse ambient)
struct CardShadow: ViewModifier {
    var strength: CGFloat = 1
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.05 * strength), radius: 2, x: 0, y: 1)
            .shadow(color: .black.opacity(0.08 * strength), radius: 22, x: 0, y: 12)
    }
}
extension View {
    func cardShadow(_ strength: CGFloat = 1) -> some View { modifier(CardShadow(strength: strength)) }
}

// MARK: - Card container
struct CardBox<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(Theme.line.opacity(0.7), lineWidth: 1))
            .cardShadow()
    }
}

// MARK: - Section header
struct SectionHeader: View {
    let title: String
    var link: String? = nil
    var onLink: (() -> Void)? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(Theme.display(18, .heavy)).tracking(-0.2).foregroundStyle(Theme.ink)
            Spacer()
            if let link {
                Button(action: { onLink?() }) {
                    Text(link).font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.accentInk)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Theme.accentSoft.opacity(0.7), in: Capsule())
                }
                .buttonStyle(.pressable)
            }
        }
        .padding(.horizontal, 2)
        .padding(.top, 4)
    }
}

// MARK: - Status pill
struct StatusPill: View {
    let status: BudgetStatus
    var body: some View {
        Text(status.pill)
            .font(.system(size: 11, weight: .bold))
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(status.kind.soft, in: Capsule())
            .foregroundStyle(status.kind.color)
    }
}

// MARK: - Progress bar (gradient fill, optional milestone notches)
struct ProgressBar: View {
    let fraction: Double
    let color: Color
    var height: CGFloat = 9
    var milestones: [Double] = []   // fractions (0–1) to mark with a notch
    @State private var shown: Double = 0
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surface3)
                Capsule()
                    .fill(LinearGradient(colors: [color.opacity(0.78), color],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(height, geo.size.width * shown))
                    .overlay(
                        Capsule().fill(LinearGradient(colors: [.white.opacity(0.28), .clear],
                                                      startPoint: .top, endPoint: .bottom))
                            .frame(width: max(height, geo.size.width * shown), height: height / 2)
                            .offset(y: -height / 4),
                        alignment: .leading
                    )
                ForEach(milestones, id: \.self) { m in
                    Capsule().fill(Theme.surface)
                        .frame(width: 2, height: max(2, height - 3))
                        .position(x: geo.size.width * m, y: height / 2)
                }
            }
        }
        .frame(height: height)
        .onAppear { withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) { shown = fraction } }
        .onChange(of: fraction) { _, f in
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) { shown = f }
        }
    }
}

// MARK: - Small stat tile
struct StatTile: View {
    let label: String
    let value: String
    var valueColor: Color = Theme.ink
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.system(size: 10.5, weight: .semibold)).foregroundStyle(Theme.muted)
            Text(value).font(Theme.mono(17)).foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.line.opacity(0.7), lineWidth: 1))
        .cardShadow(0.6)
    }
}

// MARK: - Status banner
struct StatusBanner: View {
    let emoji: String
    let title: String
    let detail: String
    let kind: StatusKind
    var body: some View {
        HStack(spacing: 12) {
            Text(emoji).font(.system(size: 22))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .bold)).foregroundStyle(kind.color)
                Text(detail).font(.system(size: 12)).foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(kind.soft)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Screen scaffold (title + scrolling content on the app background)
struct Screen<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(title).font(Theme.display(28, .heavy)).tracking(-0.4).foregroundStyle(Theme.ink)
                    .padding(.top, 4)
                content
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(AppBackground())
    }
}
