import SwiftUI
import UIKit

// MARK: - Haptics
enum Haptics {
    static func light()  { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func soft()   { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func select() { UISelectionFeedbackGenerator().selectionChanged() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}

// MARK: - Springy press feedback for buttons
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
}

// MARK: - Count-up animated currency
private struct CountUpModifier: AnimatableModifier {
    var value: Double
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    let format: (Double) -> String
    func body(content: Content) -> some View { Text(format(value)) }
}

/// A currency label that rolls up from 0 on appear and animates on change.
struct AnimatedAUD: View {
    let value: Double
    var decimals: Int = 0
    @State private var shown: Double = 0

    var body: some View {
        Text(verbatim: Money.aud(0, decimals: decimals))
            .modifier(CountUpModifier(value: shown) { Money.aud($0, decimals: decimals) })
            .onAppear { withAnimation(.easeOut(duration: 0.9)) { shown = value } }
            .onChange(of: value) { _, v in withAnimation(.easeOut(duration: 0.55)) { shown = v } }
    }
}

// MARK: - Lightweight confetti (no library)
struct ConfettiView: View {
    private struct Piece: Identifiable {
        let id = UUID()
        let x: CGFloat, size: CGFloat, delay: Double, dur: Double
        let rotStart: Double, rotEnd: Double, drift: CGFloat, color: Color
    }
    @State private var go = false
    private let pieces: [Piece]

    init() {
        let palette = [Theme.good, Theme.accent, Color(hex: "C07B00"),
                       Color(hex: "3E6BB0"), Color(hex: "C74B7A"), Color(hex: "8A5BC7")]
        pieces = (0..<46).map { _ in
            Piece(x: .random(in: 0.04...0.96), size: .random(in: 6...12),
                  delay: .random(in: 0...0.35), dur: .random(in: 1.4...2.4),
                  rotStart: .random(in: 0...180), rotEnd: .random(in: 360...900),
                  drift: .random(in: -0.10...0.10), color: palette.randomElement()!)
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { p in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(p.color)
                        .frame(width: p.size, height: p.size * 0.6)
                        .position(x: (p.x + (go ? p.drift : 0)) * geo.size.width,
                                  y: go ? geo.size.height + 40 : -40)
                        .rotationEffect(.degrees(go ? p.rotEnd : p.rotStart))
                        .opacity(go ? 0 : 1)
                        .animation(.easeIn(duration: p.dur).delay(p.delay), value: go)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { go = true }
    }
}
