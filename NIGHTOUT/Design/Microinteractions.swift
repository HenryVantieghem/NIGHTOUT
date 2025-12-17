import SwiftUI

// MARK: - Confetti Particle
/// Individual confetti particle for celebrations
struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var color: Color
    var rotation: Double
    var scale: CGFloat
    var velocity: CGPoint
    var rotationSpeed: Double
}

// MARK: - Confetti View
/// Celebratory confetti animation for achievements and milestones
@MainActor
struct ConfettiView: View {
    @Binding var isShowing: Bool

    @State private var particles: [ConfettiParticle] = []
    @State private var timer: Timer?
    @State private var viewSize: CGSize = .zero

    private let colors: [Color] = [
        NightOutColors.neonPink,
        NightOutColors.partyPurple,
        NightOutColors.electricBlue,
        NightOutColors.goldenHour,
        NightOutColors.successGreen
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: 8 * particle.scale, height: 8 * particle.scale)
                        .position(particle.position)
                        .rotationEffect(.degrees(particle.rotation))
                }
            }
            .onAppear {
                viewSize = geometry.size
            }
            .onChange(of: geometry.size) { _, newSize in
                viewSize = newSize
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isShowing) { _, newValue in
            if newValue {
                startConfetti()
            } else {
                stopConfetti()
            }
        }
    }

    private func startConfetti() {
        NightOutHaptics.success()

        // Create initial burst
        for _ in 0..<50 {
            let particle = createParticle()
            particles.append(particle)
        }

        // Animate particles
        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            Task { @MainActor in
                updateParticles()
            }
        }

        // Auto stop after 3 seconds
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            stopConfetti()
        }
    }

    private func stopConfetti() {
        timer?.invalidate()
        timer = nil
        withAnimation(NightOutAnimation.smooth) {
            particles.removeAll()
            isShowing = false
        }
    }

    private func createParticle() -> ConfettiParticle {
        let screenWidth = viewSize.width > 0 ? viewSize.width : 400

        return ConfettiParticle(
            position: CGPoint(x: screenWidth / 2, y: -20),
            color: colors.randomElement() ?? NightOutColors.neonPink,
            rotation: Double.random(in: 0...360),
            scale: CGFloat.random(in: 0.5...1.5),
            velocity: CGPoint(
                x: CGFloat.random(in: -200...200),
                y: CGFloat.random(in: 300...600)
            ),
            rotationSpeed: Double.random(in: -360...360)
        )
    }

    private func updateParticles() {
        let dt: CGFloat = 1/60
        let gravity: CGFloat = 500
        let screenHeight = viewSize.height > 0 ? viewSize.height : 800

        particles = particles.compactMap { particle in
            var updated = particle
            updated.position.x += particle.velocity.x * dt
            updated.position.y += particle.velocity.y * dt
            updated.velocity.y += gravity * dt
            updated.rotation += particle.rotationSpeed * dt

            // Remove if off screen
            if updated.position.y > screenHeight + 50 {
                return nil
            }
            return updated
        }
    }
}

// MARK: - Pulse Glow Modifier
/// Breathing pulse effect for live indicators
struct PulseGlowModifier: ViewModifier {
    let color: Color
    let intensity: Double
    let duration: Double

    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(isPulsing ? intensity : intensity * 0.3),
                radius: isPulsing ? 12 : 4
            )
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulseGlow(
        color: Color = NightOutColors.liveRed,
        intensity: Double = 0.6,
        duration: Double = 1.0
    ) -> some View {
        modifier(PulseGlowModifier(color: color, intensity: intensity, duration: duration))
    }
}

// MARK: - Gold Shimmer Effect
/// Gold shimmer sweep for achievements
struct GoldShimmerModifier: ViewModifier {
    let duration: Double
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.4),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: -geometry.size.width * 0.25 + phase * geometry.size.width * 1.5)
                    .mask(content)
                }
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: duration)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func goldShimmer(duration: Double = 2.0) -> some View {
        modifier(GoldShimmerModifier(duration: duration))
    }
}

// MARK: - Bounce Press Modifier
/// Spring bounce effect on button press
struct BouncePressModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(NightOutAnimation.bouncy, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            NightOutHaptics.light()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

extension View {
    func bouncePress() -> some View {
        modifier(BouncePressModifier())
    }
}

// MARK: - Success Checkmark Animation
/// Animated checkmark for completion states
@MainActor
struct SuccessCheckmark: View {
    @Binding var isShowing: Bool

    @State private var scale: CGFloat = 0
    @State private var strokeEnd: CGFloat = 0
    @State private var rotation: Double = -90

    var body: some View {
        if isShowing {
            ZStack {
                // Circle background
                Circle()
                    .fill(NightOutColors.successGreen)
                    .frame(width: 80, height: 80)
                    .scaleEffect(scale)

                // Checkmark path
                CheckmarkShape()
                    .trim(from: 0, to: strokeEnd)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(rotation))
            }
            .onAppear {
                NightOutHaptics.success()

                withAnimation(NightOutAnimation.bouncy) {
                    scale = 1.0
                    rotation = 0
                }

                withAnimation(NightOutAnimation.smooth.delay(0.2)) {
                    strokeEnd = 1.0
                }
            }
        }
    }
}

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.2, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.7))
        path.addLine(to: CGPoint(x: width * 0.8, y: height * 0.3))

        return path
    }
}

