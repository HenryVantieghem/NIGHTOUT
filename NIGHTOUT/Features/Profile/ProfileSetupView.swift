import SwiftUI
import PhotosUI
import Auth

/// First-time profile setup flow after onboarding
@MainActor
struct ProfileSetupView: View {
    @Binding var isComplete: Bool

    @State private var currentStep: SetupStep = .welcome
    @State private var displayName = ""
    @State private var bio = ""
    @State private var avatarImage: UIImage?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var favoriteDrink: DrinkType = .beer
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Animations
    @State private var contentOpacity: Double = 0
    @State private var avatarScale: CGFloat = 0.8

    enum SetupStep: Int, CaseIterable {
        case welcome = 0
        case avatar = 1
        case bio = 2
        case favorite = 3
        case complete = 4

        var title: String {
            switch self {
            case .welcome: return "Welcome!"
            case .avatar: return "Add a Photo"
            case .bio: return "About You"
            case .favorite: return "Your Vibe"
            case .complete: return "You're Ready!"
            }
        }

        var next: SetupStep? {
            SetupStep(rawValue: rawValue + 1)
        }

        var previous: SetupStep? {
            SetupStep(rawValue: rawValue - 1)
        }
    }

    var body: some View {
        ZStack {
            NightOutColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                if currentStep != .welcome && currentStep != .complete {
                    ProgressBar(currentStep: currentStep.rawValue - 1, totalSteps: SetupStep.allCases.count - 2)
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)
                        .padding(.top, NightOutSpacing.lg)
                }

                // Content
                TabView(selection: $currentStep) {
                    WelcomeStep(displayName: displayName, onContinue: { advanceStep() })
                        .tag(SetupStep.welcome)

                    AvatarStep(
                        avatarImage: $avatarImage,
                        selectedPhoto: $selectedPhoto,
                        displayName: displayName,
                        onContinue: { advanceStep() },
                        onSkip: { advanceStep() }
                    )
                    .tag(SetupStep.avatar)

                    BioStep(bio: $bio, onContinue: { advanceStep() }, onSkip: { advanceStep() })
                        .tag(SetupStep.bio)

                    FavoriteDrinkStep(selectedDrink: $favoriteDrink, onContinue: { advanceStep() })
                        .tag(SetupStep.favorite)

                    CompleteStep(displayName: displayName, avatarImage: avatarImage, isSaving: isSaving) {
                        Task { await saveProfile() }
                    }
                    .tag(SetupStep.complete)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            // Load user's display name from session
            if let user = SessionManager.shared.currentUser {
                let metadata = user.userMetadata
                if let name = metadata["display_name"]?.stringValue {
                    displayName = name
                } else if let email = metadata["email"]?.stringValue {
                    displayName = email.components(separatedBy: "@").first ?? "Friend"
                }
            }
        }
    }

    private func advanceStep() {
        NightOutHaptics.light()
        if let next = currentStep.next {
            withAnimation {
                currentStep = next
            }
        }
    }

    private func saveProfile() async {
        isSaving = true
        defer { isSaving = false }

        do {
            // Upload avatar if set
            var avatarUrl: String? = nil
            if let image = avatarImage, let userId = SessionManager.shared.currentUser?.id {
                avatarUrl = try await MediaService.shared.uploadAvatar(userId: userId, image: image)
            }

            // Update profile with bio and avatar
            let update = SupabaseProfileUpdate(
                bio: bio.isEmpty ? nil : bio,
                avatarUrl: avatarUrl
            )

            try await UserService.shared.updateProfile(update: update)

            // Mark profile setup as complete
            UserDefaults.standard.set(true, forKey: "hasCompletedProfileSetup")

            NightOutHaptics.success()

            withAnimation {
                isComplete = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            NightOutHaptics.error()
        }
    }
}

// MARK: - Welcome Step
@MainActor
private struct WelcomeStep: View {
    let displayName: String
    let onContinue: () -> Void

    @State private var iconScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0

