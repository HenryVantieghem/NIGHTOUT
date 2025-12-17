import SwiftUI

/// Main settings view
@MainActor
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NightOutSpacing.lg) {
                    // Account section
                    SectionHeader("Account")

                    VStack(spacing: 0) {
                        NavigationLink {
                            Text("Edit Profile") // Placeholder - EditProfileView used elsewhere
                        } label: {
                            SettingsRow(title: "Edit Profile", icon: "person")
                        }
                    }
                    .background(NightOutColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
                    .padding(.horizontal, NightOutSpacing.screenHorizontal)

                    // Preferences section
                    SectionHeader("Preferences")

                    VStack(spacing: 0) {
                        NavigationLink {
                            AppearanceSettingsView()
                        } label: {
                            SettingsRow(title: "Appearance", icon: "paintbrush")
                        }

                        Divider()
                            .background(NightOutColors.dimmed)

                        NavigationLink {
                            LocationSharingView()
                        } label: {
                            SettingsRow(title: "Location Sharing", icon: "location")
                        }

                        Divider()
                            .background(NightOutColors.dimmed)

                        NavigationLink {
                            UnitsSettingsView()
                        } label: {
                            SettingsRow(title: "Units", icon: "ruler")
                        }

                        Divider()
                            .background(NightOutColors.dimmed)

                        NavigationLink {
                            LanguageSettingsView()
                        } label: {
                            SettingsRow(title: "Language", icon: "globe")
                        }
                    }
                    .background(NightOutColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
                    .padding(.horizontal, NightOutSpacing.screenHorizontal)

                    // About section
                    SectionHeader("About")

                    VStack(spacing: 0) {
                        NavigationLink {
                            LicensesView()
                        } label: {
                            SettingsRow(title: "Licenses", icon: "doc.text")
                        }

                        Divider()
                            .background(NightOutColors.dimmed)

                        SettingsRow(title: "Version", icon: "info.circle", value: "14.0")
                    }
                    .background(NightOutColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
                    .padding(.horizontal, NightOutSpacing.screenHorizontal)

                    // Sign out
                    GlassButton("Sign Out", icon: "arrow.right.square", style: .destructive, size: .large) {
                        showLogoutConfirmation = true
                    }
                    .padding(.horizontal, NightOutSpacing.screenHorizontal)
                    .padding(.top, NightOutSpacing.lg)
                }
                .padding(.vertical, NightOutSpacing.lg)
            }
            .nightOutBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(NightOutColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
        }
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
}

#Preview {
    SettingsView()
}