// MARK: - Heart Burst Animation
/// Twitter-style heart burst on like
@MainActor
struct HeartBurstView: View {
    @Binding var isLiked: Bool

    @State private var scale: CGFloat = 1
    @State private var particleScale: CGFloat = 0
    @State private var particleOpacity: Double = 1

    private let particleColors: [Color] = [
        NightOutColors.neonPink,
        NightOutColors.liveRed,
        NightOutColors.partyPurple,
        NightOutColors.goldenHour
    ]

    var body: some View {
        ZStack {
            // Burst particles
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(particleColors[index % particleColors.count])
                    .frame(width: 6, height: 6)
                    .offset(y: -20 * particleScale)
                    .rotationEffect(.degrees(Double(index) * 45))
                    .scaleEffect(particleScale)
                    .opacity(particleOpacity)
            }

            // Heart icon
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .font(.system(size: 24))
                .foregroundStyle(isLiked ? NightOutColors.liveRed : NightOutColors.silver)
                .scaleEffect(scale)
        }
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            toggleLike()
        }
    }

    private func toggleLike() {
        isLiked.toggle()

        if isLiked {
            NightOutHaptics.medium()

            // Heart bounce
            withAnimation(NightOutAnimation.bouncy) {
                scale = 1.3
            }
            withAnimation(NightOutAnimation.bouncy.delay(0.1)) {
                scale = 1.0
            }

            // Particle burst
            withAnimation(NightOutAnimation.smooth) {
                particleScale = 1.5
            }
            withAnimation(NightOutAnimation.smooth.delay(0.1)) {
                particleOpacity = 0
            }

            // Reset particles
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                particleScale = 0
                particleOpacity = 1
            }
        } else {
            NightOutHaptics.light()

            withAnimation(NightOutAnimation.quick) {
                scale = 0.8
            }
            withAnimation(NightOutAnimation.quick.delay(0.05)) {
                scale = 1.0
            }
        }
    }
}

// MARK: - Loading Dots Animation
/// Animated loading dots
@MainActor
struct LoadingDotsView: View {
    @State private var animatingDot = 0

    private let dotCount = 3
    private let dotSize: CGFloat = 8
    private let color = NightOutColors.neonPink

    var body: some View {
        HStack(spacing: dotSize) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(animatingDot == index ? 1.2 : 0.8)
                    .opacity(animatingDot == index ? 1.0 : 0.4)
            }
        }
        .onAppear {
            animateDots()
        }
    }

    private func animateDots() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(NightOutAnimation.bouncy) {
                    animatingDot = (animatingDot + 1) % dotCount
                }
            }
        }
    }
}

// MARK: - Typing Indicator
/// Chat-style typing indicator
@MainActor
struct TypingIndicatorView: View {
    var body: some View {
        HStack(spacing: NightOutSpacing.sm) {
            LoadingDotsView()

            Text("typing...")
                .font(NightOutTypography.caption)
                .foregroundStyle(NightOutColors.dimmed)
        }
        .padding(.horizontal, NightOutSpacing.md)
        .padding(.vertical, NightOutSpacing.sm)
        .background(NightOutColors.glassBackground)
        .clipShape(Capsule())
    }
}

// MARK: - Toast Notification
/// Slide-up toast notification
@MainActor
struct ToastView: View {
    let message: String
    let icon: String?
    let style: ToastStyle
    @Binding var isShowing: Bool

    enum ToastStyle {
        case success, error, info

        var color: Color {
            switch self {
            case .success: return NightOutColors.successGreen
            case .error: return NightOutColors.liveRed
            case .info: return NightOutColors.electricBlue
            }
        }

        var defaultIcon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    var body: some View {
        if isShowing {
            HStack(spacing: NightOutSpacing.sm) {
                Image(systemName: icon ?? style.defaultIcon)
                    .foregroundStyle(style.color)

                Text(message)
                    .font(NightOutTypography.subheadline)
                    .foregroundStyle(NightOutColors.chrome)
            }
            .padding(.horizontal, NightOutSpacing.lg)
            .padding(.vertical, NightOutSpacing.md)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(NightOutShadows.medium)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                NightOutHaptics.light()

                // Auto dismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(NightOutAnimation.smooth) {
                        isShowing = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Microinteractions") {
    ZStack {
        NightOutColors.background.ignoresSafeArea()

        VStack(spacing: 32) {
            // Heart burst
            HeartBurstView(isLiked: .constant(true))

            // Success checkmark
            SuccessCheckmark(isShowing: .constant(true))

            // Loading dots
            LoadingDotsView()

            // Animated counter
            AnimatedCounter(value: 42, font: NightOutTypography.statNumber, color: NightOutColors.chrome)

            // Shimmer button
            GlassButton("Achievement Unlocked", icon: "star.fill", style: .prominent, size: .large) {}
                .goldShimmer()

            // Pulse glow
            Circle()
                .fill(NightOutColors.liveRed)
                .frame(width: 12, height: 12)
                .pulseGlow()
        }
    }
}
