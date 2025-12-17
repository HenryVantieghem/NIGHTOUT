import SwiftUI

/// Forgot password view with email-based reset
@MainActor
struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var iconScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NightOutSpacing.xxl) {
                    Spacer(minLength: NightOutSpacing.xxxl)

                    // Icon
                    ZStack {
                        Circle()
                            .fill(NightOutColors.electricBlue.opacity(0.2))
                            .frame(width: 120, height: 120)

                        Image(systemName: "key.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(NightOutColors.electricBlue)
                    }
                    .scaleEffect(iconScale)

                    // Header
                    VStack(spacing: NightOutSpacing.md) {
                        Text("Forgot Password?")
                            .font(NightOutTypography.title)
                            .foregroundStyle(NightOutColors.chrome)

                        Text("No worries! Enter your email and we'll send you a link to reset your password.")
                            .font(NightOutTypography.body)
                            .foregroundStyle(NightOutColors.silver)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, NightOutSpacing.lg)
                    }
                    .opacity(textOpacity)

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

                        // Reset button
                        GlassButton("Send Reset Link", icon: "paperplane.fill", style: .primary, size: .large, isLoading: isLoading) {
                            Task { await resetPassword() }
                        }
                    }
                    .padding(.horizontal, NightOutSpacing.screenHorizontal)
                    .opacity(textOpacity)

                    Spacer(minLength: NightOutSpacing.xxl)

                    // Back to sign in
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: NightOutSpacing.xs) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 14))
                            Text("Back to Sign In")
                        }
                        .font(NightOutTypography.headline)
                        .foregroundStyle(NightOutColors.silver)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .padding(.bottom, NightOutSpacing.xxl)
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
            .alert("Check Your Email", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("We've sent a password reset link to \(email). Check your inbox and follow the instructions.")
            }
            .onAppear {
                withAnimation(NightOutAnimation.bouncy.delay(0.1)) {
                    iconScale = 1.0
                }
                withAnimation(NightOutAnimation.smooth.delay(0.2)) {
                    textOpacity = 1.0
                }
            }
        }
    }

    private func resetPassword() async {
        // Validate email
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            showError = true
            NightOutHaptics.error()
            return
        }

        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            showError = true
            NightOutHaptics.error()
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await AuthService.shared.resetPassword(email: email)
            NightOutHaptics.success()
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            NightOutHaptics.error()
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
}

#Preview {
    ForgotPasswordView()
}
