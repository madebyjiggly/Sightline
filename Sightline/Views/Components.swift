import SwiftUI

// MARK: - Card container
struct CardBox<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.line, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 8)
    }
}

// MARK: - Section header
struct SectionHeader: View {
    let title: String
    var link: String? = nil
    var onLink: (() -> Void)? = nil
    var body: some View {
        HStack {
            Text(title).font(Theme.display(17)).foregroundStyle(Theme.ink)
            Spacer()
            if let link {
                Button(action: { onLink?() }) {
                    Text(link).font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.accentInk)
                }
            }
        }
        .padding(.horizontal, 2)
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

// MARK: - Progress bar
struct ProgressBar: View {
    let fraction: Double
    let color: Color
    var height: CGFloat = 8
    var milestones: [Double] = []   // fractions (0–1) to mark with a notch
    @State private var shown: Double = 0
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surface3)
                Capsule().fill(color)
                    .frame(width: max(height, geo.size.width * shown))
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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.line, lineWidth: 1))
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
                Text(title).font(Theme.display(26, .heavy)).foregroundStyle(Theme.ink)
                    .padding(.top, 4)
                content
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.bg)
    }
}
