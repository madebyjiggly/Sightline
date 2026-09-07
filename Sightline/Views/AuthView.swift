import SwiftUI

struct AuthView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss

    enum Mode { case signIn, register }
    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    @State private var loading = false
    @FocusState private var focus: Field?
    enum Field { case email, password }

    private var title: String { mode == .signIn ? "Sign in" : "Create account" }

    var body: some View {
        NavigationStack {
            Screen(title: title) {
                CardBox {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(mode == .signIn ? "Welcome back." : "Create your Sightline account to connect a real bank and sync across devices.")
                            .font(.system(size: 13)).foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        field("Email") {
                            TextField("you@example.com", text: $email)
                                .textInputAutocapitalization(.never).autocorrectionDisabled()
                                .keyboardType(.emailAddress).textContentType(.username)
                                .focused($focus, equals: .email)
                        }
                        field("Password") {
                            SecureField("At least 6 characters", text: $password)
                                .textContentType(mode == .signIn ? .password : .newPassword)
                                .focused($focus, equals: .password)
                        }

                        if let error {
                            Text(error).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(Theme.bad)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Button(action: submit) {
                            HStack {
                                if loading { ProgressView().tint(.white) }
                                Text(loading ? "Please wait…" : title)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(canSubmit ? Theme.accent : Theme.faint,
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(.white).font(.system(size: 15, weight: .bold))
                        }
                        .disabled(!canSubmit || loading)
                    }
                }

                Button {
                    withAnimation { mode = (mode == .signIn ? .register : .signIn); error = nil }
                } label: {
                    Text(mode == .signIn ? "New here? Create an account" : "Already have an account? Sign in")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.accentInk)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 2)

                Text("Your password is hashed on the server; only a session token is stored on this device.")
                    .font(.system(size: 11)).foregroundStyle(Theme.faint)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focus = .email } }
        }
    }

    private var canSubmit: Bool {
        email.contains("@") && password.count >= 6
    }

    private func submit() {
        loading = true; error = nil
        Task {
            do {
                if mode == .signIn { try await auth.signIn(email: email, password: password) }
                else { try await auth.register(email: email, password: password) }
                loading = false
                dismiss()
            } catch {
                self.error = error.localizedDescription
                loading = false
            }
        }
    }

    @ViewBuilder private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.muted)
            content()
                .font(.system(size: 15)).foregroundStyle(Theme.ink)
                .padding(13)
                .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.line, lineWidth: 1))
        }
    }
}