    var body: some View {
        VStack(spacing: NightOutSpacing.xxxl) {
            Spacer()

            // Celebration emoji
            Text("🎉")
                .font(.system(size: 100))
                .scaleEffect(iconScale)

            // Welcome message
            VStack(spacing: NightOutSpacing.md) {
                Text("Hey \(displayName.isEmpty ? "there" : displayName)!")
                    .font(NightOutTypography.largeTitle)
                    .foregroundStyle(NightOutColors.chrome)

                Text("Let's set up your profile so your friends can find you.")
                    .font(NightOutTypography.body)
                    .foregroundStyle(NightOutColors.silver)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, NightOutSpacing.xl)
            }
            .opacity(textOpacity)

            Spacer()
            Spacer()

            // Continue button
            GlassButton("Let's Go", icon: "arrow.right", style: .primary, size: .large) {
                onContinue()
            }
            .padding(.horizontal, NightOutSpacing.screenHorizontal)
            .padding(.bottom, NightOutSpacing.xxxl)
        }
        .onAppear {
            withAnimation(NightOutAnimation.bouncy.delay(0.2)) {
                iconScale = 1.0
            }
            withAnimation(NightOutAnimation.smooth.delay(0.4)) {
                textOpacity = 1.0
            }
        }
    }
}

// MARK: - Avatar Step
@MainActor
private struct AvatarStep: View {
    @Binding var avatarImage: UIImage?
    @Binding var selectedPhoto: PhotosPickerItem?
    let displayName: String
    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var showCameraOption = false

    var body: some View {
        VStack(spacing: NightOutSpacing.xxl) {
            Spacer()

            // Header
            VStack(spacing: NightOutSpacing.md) {
                Text("Add a Photo")
                    .font(NightOutTypography.title)
                    .foregroundStyle(NightOutColors.chrome)

                Text("Help your friends recognize you!")
                    .font(NightOutTypography.body)
                    .foregroundStyle(NightOutColors.silver)
            }

            // Avatar preview
            ZStack {
                if let image = avatarImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(NightOutColors.primaryGradient, lineWidth: 3)
                        )
                } else {
                    Circle()
                        .fill(NightOutColors.surface)
                        .frame(width: 150, height: 150)
                        .overlay(
                            Text(displayName.prefix(1).uppercased())
                                .font(.system(size: 60, weight: .bold, design: .rounded))
                                .foregroundStyle(NightOutColors.silver)
                        )
                        .overlay(
                            Circle()
                                .stroke(NightOutColors.glassBorder, lineWidth: 2)
                        )
                }

                // Camera button overlay
                let captionFont = NightOutTypography.caption
                let silverColor = NightOutColors.silver
                PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                    Circle()
                        .fill(NightOutColors.neonPink)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        )
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .offset(x: 55, y: 55)
            }
            .padding(.vertical, NightOutSpacing.xl)

            // Photo picker button
            let captionFont = NightOutTypography.caption
            let silverColor = NightOutColors.silver
            PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                Text("Choose from Library")
                    .font(captionFont)
                    .foregroundStyle(silverColor)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            Spacer()
            Spacer()

            // Buttons
            VStack(spacing: NightOutSpacing.md) {
                GlassButton("Continue", icon: "arrow.right", style: .primary, size: .large) {
                    onContinue()
                }

                Button {
                    onSkip()
                } label: {
                    Text("Skip for now")
                        .font(NightOutTypography.subheadline)
                        .foregroundStyle(NightOutColors.dimmed)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            .padding(.horizontal, NightOutSpacing.screenHorizontal)
            .padding(.bottom, NightOutSpacing.xxxl)
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

// MARK: - Bio Step
@MainActor
private struct BioStep: View {
    @Binding var bio: String
    let onContinue: () -> Void
    let onSkip: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: NightOutSpacing.xxl) {
            Spacer()

            // Header
            VStack(spacing: NightOutSpacing.md) {
                Text("About You")
                    .font(NightOutTypography.title)
                    .foregroundStyle(NightOutColors.chrome)

                Text("Write a short bio so people know what you're about")
                    .font(NightOutTypography.body)
                    .foregroundStyle(NightOutColors.silver)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, NightOutSpacing.lg)
            }

            // Bio input
            VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                TextField("Weekend warrior, cocktail enthusiast...", text: $bio, axis: .vertical)
                    .textFieldStyle(GlassTextFieldStyle())
                    .lineLimit(3...6)
                    .focused($isFocused)

                HStack {
                    Spacer()
                    Text("\(bio.count)/150")
                        .font(NightOutTypography.caption)
                        .foregroundStyle(bio.count > 150 ? NightOutColors.liveRed : NightOutColors.dimmed)
                }
            }
            .padding(.horizontal, NightOutSpacing.screenHorizontal)

            Spacer()
            Spacer()

            // Buttons
            VStack(spacing: NightOutSpacing.md) {
                GlassButton("Continue", icon: "arrow.right", style: .primary, size: .large) {
                    isFocused = false
                    onContinue()
                }

                Button {
                    onSkip()
                } label: {
                    Text("Skip for now")
                        .font(NightOutTypography.subheadline)
                        .foregroundStyle(NightOutColors.dimmed)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            .padding(.horizontal, NightOutSpacing.screenHorizontal)
            .padding(.bottom, NightOutSpacing.xxxl)
        }
    }
}

