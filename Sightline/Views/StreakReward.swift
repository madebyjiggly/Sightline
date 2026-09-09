import SwiftUI

/// Celebratory popup shown when the daily streak earns a badge.
struct StreakRewardPopup: View {
    let milestone: StreakMilestone
    let streakDays: Int
    let onDismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.38).ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 12) {
                Text(milestone.emoji)
                    .font(.system(size: 68))
                    .scaleEffect(appeared ? 1 : 0.4)
                    .rotationEffect(.degrees(appeared ? 0 : -20))
                Text("Badge earned!")
                    .font(.system(size: 12, weight: .bold)).tracking(1.2)
                    .foregroundStyle(Theme.accentInk).textCase(.uppercase)
                Text(milestone.title)
                    .font(Theme.display(24, .heavy)).foregroundStyle(Theme.ink)
                Text("\(streakDays)-day streak 🔥 — keep showing up.")
                    .font(.system(size: 13.5)).foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                Button {
                    Haptics.light()
                    onDismiss()
                } label: {
                    Text("Nice!").frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(.white).font(.system(size: 15, weight: .bold))
                }
                .buttonStyle(.pressable)
                .padding(.top, 6)
            }
            .padding(26)
            .frame(maxWidth: 320)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 30, y: 12)
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { onDismiss() }
        }
    }
}
