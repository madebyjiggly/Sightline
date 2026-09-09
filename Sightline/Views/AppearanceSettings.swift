import SwiftUI

/// Appearance page. Pushed inside the Settings hub, or wrapped by
/// `AppearanceSheet` when presented on its own.
struct AppearanceContent: View {
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        Screen(title: "Appearance") {
            CardBox {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Theme").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.ink)
                    HStack(spacing: 10) {
                        ForEach(ThemeManager.Mode.allCases) { mode in
                            Button {
                                Haptics.select()
                                withAnimation(.easeInOut(duration: 0.2)) { theme.mode = mode }
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: mode.icon).font(.system(size: 20))
                                    Text(mode.label).font(.system(size: 13, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(theme.mode == mode ? Theme.accentSoft : Theme.surface2,
                                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(theme.mode == mode ? Theme.accent : Theme.line,
                                            lineWidth: theme.mode == mode ? 2 : 1))
                                .foregroundStyle(theme.mode == mode ? Theme.accentInk : Theme.muted)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Text("“System” follows your iPhone's light/dark setting automatically.")
                        .font(.system(size: 12)).foregroundStyle(Theme.faint)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppearanceSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            AppearanceContent()
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
