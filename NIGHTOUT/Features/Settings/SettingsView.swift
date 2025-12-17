import SwiftUI
import StoreKit

/// Premium settings view with profile hero, fun facts, and glass effects
@MainActor
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var profile: SupabaseProfile?
    @State private var showEditProfile = false
    @State private var totalNights = 0
    @State private var totalDrinks = 0
    @State private var isLoading = true

    // Dynamic app version
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NightOutSpacing.lg) {
                    // Profile Hero Card
                    if let profile {
                        ProfileHeroCard(
                            profile: profile,
                            totalNights: totalNights,
                            totalDrinks: totalDrinks,
                            onEditTap: { showEditProfile = true }
                        )
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)
                        .staggerAnimation(index: 0)
                    }

                    // Fun Fact Card
                    if totalNights > 0 {
                        FunFactCard(nights: totalNights, drinks: totalDrinks)
                            .padding(.horizontal, NightOutSpacing.screenHorizontal)
                            .staggerAnimation(index: 1)
                    }

                    // Account Section
                    SettingsSection(title: "Account", index: 2) {
                        SettingsActionRow(
                            icon: "person.circle",
                            title: "Edit Profile",
                            subtitle: "Photo, name, bio",
                            iconColor: NightOutColors.electricBlue
                        ) {
                            showEditProfile = true
                        }

                        Divider().background(NightOutColors.dimmed)

                        SettingsRow(icon: "key", title: "Change Password", iconColor: NightOutColors.goldenHour) {
                            ChangePasswordView()
                        }

                        Divider().background(NightOutColors.dimmed)

                        SettingsRow(icon: "bell.badge", title: "Notifications", iconColor: NightOutColors.neonPink) {
                            NotificationSettingsView()
                        }
                    }

                    // Preferences Section
                    SettingsSection(title: "Preferences", index: 3) {
                        SettingsRow(icon: "paintbrush", title: "Appearance", iconColor: NightOutColors.partyPurple) {
                            AppearanceSettingsView()
                        }

                        Divider().background(NightOutColors.dimmed)

                        SettingsRow(icon: "location", title: "Location Sharing", iconColor: NightOutColors.successGreen) {
                            LocationSharingView()
                        }

                        Divider().background(NightOutColors.dimmed)

                        SettingsRow(icon: "ruler", title: "Units", iconColor: NightOutColors.silver) {
                            UnitsSettingsView()
                        }

                        Divider().background(NightOutColors.dimmed)

                        SettingsRow(icon: "globe", title: "Language", iconColor: NightOutColors.electricBlue) {
                            LanguageSettingsView()
                        }
                    }

                    // Support Section
                    SettingsSection(title: "Support", index: 4) {
                        SettingsActionRow(
                            icon: "questionmark.circle",
                            title: "Help & FAQ",
                            iconColor: NightOutColors.electricBlue
                        ) {
                            openURL("https://nightout.app/help")
                        }

                        Divider().background(NightOutColors.dimmed)

                        SettingsActionRow(
                            icon: "envelope",
                            title: "Contact Us",
                            iconColor: NightOutColors.partyPurple
                        ) {
                            openURL("mailto:support@nightout.app")
                        }

                        Divider().background(NightOutColors.dimmed)

                        SettingsActionRow(
                            icon: "ant",
                            title: "Report a Bug",
                            iconColor: NightOutColors.goldenHour
                        ) {
                            openURL("mailto:bugs@nightout.app?subject=Bug%20Report")
                        }

                        Divider().background(NightOutColors.dimmed)

                        SettingsActionRow(
                            icon: "star",
                            title: "Rate NIGHTOUT",
                            subtitle: "Help us grow!",
                            iconColor: NightOutColors.goldenHour
                        ) {
                            requestAppStoreReview()
                        }
                    }

                    // About Section
                    SettingsSection(title: "About", index: 5) {
                        SettingsRow(icon: "doc.text", title: "Licenses", iconColor: NightOutColors.silver) {
                            LicensesView()
                        }

                        Divider().background(NightOutColors.dimmed)

                        SettingsRow(icon: "lock.shield", title: "Privacy Policy", iconColor: NightOutColors.successGreen) {
                            PrivacyPolicyView()
                        }

                        Divider().background(NightOutColors.dimmed)

                        HStack(spacing: NightOutSpacing.md) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(NightOutColors.silver)
                                .frame(width: 28, height: 28)

                            Text("Version")
                                .font(NightOutTypography.body)
                                .foregroundStyle(NightOutColors.chrome)

                            Spacer()

                            Text(appVersion)
                                .font(NightOutTypography.body)
                                .foregroundStyle(NightOutColors.silver)
                        }
                        .padding(.vertical, NightOutSpacing.md)
                        .frame(minHeight: 44)
                    }

                    // Danger Zone Section
                    SettingsSection(title: "Danger Zone", index: 6) {
                        SettingsActionRow(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: "Sign Out",
                            iconColor: NightOutColors.goldenHour
                        ) {
                            showLogoutConfirmation = true
                        }

                        Divider().background(NightOutColors.dimmed)

                        SettingsActionRow(
                            icon: "trash",
                            title: "Delete Account",
                            iconColor: NightOutColors.liveRed,
                            isDestructive: true
                        ) {
                            showDeleteConfirmation = true
                        }
                    }

                    // Footer
                    VStack(spacing: NightOutSpacing.sm) {
                        Text("Made with 🌙 in Brussels")
                            .font(NightOutTypography.caption)
                            .foregroundStyle(NightOutColors.dimmed)

                        Text("NIGHTOUT © 2024")
                            .font(NightOutTypography.caption2)
                            .foregroundStyle(NightOutColors.dimmed.opacity(0.6))
                    }
                    .padding(.vertical, NightOutSpacing.xxl)
                    .staggerAnimation(index: 7)
                }
                .padding(.vertical, NightOutSpacing.lg)
            }
            .nightOutBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(NightOutColors.silver)
                }
            }
            .alert("Sign Out", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task { await signOut() }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Forever", role: .destructive) {
                    Task { await deleteAccount() }
                }
            } message: {
                Text("This will permanently delete your account and all your data. This action cannot be undone.")
            }
            .sheet(isPresented: $showEditProfile) {
                if let profile {
                    EditProfileView(profile: profile)
                }
            }
            .task {
                await loadData()
            }
        }
    }

    // MARK: - Actions

    private func loadData() async {
        isLoading = true
        do {
            profile = try await UserService.shared.getCurrentProfile()
            let stats = try await NightService.shared.getUserStats()
            totalNights = stats.totalNights
            totalDrinks = stats.totalDrinks
        } catch {
            print("Error loading settings data: \(error)")
        }
        isLoading = false
    }

    private func signOut() async {
        do {
            try await AuthService.shared.signOut()
            SessionManager.shared.clearSession()
            NightOutHaptics.success()
            dismiss()
        } catch {
            print("Sign out error: \(error)")
            NightOutHaptics.error()
        }
    }

    private func deleteAccount() async {
        do {
            try await UserService.shared.deleteAccount()
            SessionManager.shared.clearSession()
            NightOutHaptics.success()
            dismiss()
        } catch {
            print("Delete account error: \(error)")
            NightOutHaptics.error()
        }
    }

    private func requestAppStoreReview() {
        NightOutHaptics.light()
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    private func openURL(_ urlString: String) {
        NightOutHaptics.light()
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Profile Hero Card

@MainActor
private struct ProfileHeroCard: View {
    let profile: SupabaseProfile
    let totalNights: Int
    let totalDrinks: Int
    let onEditTap: () -> Void

    var body: some View {
        VStack(spacing: NightOutSpacing.lg) {
            // Avatar and Name
            HStack(spacing: NightOutSpacing.lg) {
                AvatarView(
                    url: profile.avatarUrl.flatMap { URL(string: $0) },
                    name: profile.displayName ?? profile.username,
                    size: 72
                )
                .overlay(
                    Circle()
                        .stroke(NightOutColors.primaryGradient, lineWidth: 3)
                )

                VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                    Text(profile.displayName ?? profile.username)
                        .font(NightOutTypography.title3)
                        .foregroundStyle(NightOutColors.chrome)

                    Text("@\(profile.username)")
                        .font(NightOutTypography.caption)
                        .foregroundStyle(NightOutColors.silver)

                    if let bio = profile.bio, !bio.isEmpty {
                        Text(bio)
                            .font(NightOutTypography.caption)
                            .foregroundStyle(NightOutColors.dimmed)
                            .lineLimit(2)
                    }
                }

                Spacer()

                Button {
                    NightOutHaptics.light()
                    onEditTap()
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(NightOutColors.neonPink)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }

            // Mini Stats Row
            HStack(spacing: NightOutSpacing.md) {
                MiniStatItem(icon: "moon.fill", value: totalNights, label: "Nights")

                Divider()
                    .frame(height: 32)
                    .background(NightOutColors.glassBorder)

                MiniStatItem(icon: "wineglass.fill", value: totalDrinks, label: "Drinks")

                Divider()
                    .frame(height: 32)
                    .background(NightOutColors.glassBorder)

                MiniStatItem(icon: "person.2.fill", value: profile.friendCount ?? 0, label: "Friends")
            }
        }
        .padding(NightOutSpacing.lg)
        .background(NightOutColors.glassBackground)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: NightOutRadius.card)
                .stroke(NightOutColors.glassBorder, lineWidth: 1)
        )
    }
}

