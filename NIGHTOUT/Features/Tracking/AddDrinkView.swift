import SwiftUI

/// Sheet to log a drink
@MainActor
struct AddDrinkView: View {
    @Environment(\.dismiss) private var dismiss
    let nightId: UUID

    @State private var selectedType: DrinkType = .beer
    @State private var customName = ""
    @State private var customEmoji = ""
    @State private var isAdding = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NightOutSpacing.xxl) {
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
                    }

                    Spacer(minLength: NightOutSpacing.xxl)

                    // Add button
                    GlassButton(
                        "Add Drink",
                        icon: "plus",
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
        }
    }

    private func addDrink() async {
        isAdding = true
        defer { isAdding = false }

        // TODO: Save drink to Supabase
        NightOutHaptics.success()
        dismiss()
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
                Text(type.emoji)
                    .font(.system(size: 40))

                Text(type.displayName)
                    .font(NightOutTypography.caption)
                    .foregroundStyle(isSelected ? NightOutColors.chrome : NightOutColors.silver)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, NightOutSpacing.lg)
            .background(isSelected ? NightOutColors.neonPink.opacity(0.2) : NightOutColors.glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: NightOutRadius.md)
                    .stroke(isSelected ? NightOutColors.neonPink : NightOutColors.glassBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

#Preview {
    AddDrinkView(nightId: UUID())
}
