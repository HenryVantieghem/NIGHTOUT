import SwiftUI

/// Sign up view for account creation
@MainActor
struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NightOutSpacing.xxl) {
                    // Header
                    VStack(spacing: NightOutSpacing.md) {
                        Text("Create Account")
                            .font(NightOutTypography.largeTitle)
                            .foregroundStyle(NightOutColors.chrome)

                        Text("Join the party")
                            .font(NightOutTypography.body)
                            .foregroundStyle(NightOutColors.silver)
                    }
                    .padding(.top, NightOutSpacing.xl)

                    // Form
                    VStack(spacing: NightOutSpacing.lg) {
                        // Display Name
                        VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                            Text("Display Name")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.silver)

                            TextField("", text: $displayName)
                                .textFieldStyle(GlassTextFieldStyle())
                                .textContentType(.name)
                        }

                        // Username
                        VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                            Text("Username")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.silver)

                            TextField("", text: $username)
                                .textFieldStyle(GlassTextFieldStyle())
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }

                        // Email
                        VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                            Text("Email")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.silver)

                            TextField("", text: $email)
                                .textFieldStyle(GlassTextFieldStyle())
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }

                        // Password
                        VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                            Text("Password")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.silver)

                            SecureField("", text: $password)
                                .textFieldStyle(GlassTextFieldStyle())
                                .textContentType(.newPassword)
                        }

                        // Confirm Password
                        VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                            Text("Confirm Password")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.silver)

                            SecureField("", text: $confirmPassword)
                                .textFieldStyle(GlassTextFieldStyle())
                                .textContentType(.newPassword)
                        }

                        // Password requirements
                        VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                            PasswordRequirement("At least 8 characters", met: password.count >= 8)
                            PasswordRequirement("Contains a number", met: password.contains(where: \.isNumber))
                        }
                        .padding(.vertical, NightOutSpacing.xs)

                        // Sign up button
                        GlassButton("Create Account", icon: "person.badge.plus", style: .primary, size: .large, isLoading: isLoading) {
                            Task { await signUp() }
                        }
                        .padding(.top, NightOutSpacing.sm)
                    }
                    .padding(.horizontal, NightOutSpacing.screenHorizontal)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .nightOutBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(NightOutColors.silver)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onChange(of: showSuccess) { _, success in
                if success {
                    dismiss()
                }
            }
        }
    }

    private func signUp() async {
        // Validate
        guard !displayName.isEmpty else {
            errorMessage = "Please enter your name"
            showError = true
            return
        }
        guard !username.isEmpty else {
            errorMessage = "Please choose a username"
            showError = true
            return
        }
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
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
                displayName: displayName
            )

            // Restore session so RootView updates
            await SessionManager.shared.restoreSession()

            NightOutHaptics.success()
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            NightOutHaptics.error()
        }
    }
}

// MARK: - Password Requirement Row
@MainActor
struct PasswordRequirement: View {
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
