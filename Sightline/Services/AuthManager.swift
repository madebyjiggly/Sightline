import SwiftUI

/// Holds the signed-in session. The token lives in the Keychain; the email is
/// a convenience shown in the UI. All calls go through the Sightline proxy.
@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var email: String?
    @Published private(set) var isAuthenticated: Bool

    private enum Keys { static let token = "authToken"; static let email = "auth.email" }

    var token: String? { Keychain.get(Keys.token) }

    /// Non-isolated accessor so networking code off the main actor can read it.
    nonisolated static var currentToken: String? { Keychain.get("authToken") }

    private init() {
        email = UserDefaults.standard.string(forKey: Keys.email)
        isAuthenticated = Keychain.get(Keys.token) != nil
    }

    struct AuthResponse: Decodable { let token: String; let email: String }

    func register(email: String, password: String) async throws {
        try await submit(path: "auth/register", email: email, password: password)
    }
    func signIn(email: String, password: String) async throws {
        try await submit(path: "auth/login", email: email, password: password)
    }

    func signOut() {
        Keychain.set(nil, for: Keys.token)
        UserDefaults.standard.removeObject(forKey: Keys.email)
        email = nil
        isAuthenticated = false
    }

    private func submit(path: String, email: String, password: String) async throws {
        guard let base = BackendConfig.baseURL else { throw AuthError.message("Set a valid proxy URL first.") }
        var req = URLRequest(url: base.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email.trimmingCharacters(in: .whitespaces),
            "password": password,
        ])
        let (data, resp): (Data, URLResponse)
        do { (data, resp) = try await URLSession.shared.data(for: req) }
        catch { throw AuthError.message("Couldn't reach the server. Is the proxy running?") }

        guard let http = resp as? HTTPURLResponse else { throw AuthError.message("No response from the server.") }
        if !(200...299).contains(http.statusCode) {
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
            throw AuthError.message(msg ?? "That didn't work (HTTP \(http.statusCode)).")
        }
        let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
        Keychain.set(decoded.token, for: Keys.token)
        UserDefaults.standard.set(decoded.email, forKey: Keys.email)
        self.email = decoded.email
        self.isAuthenticated = true
    }
}

enum AuthError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let m) = self { return m }; return nil }
}
