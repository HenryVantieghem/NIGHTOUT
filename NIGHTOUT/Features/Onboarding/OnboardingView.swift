import SwiftUI
import CoreLocation
import AVFoundation
import Photos

/// Enhanced onboarding flow with permission requests
@MainActor
struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentStep: OnboardingStep = .welcome

    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case location = 1
        case camera = 2
        case photos = 3
        case notifications = 4
        case ready = 5

        var next: OnboardingStep? {
            OnboardingStep(rawValue: rawValue + 1)
        }
    }

    var body: some View {
        ZStack {
            NightOutColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                ProgressBar(currentStep: currentStep.rawValue, totalSteps: OnboardingStep.allCases.count)
                    .padding(.horizontal, NightOutSpacing.screenHorizontal)
                    .padding(.top, NightOutSpacing.lg)

                // Content
                TabView(selection: $currentStep) {
                    WelcomeStepView(onContinue: { advanceStep() })
                        .tag(OnboardingStep.welcome)

                    LocationPermissionView(onContinue: { advanceStep() })
                        .tag(OnboardingStep.location)

                    CameraPermissionView(onContinue: { advanceStep() })
                        .tag(OnboardingStep.camera)

                    PhotosPermissionView(onContinue: { advanceStep() })
                        .tag(OnboardingStep.photos)

                    NotificationsPermissionView(onContinue: { advanceStep() })
                        .tag(OnboardingStep.notifications)

                    ReadyStepView(onComplete: { completeOnboarding() })
                        .tag(OnboardingStep.ready)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
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

    private func completeOnboarding() {
        NightOutHaptics.success()
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation {
            isComplete = true
        }
    }
}

// MARK: - Progress Bar
@MainActor
struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(NightOutColors.surface)
                    .frame(height: 4)

                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(NightOutColors.primaryGradient)
                    .frame(
                        width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps),
                        height: 4
                    )
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Welcome Step
@MainActor
struct WelcomeStepView: View {
    let onContinue: () -> Void

    @State private var logoScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0

    var body: some View {
        VStack(spacing: NightOutSpacing.xxxl) {
            Spacer()

            // Logo
            VStack(spacing: NightOutSpacing.lg) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(NightOutColors.primaryGradient)
                    .scaleEffect(logoScale)

                Text("NIGHTOUT")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(NightOutColors.chrome)
            }

            // Description
            VStack(spacing: NightOutSpacing.md) {
                Text("Your nights out, tracked.")
                    .font(NightOutTypography.title2)
                    .foregroundStyle(NightOutColors.chrome)

                Text("Track adventures, capture moments, and see where your friends are partying.")
                    .font(NightOutTypography.body)
                    .foregroundStyle(NightOutColors.silver)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, NightOutSpacing.xl)
            }
            .opacity(textOpacity)

            Spacer()
            Spacer()

            // Button
            GlassButton("Get Started", icon: "arrow.right", style: .primary, size: .large) {
                onContinue()
            }
            .padding(.horizontal, NightOutSpacing.screenHorizontal)
            .padding(.bottom, NightOutSpacing.xxxl)
        }
        .onAppear {
            withAnimation(NightOutAnimation.bouncy.delay(0.2)) {
                logoScale = 1.0
            }
            withAnimation(NightOutAnimation.smooth.delay(0.4)) {
                textOpacity = 1.0
            }
        }
    }
}