// MARK: - Favorite Drink Step
@MainActor
private struct FavoriteDrinkStep: View {
    @Binding var selectedDrink: DrinkType
    let onContinue: () -> Void

    private let drinks: [DrinkType] = [.beer, .wine, .cocktail, .champagne, .shot, .spirit, .cider, .water]

    var body: some View {
        VStack(spacing: NightOutSpacing.xxl) {
            Spacer()

            // Header
            VStack(spacing: NightOutSpacing.md) {
                Text("What's Your Vibe?")
                    .font(NightOutTypography.title)
                    .foregroundStyle(NightOutColors.chrome)

                Text("Pick your go-to drink")
                    .font(NightOutTypography.body)
                    .foregroundStyle(NightOutColors.silver)
            }

            // Drink grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: NightOutSpacing.lg) {
                ForEach(drinks, id: \.self) { drink in
                    DrinkOption(drink: drink, isSelected: selectedDrink == drink) {
                        NightOutHaptics.light()
                        withAnimation(NightOutAnimation.bouncy) {
                            selectedDrink = drink
                        }
                    }
                }
            }
            .padding(.horizontal, NightOutSpacing.screenHorizontal)

            Spacer()
            Spacer()

            // Continue button
            GlassButton("Continue", icon: "arrow.right", style: .primary, size: .large) {
                onContinue()
            }
            .padding(.horizontal, NightOutSpacing.screenHorizontal)
            .padding(.bottom, NightOutSpacing.xxxl)
        }
    }
}

@MainActor
private struct DrinkOption: View {
    let drink: DrinkType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: NightOutSpacing.xs) {
                Text(drink.emoji)
                    .font(.system(size: 36))
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                Text(drink.displayName)
                    .font(NightOutTypography.caption)
                    .foregroundStyle(isSelected ? NightOutColors.chrome : NightOutColors.silver)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, NightOutSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: NightOutRadius.md)
                    .fill(isSelected ? drink.color.opacity(0.2) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: NightOutRadius.md)
                            .stroke(isSelected ? drink.color : NightOutColors.glassBorder, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - Complete Step
@MainActor
private struct CompleteStep: View {
    let displayName: String
    let avatarImage: UIImage?
    let isSaving: Bool
    let onFinish: () -> Void

    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            VStack(spacing: NightOutSpacing.xxxl) {
                Spacer()

                // Avatar with checkmark
                ZStack {
                    if let image = avatarImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(NightOutColors.surface)
                            .frame(width: 120, height: 120)
                            .overlay(
                                Text(displayName.prefix(1).uppercased())
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(NightOutColors.silver)
                            )
                    }

                    // Checkmark badge
                    Circle()
                        .fill(NightOutColors.successGreen)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 45, y: 45)
                }
                .scaleEffect(scale)

                // Message
                VStack(spacing: NightOutSpacing.md) {
                    Text("Looking Good!")
                        .font(NightOutTypography.title)
                        .foregroundStyle(NightOutColors.chrome)

                    Text("You're all set to start tracking your nights out with friends!")
                        .font(NightOutTypography.body)
                        .foregroundStyle(NightOutColors.silver)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, NightOutSpacing.xl)
                }
                .opacity(opacity)

                Spacer()
                Spacer()

                // Finish button
                GlassButton("Start the Party!", icon: "party.popper", style: .prominent, size: .large, isLoading: isSaving) {
                    showConfetti = true
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        onFinish()
                    }
                }
                .padding(.horizontal, NightOutSpacing.screenHorizontal)
                .padding(.bottom, NightOutSpacing.xxxl)
            }

            // Confetti overlay
            ConfettiView(isShowing: $showConfetti)
        }
        .onAppear {
            withAnimation(NightOutAnimation.bouncy.delay(0.2)) {
                scale = 1.0
            }
            withAnimation(NightOutAnimation.smooth.delay(0.4)) {
                opacity = 1.0
            }
        }
    }
}

#Preview {
    ProfileSetupView(isComplete: .constant(false))
}
