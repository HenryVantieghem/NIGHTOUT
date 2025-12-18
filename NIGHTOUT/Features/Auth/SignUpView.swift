import SwiftUI

/// Combined authentication view with sign in / sign up toggle
/// Pixel-perfect redesign matching reference screenshots
@MainActor
struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss

    // Auth mode toggle
    @State private var isSignUp = true

    // Sign Up fields
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    // UI state
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    var body: some View {
        ZStack {
            // Vignette background
            NightOutColors.backgroundVignette
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: NightOutSpacing.xxl) {
                    // Logo section
                    logoSection
                        .padding(.top, NightOutSpacing.huge)

                    // Auth toggle
                    AuthToggle(isSignUp: $isSignUp)
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)

                    // Form fields
                    formSection
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)

                    // Primary button
                    primaryButton
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)

                    // Terms text
                    if isSignUp {
                        Text("By signing up, you agree to our terms and conditions")
                            .font(NightOutTypography.caption)
                            .foregroundStyle(NightOutColors.silver)
                            .multilineTextAlignment(.center)
                    }

                    // Guest option
                    guestSection
                        .padding(.top, NightOutSpacing.md)

                    Spacer(minLength: NightOutSpacing.huge)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Account Created", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Check your email to verify your account, then sign in.")
        }
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(spacing: NightOutSpacing.lg) {
            DiscoBallLogo(size: 80)

            Text("NIGHTOUT")
                .font(NightOutTypography.largeTitle)
                .foregroundStyle(NightOutColors.chrome)
                .tracking(2)
        }
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: NightOutSpacing.lg) {
            UltraInputField(
                icon: Emoji.email,
                placeholder: "Email",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )

            if isSignUp {
                UltraInputField(
                    icon: "@",
                    placeholder: "Username",
                    text: $username,
                    textContentType: .username
                )
            }

            UltraInputField(
                icon: Emoji.password,
                placeholder: "Password",
                text: $password,
                isSecure: true,
                textContentType: isSignUp ? .newPassword : .password
            )

            if isSignUp {
                UltraInputField(
                    icon: Emoji.password,
                    placeholder: "Confirm Password",
                    text: $confirmPassword,
                    isSecure: true,
                    textContentType: .newPassword
                )
            }

            // Password requirements (sign up only)
            if isSignUp {
                VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                    PasswordRequirementRow("At least 8 characters", met: password.count >= 8)
                    PasswordRequirementRow("Contains a number", met: password.contains(where: \.isNumber))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .animation(NightOutAnimation.smooth, value: isSignUp)
    }

    // MARK: - Primary Button

    private var primaryButton: some View {
        PrimaryGradientButton(
            title: isSignUp ? "Create Account" : "Sign In",
            emoji: isSignUp ? Emoji.party : nil,
            isLoading: isLoading
        ) {
            Task {
                if isSignUp {
                    await signUp()
                } else {
                    await signIn()
                }
            }
        }
    }

    // MARK: - Guest Section

    private var guestSection: some View {
        Button {
            NightOutHaptics.light()
            continueAsGuest()
        } label: {
            VStack(spacing: NightOutSpacing.xs) {
                HStack(spacing: NightOutSpacing.xs) {
                    Text("Continue as Guest")
                        .font(NightOutTypography.subheadline)
                        .foregroundStyle(NightOutColors.silver)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                        .foregroundStyle(NightOutColors.silver)
                }

                Text("Some features require sign in")
                    .font(NightOutTypography.caption2)
                    .foregroundStyle(NightOutColors.dimmed)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    // MARK: - Actions

    private func signUp() async {
        // Validate
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            showError = true
            return
        }
        guard !username.isEmpty else {
            errorMessage = "Please choose a username"
            showError = true
            return
        }
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            showError = true
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Check username availability
            let available = try await UserService.shared.isUsernameAvailable(username)
            guard available else {
                errorMessage = "Username is already taken"
                showError = true
                return
            }

            // Create account
            try await AuthService.shared.signUp(
                email: email,
                password: password,
                username: username,
                displayName: username
            )

            NightOutHaptics.success()
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            NightOutHaptics.error()
        }
    }

    private func signIn() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            showError = true
            return
        }
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await AuthService.shared.signIn(email: email, password: password)
            NightOutHaptics.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            NightOutHaptics.error()
        }
    }

    private func continueAsGuest() {
        SessionManager.shared.enableGuestMode()
        dismiss()
    }
}

// MARK: - Password Requirement Row
@MainActor
struct PasswordRequirementRow: View {
    let text: String
    let met: Bool

    init(_ text: String, met: Bool) {
        self.text = text
        self.met = met
    }

    var body: some View {
        HStack(spacing: NightOutSpacing.sm) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundStyle(met ? NightOutColors.successGreen : NightOutColors.dimmed)

            Text(text)
                .font(NightOutTypography.caption)
                .foregroundStyle(met ? NightOutColors.silver : NightOutColors.dimmed)
        }
    }
}

#Preview {
    SignUpView()
}
