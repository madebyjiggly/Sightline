import SwiftUI

/// Holds the user's appearance choice (System / Light / Dark), persisted.
@MainActor
final class ThemeManager: ObservableObject {
    enum Mode: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
        var label: String {
            switch self {
            case .system: return "System"
            case .light:  return "Light"
            case .dark:   return "Dark"
            }
        }
        var icon: String {
            switch self {
            case .system: return "iphone"
            case .light:  return "sun.max.fill"
            case .dark:   return "moon.fill"
            }
        }
        /// nil = follow the device setting.
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light:  return .light
            case .dark:   return .dark
            }
        }
    }

    @Published var mode: Mode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.key) }
    }

    private static let key = "theme.mode"

    init() {
        let saved = UserDefaults.standard.string(forKey: Self.key)
        mode = Mode(rawValue: saved ?? "") ?? .system
    }
}
