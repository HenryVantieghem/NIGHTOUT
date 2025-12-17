import SwiftUI

/// Sheet to log a drink with skeuomorphic emoji selection
@MainActor
struct AddDrinkView: View {
    @Environment(\.dismiss) private var dismiss
    let nightId: UUID
    let onDrinkAdded: () -> Void

    @State private var selectedType: DrinkType = .beer
    @State private var customName = ""
    @State private var customEmoji = ""
    @State private var isAdding = false
    @State private var showSuccess = false

    init(nightId: UUID, onDrinkAdded: @escaping () -> Void = {}) {
        self.nightId = nightId
        self.onDrinkAdded = onDrinkAdded
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NightOutSpacing.xxl) {
                    // Selected drink preview
                    VStack(spacing: NightOutSpacing.sm) {
                        Text(selectedType.emoji)
                            .font(.system(size: 80))
                            .scaleEffect(showSuccess ? 1.3 : 1.0)

                        Text(selectedType.displayName)
                            .font(NightOutTypography.title2)
                            .foregroundStyle(NightOutColors.chrome)
                    }
                    .padding(.top, NightOutSpacing.lg)
                    .animation(NightOutAnimation.bouncy, value: selectedType)

                    // Drink type grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: NightOutSpacing.md) {
                        ForEach(DrinkType.allCases) { type in
                            DrinkTypeButton(
                                type: type,
                                isSelected: selectedType == type
                            ) {
                                selectedType = type
                                NightOutHaptics.light()
                            }
                        }
                    }
                    .padding(.horizontal, NightOutSpacing.screenHorizontal)

                    // Custom drink fields (if custom selected)
                    if selectedType == .custom {
                        VStack(spacing: NightOutSpacing.md) {
                            VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                                Text("Custom Name")
                                    .font(NightOutTypography.caption)
                                    .foregroundStyle(NightOutColors.silver)

                                TextField("Drink name", text: $customName)
                                    .textFieldStyle(GlassTextFieldStyle())
                            }

                            VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                                Text("Emoji")
                                    .font(NightOutTypography.caption)
                                    .foregroundStyle(NightOutColors.silver)

                                TextField("🍹", text: $customEmoji)
                                    .textFieldStyle(GlassTextFieldStyle())
                            }
                        }
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Spacer(minLength: NightOutSpacing.xxl)

                    // Add button
                    GlassButton(
                        "Add Drink",
                        icon: "plus.circle.fill",
                        style: .primary,
                        size: .large,
                        isLoading: isAdding
                    ) {
                        Task { await addDrink() }
                    }
                    .padding(.horizontal, NightOutSpacing.screenHorizontal)
                    .padding(.bottom, NightOutSpacing.xxl)
                }
                .padding(.top, NightOutSpacing.lg)
            }
            .nightOutBackground()
            .navigationTitle("Add Drink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(NightOutColors.silver)
                }
            }
            .animation(NightOutAnimation.smooth, value: selectedType)
        }
    }

    private func addDrink() async {
        isAdding = true

        do {
            _ = try await DrinkService.shared.addDrink(
                nightId: nightId,
                type: selectedType,
                customName: selectedType == .custom ? customName : nil,
                customEmoji: selectedType == .custom ? customEmoji : nil
            )

            // Success animation
            withAnimation(NightOutAnimation.bouncy) {
                showSuccess = true
            }

            NightOutHaptics.success()

            // Brief delay to show success
            try? await Task.sleep(nanoseconds: 300_000_000)

            onDrinkAdded()
            dismiss()
        } catch {
            print("Error adding drink: \(error)")
            NightOutHaptics.error()
            isAdding = false
        }
    }
}

// MARK: - Drink Type Button
@MainActor
struct DrinkTypeButton: View {
    let type: DrinkType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: NightOutSpacing.sm) {
                // Emoji with color background
                ZStack {
                    Circle()
                        .fill(type.color.opacity(isSelected ? 0.3 : 0.1))
                        .frame(width: 56, height: 56)

                    Text(type.emoji)
                        .font(.system(size: 32))
                }

                Text(type.displayName)
                    .font(NightOutTypography.caption)
                    .foregroundStyle(isSelected ? NightOutColors.chrome : NightOutColors.silver)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, NightOutSpacing.md)
            .background(isSelected ? type.color.opacity(0.15) : NightOutColors.glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: NightOutRadius.md)
                    .stroke(isSelected ? type.color : NightOutColors.glassBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(NightOutAnimation.bouncy, value: isSelected)
    }
}

#Preview {
    AddDrinkView(nightId: UUID())
}
