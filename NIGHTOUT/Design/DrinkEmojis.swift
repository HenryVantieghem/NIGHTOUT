import SwiftUI

// MARK: - Drink Emoji Button
/// Large tappable drink emoji button for the Add Drink sheet
@MainActor
struct DrinkEmojiButton: View {
    let drinkType: DrinkType
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false
    @State private var showBounce = false

    var body: some View {
        Button(action: {
            NightOutHaptics.medium()
            withAnimation(NightOutAnimation.bouncy) {
                showBounce = true
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000)
                showBounce = false
            }
            action()
        }) {
            VStack(spacing: NightOutSpacing.sm) {
                ZStack {
                    // Background glow when selected
                    if isSelected {
                        Circle()
                            .fill(drinkType.color.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .blur(radius: 10)
                    }

                    // Main emoji
                    Text(drinkType.emoji)
                        .font(.system(size: 48))
                        .scaleEffect(showBounce ? 1.2 : (isPressed ? 0.9 : 1.0))
                        .animation(NightOutAnimation.bouncy, value: showBounce)
                        .animation(NightOutAnimation.quick, value: isPressed)

                    // Count badge
                    if count > 0 {
                        Text("\(count)")
                            .font(NightOutTypography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(NightOutColors.neonPink)
                            )
                            .offset(x: 24, y: -24)
                    }
                }
                .frame(width: 80, height: 80)

                // Label
                Text(drinkType.displayName)
                    .font(NightOutTypography.caption)
                    .foregroundStyle(isSelected ? NightOutColors.chrome : NightOutColors.silver)
            }
            .padding(NightOutSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: NightOutRadius.lg)
                    .fill(isSelected ? NightOutColors.glassBackground : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: NightOutRadius.lg)
                            .stroke(isSelected ? drinkType.color.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Drink Emoji Grid
/// Grid layout for drink selection
@MainActor
struct DrinkEmojiGrid: View {
    let drinkCounts: [DrinkType: Int]
    let selectedDrink: DrinkType?
    let onSelect: (DrinkType) -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: NightOutSpacing.md) {
            ForEach(DrinkType.allCases.filter { $0 != .custom }, id: \.self) { drinkType in
                DrinkEmojiButton(
                    drinkType: drinkType,
                    count: drinkCounts[drinkType] ?? 0,
                    isSelected: selectedDrink == drinkType,
                    action: { onSelect(drinkType) }
                )
            }
        }
    }
}

// MARK: - Drink Counter Display
/// Horizontal scroll of drink emojis with counts (BeerBuddy style)
@MainActor
struct DrinkCounterDisplay: View {
    let drinkCounts: [DrinkType: Int]

    private var sortedDrinks: [(DrinkType, Int)] {
        drinkCounts
            .filter { $0.value > 0 }
            .sorted { $0.value > $1.value }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NightOutSpacing.lg) {
                ForEach(sortedDrinks, id: \.0) { drinkType, count in
                    VStack(spacing: NightOutSpacing.xs) {
                        Text(drinkType.emoji)
                            .font(.system(size: 32))

                        Text("\(count)")
                            .font(NightOutTypography.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(NightOutColors.chrome)
                    }
                    .padding(.horizontal, NightOutSpacing.sm)
                }

                if sortedDrinks.isEmpty {
                    Text("No drinks yet")
                        .font(NightOutTypography.caption)
                        .foregroundStyle(NightOutColors.dimmed)
                }
            }
            .padding(.horizontal, NightOutSpacing.screenHorizontal)
        }
    }
}

// MARK: - Cheers Animation View
/// Celebratory animation when adding a drink
@MainActor
struct CheersAnimationView: View {
    @Binding var isShowing: Bool
    let drinkType: DrinkType

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = -15

    var body: some View {
        if isShowing {
            ZStack {
                // Background blur
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissAnimation()
                    }

                VStack(spacing: NightOutSpacing.lg) {
                    // Clinking glasses
                    HStack(spacing: -20) {
                        Text(drinkType.emoji)
                            .font(.system(size: 80))
                            .rotationEffect(.degrees(-rotation))

                        Text(drinkType.emoji)
                            .font(.system(size: 80))
                            .rotationEffect(.degrees(rotation))
                            .scaleEffect(x: -1, y: 1)
                    }
                    .scaleEffect(scale)

                    Text("Cheers!")
                        .font(NightOutTypography.title)
                        .foregroundStyle(NightOutColors.chrome)
                }
                .opacity(opacity)
            }
            .onAppear {
                NightOutHaptics.success()

                withAnimation(NightOutAnimation.bouncy) {
                    scale = 1.0
                    opacity = 1.0
                    rotation = 0
                }

                // Auto dismiss after delay
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    dismissAnimation()
                }
            }
        }
    }

    private func dismissAnimation() {
        withAnimation(NightOutAnimation.quick) {
            scale = 0.8
            opacity = 0
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            isShowing = false
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        NightOutColors.background.ignoresSafeArea()

        VStack(spacing: 32) {
            // Counter display
            DrinkCounterDisplay(drinkCounts: [
                .beer: 3,
                .cocktail: 2,
                .shot: 1
            ])

            // Grid
            DrinkEmojiGrid(
                drinkCounts: [.beer: 3, .cocktail: 2],
                selectedDrink: .beer,
                onSelect: { _ in }
            )
            .padding()
        }
    }
}