// MARK: - Permission Step Base
@MainActor
struct PermissionStepView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let buttonTitle: String
    let skipTitle: String
    let onRequest: () async -> Void
    let onSkip: () -> Void

    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: NightOutSpacing.xxxl) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 140, height: 140)

                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundStyle(iconColor)
            }

            // Text
            VStack(spacing: NightOutSpacing.md) {
                Text(title)
                    .font(NightOutTypography.title)
                    .foregroundStyle(NightOutColors.chrome)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(NightOutTypography.body)
                    .foregroundStyle(NightOutColors.silver)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, NightOutSpacing.xl)
            }

            Spacer()
            Spacer()

            // Buttons
            VStack(spacing: NightOutSpacing.md) {
                GlassButton(buttonTitle, icon: "checkmark.circle", style: .primary, size: .large, isLoading: isRequesting) {
                    isRequesting = true
                    Task {
                        await onRequest()
                        isRequesting = false
                    }
                }

                Button {
                    onSkip()
                } label: {
                    Text(skipTitle)
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

// MARK: - Location Permission
@MainActor
struct LocationPermissionView: View {
    let onContinue: () -> Void

    var body: some View {
        PermissionStepView(
            icon: "location.fill",
            iconColor: NightOutColors.electricBlue,
            title: "See Friends on the Map",
            description: "Enable location to see where your friends are partying and share your location during nights out.",
            buttonTitle: "Enable Location",
            skipTitle: "Not Now",
            onRequest: {
                _ = await PermissionsManager.shared.requestLocationPermission()
                onContinue()
            },
            onSkip: onContinue
        )
    }
}

// MARK: - Camera Permission
@MainActor
struct CameraPermissionView: View {
    let onContinue: () -> Void

    var body: some View {
        PermissionStepView(
            icon: "camera.fill",
            iconColor: NightOutColors.neonPink,
            title: "Capture the Moments",
            description: "Take photos and videos during your night to create lasting memories with friends.",
            buttonTitle: "Enable Camera",
            skipTitle: "Not Now",
            onRequest: {
                _ = await PermissionsManager.shared.requestCameraPermission()
                onContinue()
            },
            onSkip: onContinue
        )
    }
}

// MARK: - Photos Permission
@MainActor
struct PhotosPermissionView: View {
    let onContinue: () -> Void

    var body: some View {
        PermissionStepView(
            icon: "photo.on.rectangle",
            iconColor: NightOutColors.partyPurple,
            title: "Add From Gallery",
            description: "Import your best photos and videos to your night timeline after the fact.",
            buttonTitle: "Enable Photos",
            skipTitle: "Not Now",
            onRequest: {
                _ = await PermissionsManager.shared.requestPhotosPermission()
                onContinue()
            },
            onSkip: onContinue
        )
    }
}

// MARK: - Notifications Permission
@MainActor
struct NotificationsPermissionView: View {
    let onContinue: () -> Void

    var body: some View {
        PermissionStepView(
            icon: "bell.fill",
            iconColor: NightOutColors.goldenHour,
            title: "Stay Connected",
            description: "Get notified when friends start a night out, react to your posts, or send you a message.",
            buttonTitle: "Enable Notifications",
            skipTitle: "Not Now",
            onRequest: {
                _ = await PermissionsManager.shared.requestNotificationsPermission()
                onContinue()
            },
            onSkip: onContinue
        )
    }
}

// MARK: - Ready Step
@MainActor
struct ReadyStepView: View {
    let onComplete: () -> Void

    @State private var showConfetti = false
    @State private var checkmarkShowing = false

    var body: some View {
        ZStack {
            VStack(spacing: NightOutSpacing.xxxl) {
                Spacer()

                // Success animation
                ZStack {
                    Circle()
                        .fill(NightOutColors.successGreen.opacity(0.2))
                        .frame(width: 140, height: 140)

                    SuccessCheckmark(isShowing: $checkmarkShowing)
                }

                // Text
                VStack(spacing: NightOutSpacing.md) {
                    Text("You're All Set!")
                        .font(NightOutTypography.title)
                        .foregroundStyle(NightOutColors.chrome)

                    Text("Time to start tracking your nights out with friends. Have fun and stay safe!")
                        .font(NightOutTypography.body)
                        .foregroundStyle(NightOutColors.silver)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, NightOutSpacing.xl)
                }

                Spacer()
                Spacer()

                // Button
                GlassButton("Let's Go!", icon: "party.popper", style: .prominent, size: .large) {
                    showConfetti = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onComplete()
                    }
                }
                .padding(.horizontal, NightOutSpacing.screenHorizontal)
                .padding(.bottom, NightOutSpacing.xxxl)
            }

            // Confetti overlay
            ConfettiView(isShowing: $showConfetti)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                checkmarkShowing = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(isComplete: .constant(false))
}
