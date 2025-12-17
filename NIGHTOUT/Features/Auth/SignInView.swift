import SwiftUI

/// Sign in view with email/password and magic link options
@MainActor
struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    @State private var showMagicLinkSent = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NightOutSpacing.xxl) {
                    // Logo/Header
                    VStack(spacing: NightOutSpacing.md) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(NightOutColors.primaryGradient)

                        Text("NIGHTOUT")
                            .font(NightOutTypography.largeTitle)
                            .foregroundStyle(NightOutColors.chrome)

                        Text("Track your nights out")
                            .font(NightOutTypography.body)
                            .foregroundStyle(NightOutColors.silver)
                    }
                    .padding(.top, NightOutSpacing.xxxl)

                    // Form
                    VStack(spacing: NightOutSpacing.lg) {
                        // Email field
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

                        // Password field
                        VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                            Text("Password")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.silver)

                            SecureField("", text: $password)
                                .textFieldStyle(GlassTextFieldStyle())
                                .textContentType(.password)

                            // Forgot password link
                            HStack {
                                Spacer()
                                Button {
                                    showForgotPassword = true
                                } label: {
                                    Text("Forgot Password?")
                                        .font(NightOutTypography.caption)
                                        .foregroundStyle(NightOutColors.neonPink)
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                            }
                            .padding(.top, NightOutSpacing.xs)
                        }

                        // Sign in button
                        GlassButton("Sign In", icon: "arrow.right", style: .primary, size: .large, isLoading: isLoading) {
                            Task { await signIn() }
                        }
                        .padding(.top, NightOutSpacing.sm)

                        // Divider
                        HStack {
                            Rectangle()
                                .fill(NightOutColors.dimmed)
                                .frame(height: 1)
                            Text("or")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.dimmed)
                            Rectangle()
                                .fill(NightOutColors.dimmed)
                                .frame(height: 1)
                        }

                        // Magic link button
                        GlassButton("Send Magic Link", icon: "envelope", style: .secondary, size: .large) {
                            Task { await sendMagicLink() }
                        }
                    }
                    .padding(.horizontal, NightOutSpacing.screenHorizontal)

                    Spacer(minLength: NightOutSpacing.xxl)

                    // Sign up link
                    HStack(spacing: NightOutSpacing.xs) {
                        Text("Don't have an account?")
                            .font(NightOutTypography.body)
                            .foregroundStyle(NightOutColors.silver)

                        Button("Sign Up") {
                            showSignUp = true
                        }
                        .font(NightOutTypography.headline)
                        .foregroundStyle(NightOutColors.neonPink)
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                    .padding(.bottom, NightOutSpacing.xxl)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .nightOutBackground()
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Check Your Email", isPresented: $showMagicLinkSent) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("We've sent you a magic link to sign in. Check your inbox!")
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }

    private func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await AuthService.shared.signIn(email: email, password: password)
            await SessionManager.shared.restoreSession()
            NightOutHaptics.success()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            NightOutHaptics.error()
        }
    }

    private func sendMagicLink() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await AuthService.shared.signInWithMagicLink(email: email)
            showMagicLinkSent = true
            NightOutHaptics.success()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            NightOutHaptics.error()
        }
    }
}

// MARK: - Glass Text Field Style
struct GlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(NightOutSpacing.md)
            .background(NightOutColors.glassBackground)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: NightOutRadius.md)
                    .stroke(NightOutColors.glassBorder, lineWidth: 1)
            )
            .foregroundStyle(NightOutColors.chrome)
    }
}

#Preview {
    SignInView()
}
