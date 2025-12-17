import SwiftUI
import PhotosUI
import Auth

/// Edit profile sheet
@MainActor
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let profile: SupabaseProfile

    @State private var displayName: String
    @State private var username: String
    @State private var bio: String
    @State private var avatarImage: UIImage?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    init(profile: SupabaseProfile) {
        self.profile = profile
        _displayName = State(initialValue: profile.displayName)
        _username = State(initialValue: profile.username)
        _bio = State(initialValue: profile.bio ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NightOutSpacing.xxl) {
                    // Avatar
                    VStack(spacing: NightOutSpacing.md) {
                        let currentImage = avatarImage
                        let captionFont = NightOutTypography.caption
                        let silverColor = NightOutColors.silver
                        // Capture values before PhotosPicker closure (Swift 6 concurrency)
                        let avatarUrl = profile.avatarUrl.flatMap { URL(string: $0) }
                        let profileDisplayName = profile.displayName
                        let avatarPlaceholder = AvatarView(url: avatarUrl, name: profileDisplayName, size: 100)

                        PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                            if let image = currentImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                avatarPlaceholder
                            }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Circle())

                        PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                            Text("Change Photo")
                                .font(captionFont)
                                .foregroundStyle(silverColor)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                    .padding(.top, NightOutSpacing.lg)

                    // Form
                    VStack(spacing: NightOutSpacing.lg) {
                        VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                            Text("Display Name")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.silver)

                            TextField("", text: $displayName)
                                .textFieldStyle(GlassTextFieldStyle())
                                .textContentType(.name)
                        }

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

                        VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                            Text("Bio")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.silver)

                            TextField("Tell us about yourself...", text: $bio, axis: .vertical)
                                .textFieldStyle(GlassTextFieldStyle())
                                .lineLimit(3...6)
                        }
                    }
                    .padding(.horizontal, NightOutSpacing.screenHorizontal)

                    Spacer(minLength: NightOutSpacing.xxl)

                    // Save button
                    GlassButton("Save Changes", icon: "checkmark", style: .primary, size: .large, isLoading: isSaving) {
                        Task { await saveChanges() }
                    }
                    .padding(.horizontal, NightOutSpacing.screenHorizontal)
                    .padding(.bottom, NightOutSpacing.xxl)
                }
            }
            .nightOutBackground()
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(NightOutColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(NightOutColors.silver)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    let data = try? await newItem?.loadTransferable(type: Data.self)
                    if let data, let image = UIImage(data: data) {
                        await MainActor.run {
                            avatarImage = image
                        }
                    }
                }
            }
        }
    }

    private func saveChanges() async {
        guard !displayName.isEmpty else {
            errorMessage = "Display name cannot be empty"
            showError = true
            return
        }
        guard !username.isEmpty else {
            errorMessage = "Username cannot be empty"
            showError = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            // Check username availability if changed
            if username != profile.username {
                let available = try await UserService.shared.isUsernameAvailable(username)
                guard available else {
                    errorMessage = "Username is already taken"
                    showError = true
                    return
                }
            }

            // Upload avatar if changed
            var avatarUrl: String? = nil
            if let image = avatarImage, let userId = SessionManager.shared.currentUser?.id {
                avatarUrl = try await MediaService.shared.uploadAvatar(userId: userId, image: image)
            }

            // Update profile
            let update = SupabaseProfileUpdate(
                username: username != profile.username ? username : nil,
                displayName: displayName != profile.displayName ? displayName : nil,
                bio: bio != profile.bio ? bio : nil,
                avatarUrl: avatarUrl
            )

            try await UserService.shared.updateProfile(update: update)

            NightOutHaptics.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            NightOutHaptics.error()
        }
    }
}

#Preview {
    EditProfileView(profile: SupabaseProfile(
        id: UUID(),
        username: "testuser",
        displayName: "Test User",
        bio: "Test bio",
        avatarUrl: nil,
        email: "test@example.com",
        totalNights: 10,
        totalDuration: 36000,
        totalDistance: 25000,
        totalDrinks: 50,
        totalPhotos: 20,
        currentStreak: 3,
        longestStreak: 7,
        emailNotifications: true,
        createdAt: Date(),
        updatedAt: Date()
    ))
}
