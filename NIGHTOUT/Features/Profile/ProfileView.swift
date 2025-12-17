import SwiftUI

/// User profile view
@MainActor
struct ProfileView: View {
    @State private var profile: SupabaseProfile?
    @State private var nights: [SupabaseNight] = []
    @State private var isLoading = true
    @State private var showSettings = false
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingView()
                } else if let profile {
                    ScrollView {
                        VStack(spacing: NightOutSpacing.lg) {
                            // Profile header
                            VStack(spacing: NightOutSpacing.md) {
                                AvatarView(
                                    url: profile.avatarUrl.flatMap { URL(string: $0) },
                                    name: profile.displayName,
                                    size: 100
                                )

                                VStack(spacing: NightOutSpacing.xs) {
                                    Text(profile.displayName)
                                        .font(NightOutTypography.title2)
                                        .foregroundStyle(NightOutColors.chrome)

                                    Text("@\(profile.username)")
                                        .font(NightOutTypography.body)
                                        .foregroundStyle(NightOutColors.silver)
                                }

                                if let bio = profile.bio, !bio.isEmpty {
                                    Text(bio)
                                        .font(NightOutTypography.body)
                                        .foregroundStyle(NightOutColors.silver)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, NightOutSpacing.xl)
                                }

                                GlassButton("Edit Profile", icon: "pencil", style: .secondary, size: .small) {
                                    showEditProfile = true
                                }
                            }
                            .padding(.vertical, NightOutSpacing.lg)

                            // Stats
                            GlassCard {
                                HStack {
                                    ProfileStatItem(value: profile.totalNights, label: "Nights")
                                    ProfileStatItem(value: friendCount, label: "Friends")
                                    ProfileStatItem(value: profile.currentStreak, label: "Streak")
                                }
                            }
                            .padding(.horizontal, NightOutSpacing.screenHorizontal)

                            // My nights
                            SectionHeader("My Nights")

                            if nights.isEmpty {
                                GlassCard {
                                    VStack(spacing: NightOutSpacing.sm) {
                                        Image(systemName: "moon.zzz")
                                            .font(.system(size: 32))
                                            .foregroundStyle(NightOutColors.dimmed)

                                        Text("No nights yet")
                                            .font(NightOutTypography.body)
                                            .foregroundStyle(NightOutColors.silver)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, NightOutSpacing.lg)
                                }
                                .padding(.horizontal, NightOutSpacing.screenHorizontal)
                            } else {
                                LazyVStack(spacing: NightOutSpacing.md) {
                                    ForEach(nights) { night in
                                        NavigationLink {
                                            NightDetailView(nightId: night.id)
                                        } label: {
                                            NightCardView(night: night)
                                        }
                                        .buttonStyle(.plain)
                                        .contentShape(Rectangle())
                                    }
                                }
                                .padding(.horizontal, NightOutSpacing.screenHorizontal)
                            }
                        }
                        .padding(.bottom, NightOutSpacing.xxl)
                    }
                    .refreshable {
                        await loadData()
                    }
                } else {
                    EmptyStateView(
                        icon: "person.crop.circle.badge.exclamationmark",
                        title: "Profile Not Found",
                        message: "There was an error loading your profile."
                    )
                }
            }
            .nightOutBackground()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(NightOutColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(NightOutColors.chrome)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showEditProfile) {
                if let profile {
                    EditProfileView(profile: profile)
                }
            }
        }
        .task {
            await loadData()
        }
    }

    // TODO: Fetch actual friend count
    private var friendCount: Int { 0 }

    private func loadData() async {
        do {
            profile = try await UserService.shared.getCurrentProfile()
            nights = try await NightService.shared.getMyNights(limit: 20)
        } catch {
            print("Error loading profile: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    ProfileView()
}
