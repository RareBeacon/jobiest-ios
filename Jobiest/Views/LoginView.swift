import SwiftUI

struct LoginView: View {
    @StateObject private var auth = AuthService.shared
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var error: String?
    @State private var busy = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Jobiest")
                .font(.largeTitle.bold())
            Text("Your AI career agent. Only sends applications you approve.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                if isSignUp {
                    TextField("Full name", text: $fullName)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                }
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .textFieldStyle(.roundedBorder)
                SecureField("Password", text: $password)
                    .textContentType(isSignUp ? .newPassword : .password)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal, 32)

            if let error {
                Text(error).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
            }

            Button {
                Task { await submit() }
            } label: {
                if busy { ProgressView().frame(maxWidth: .infinity) }
                else { Text(isSignUp ? "Create account" : "Sign in").frame(maxWidth: .infinity) }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(busy || email.isEmpty || password.isEmpty || (isSignUp && fullName.isEmpty))
            .padding(.horizontal, 32)

            Button(isSignUp ? "I already have an account" : "New here? Create an account") {
                withAnimation { isSignUp.toggle(); error = nil }
            }
            .font(.footnote)

            Spacer()
        }
    }

    private func submit() async {
        busy = true
        error = nil
        do {
            if isSignUp {
                try await auth.signUp(email: email, password: password, fullName: fullName)
                if !auth.isAuthenticated {
                    error = "Check your inbox to confirm your email, then sign in."
                }
            } else {
                try await auth.signIn(email: email, password: password)
            }
        } catch {
            self.error = error.localizedDescription
        }
        busy = false
    }
}