// MARK: - Mini Stat Item

@MainActor
private struct MiniStatItem: View {
    let icon: String
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: NightOutSpacing.xs) {
            HStack(spacing: NightOutSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(NightOutColors.neonPink)

                Text("\(value)")
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.chrome)
                    .contentTransition(.numericText(value: Double(value)))
            }

            Text(label)
                .font(NightOutTypography.caption2)
                .foregroundStyle(NightOutColors.silver)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Fun Fact Card

@MainActor
private struct FunFactCard: View {
    let nights: Int
    let drinks: Int

    private var funFact: (emoji: String, text: String) {
        if nights >= 100 {
            return ("👑", "Legend status! \(nights) nights tracked!")
        } else if nights >= 50 {
            return ("🔥", "Party animal! \(nights) nights and counting!")
        } else if nights >= 25 {
            return ("🎉", "You've tracked \(nights) epic nights!")
        } else if nights >= 10 {
            return ("🌟", "Getting started! \(nights) nights logged!")
        } else {
            return ("🌙", "You've tracked \(nights) night\(nights == 1 ? "" : "s")!")
        }
    }

    var body: some View {
        HStack(spacing: NightOutSpacing.md) {
            Text(funFact.emoji)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 2) {
                Text(funFact.text)
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.chrome)

                Text("Keep the good times rolling!")
                    .font(NightOutTypography.caption)
                    .foregroundStyle(NightOutColors.silver)
            }

