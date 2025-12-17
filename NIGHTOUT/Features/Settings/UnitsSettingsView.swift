//
//  UnitsSettingsView.swift
//  NIGHTOUT
//
//  Distance unit settings
//

import SwiftUI

struct UnitsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("distanceUnit") private var distanceUnit = "miles"

    private let units = [
        ("miles", "🇺🇸", "Miles", "Used in US, UK"),
        ("kilometers", "🌍", "Kilometers", "Used worldwide")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                NightOutColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Text("📏")
                                .font(.system(size: 60))

                            Text("Distance Units")
                                .font(NightOutTypography.title2)
                                .foregroundStyle(NightOutColors.chrome)

                            Text("Choose how distances are displayed")
                                .font(NightOutTypography.body)
                                .foregroundStyle(NightOutColors.dimmed)
                        }
                        .padding(.top, 20)

                        // Unit Options
                        VStack(spacing: 12) {
                            ForEach(units, id: \.0) { unit in
                                UnitOptionRow(
                                    id: unit.0,
                                    emoji: unit.1,
                                    title: unit.2,
                                    description: unit.3,
                                    isSelected: distanceUnit == unit.0
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        distanceUnit = unit.0
                                        NightOutHaptics.light()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Example
                        VStack(spacing: 12) {
                            Text("Example")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.dimmed)

                            HStack {
                                Image(systemName: "figure.walk")
                                    .foregroundStyle(NightOutColors.neonPink)
                                Text(distanceUnit == "miles" ? "1.5 miles walked" : "2.4 km walked")
                                    .font(NightOutTypography.body)
                                    .foregroundStyle(NightOutColors.silver)
                            }
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: NightOutRadius.md)
                                    .fill(NightOutColors.surface)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Units")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(NightOutColors.silver)
                }
            }
        }
    }
}

// MARK: - Unit Option Row
struct UnitOptionRow: View {
    let id: String
    let emoji: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(emoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(NightOutTypography.headline)
                        .foregroundStyle(NightOutColors.silver)

                    Text(description)
                        .font(NightOutTypography.caption)
                        .foregroundStyle(NightOutColors.dimmed)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? NightOutColors.electricBlue : NightOutColors.dimmed)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: NightOutRadius.md)
                    .fill(NightOutColors.surface)
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: NightOutRadius.md)
                                .stroke(NightOutColors.electricBlue, lineWidth: 1)
                        }
                    }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
}

#Preview {
    UnitsSettingsView()
}
