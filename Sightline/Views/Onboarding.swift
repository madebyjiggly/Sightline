import SwiftUI

/// First-launch flow: a branded intro page, then a sign-in page.
/// Shown until the user signs in or chooses to explore with sample data;
/// after that `hasOnboarded` keeps it out of the way forever.
struct OnboardingFlow: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var step: Step = .intro
    enum Step { case intro, login }

    var body: some View {
        ZStack {
            switch step {
            case .intro:
                IntroPage {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { step = .login }
                }
                .transition(.asymmetric(insertion: .identity, removal: .move(edge: .leading).combined(with: .opacity)))
            case .login:
                LoginPage(onBack: {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { step = .intro }
                }, onFinished: finish)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }

    private func finish() {
        withAnimation(.easeInOut(duration: 0.35)) { hasOnboarded = true }
    }
}

// MARK: - Page 1: intro

private struct IntroPage: View {
    var onGetStarted: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Theme.heroGradient.ignoresSafeArea()
            // The hero card's decorative light, scaled up to a full screen.
            RadialGradient(colors: [Theme.heroAccent.opacity(0.30), .clear],
                           center: .init(x: 0.15, y: 0.12), startRadius: 0, endRadius: 420)
                .ignoresSafeArea()
            Circle().fill(.white.opacity(0.06)).frame(width: 380, height: 380)
                .offset(x: 150, y: -330)

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                Text("S")
                    .font(Theme.display(34, .heavy)).foregroundStyle(Theme.heroTop)
                    .frame(width: 64, height: 64)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 14, y: 8)
                    .padding(.bottom, 22)

                Text("Sightline")
                    .font(Theme.display(40, .heavy)).tracking(-0.8).foregroundStyle(.white)
                Text("See your money clearly.")
                    .font(.system(size: 17, weight: .medium)).foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 18) {
                    feature("chart.pie.fill", "Budgets that keep score",
                            "Set a monthly budget per category and watch spending update against it.")
                    feature("target", "Goals with a plan",
                            "Save for what matters with milestones, streaks and a little confetti.")
                    feature("building.columns.fill", "Bank-ready",
                            "Explore with sample data now — securely connect your bank when you're ready.")
                }
                .padding(.top, 36)

                Spacer()
                Spacer()

                Button(action: onGetStarted) {
                    Text("Get started")
                        .font(.system(size: 17, weight: .bold)).foregroundStyle(Theme.heroTop)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.pressable)
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
        }
        .onAppear { withAnimation(.easeOut(duration: 0.5)) { appeared = true } }
    }

    private func feature(_ icon: String, _ title: String, _ line: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.white.opacity(0.2), lineWidth: 1))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 15.5, weight: .bold)).foregroundStyle(.white)
                Text(line).font(.system(size: 13)).foregroundStyle(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Page 2: login

private struct LoginPage: View {
    var onBack: () -> Void
    var onFinished: () -> Void

    var body: some View {
        AuthContent(onFinished: onFinished)
            .safeAreaInset(edge: .top) {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.accentInk)
                            .frame(width: 36, height: 36)
                            .background(Theme.surface2, in: Circle())
                            .overlay(Circle().stroke(Theme.line, lineWidth: 1))
                    }
                    .accessibilityLabel("Back")
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.top, 4)
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: onFinished) {
                    Text("Skip for now — explore with sample data")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.accentInk)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                }
                .background(AppBackground().opacity(0.9))
            }
    }
}