            Spacer()
        }
        .padding(NightOutSpacing.lg)
        .background(
            LinearGradient(
                colors: [
                    NightOutColors.partyPurple.opacity(0.3),
                    NightOutColors.neonPink.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: NightOutRadius.card)
                .stroke(NightOutColors.glassBorder, lineWidth: 1)
        )
    }
}

// MARK: - Settings Section Container

@MainActor
private struct SettingsSection<Content: View>: View {
    let title: String
    let index: Int
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: NightOutSpacing.sm) {
            Text(title)
                .font(NightOutTypography.footnote)
                .foregroundStyle(NightOutColors.silver)
                .textCase(.uppercase)
                .padding(.horizontal, NightOutSpacing.screenHorizontal)

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, NightOutSpacing.md)
            .background(NightOutColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
            .padding(.horizontal, NightOutSpacing.screenHorizontal)
        }
        .staggerAnimation(index: index)
    }
}

// MARK: - Placeholder Views

struct ChangePasswordView: View {
    var body: some View {
        Text("Change Password")
            .nightOutBackground()
            .navigationTitle("Change Password")
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        Text("Notification Settings")
            .nightOutBackground()
            .navigationTitle("Notifications")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        Text("Privacy Policy")
            .nightOutBackground()
            .navigationTitle("Privacy Policy")
    }
}

#Preview {
    SettingsView()
}
