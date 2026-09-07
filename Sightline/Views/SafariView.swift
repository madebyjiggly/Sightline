import SwiftUI
import SafariServices

/// Presents a URL in an in-app Safari view — used for the Basiq Connect consent
/// flow so the user logs into their bank on the bank's own secure page.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.barCollapsingEnabled = false
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredControlTintColor = UIColor(Theme.accent)
        return vc
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

/// A URL that can drive a SwiftUI `.sheet(item:)`.
struct IdentifiedURL: Identifiable {
    let id = UUID()
    let url: URL
}
