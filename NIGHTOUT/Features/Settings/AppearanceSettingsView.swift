//
//  AppearanceSettingsView.swift
//  NIGHTOUT
//
//  Theme and appearance settings
//

import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appTheme") private var appTheme = "dark"

    private let themes = [
        ("dark", "🌙", "Dark", "Classic dark theme for nightlife"),
        ("midnight", "🌌", "Midnight", "Deep black with neon accents"),
        ("neon", "💜", "Neon", "Vibrant neon-focused theme")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                NightOutColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Text("🎨")
                                .font(.system(size: 60))

                            Text("Appearance")
                                .font(NightOutTypography.title2)
                                .foregroundStyle(NightOutColors.chrome)

                            Text("Choose how NIGHTOUT looks")
                                .font(NightOutTypography.body)
                                .foregroundStyle(NightOutColors.dimmed)
                        }
                        .padding(.top, 20)

                        // Theme Options
                        VStack(spacing: 12) {
                            ForEach(themes, id: \.0) { theme in
                                ThemeOptionRow(
                                    id: theme.0,
                                    emoji: theme.1,
                                    title: theme.2,
                                    description: theme.3,
                                    isSelected: appTheme == theme.0
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        appTheme = theme.0
                                        NightOutHaptics.light()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Coming Soon
                        VStack(spacing: 8) {
                            Text("More themes coming soon!")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.dimmed)
                        }
                        .padding(.top, 20)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Appearance")
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

// MARK: - Theme Option Row
struct ThemeOptionRow: View {
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
                    .font(.system(size: 32))

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
                    .foregroundStyle(isSelected ? NightOutColors.neonPink : NightOutColors.dimmed)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: NightOutRadius.md)
                    .fill(NightOutColors.surface)
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: NightOutRadius.md)
                                .stroke(NightOutColors.neonPink, lineWidth: 1)
                        }
                    }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
}

#Preview {
    AppearanceSettingsView()
}
