//
//  LanguageSettingsView.swift
//  NIGHTOUT
//
//  Language settings
//

import SwiftUI

struct LanguageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = "en"

    private let languages = [
        ("en", "🇺🇸", "English"),
        ("es", "🇪🇸", "Español"),
        ("fr", "🇫🇷", "Français"),
        ("de", "🇩🇪", "Deutsch"),
        ("it", "🇮🇹", "Italiano"),
        ("pt", "🇧🇷", "Português"),
        ("nl", "🇳🇱", "Nederlands")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                NightOutColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Text("🌍")
                                .font(.system(size: 60))

                            Text("Language")
                                .font(NightOutTypography.title2)
                                .foregroundStyle(NightOutColors.chrome)

                            Text("Choose your preferred language")
                                .font(NightOutTypography.body)
                                .foregroundStyle(NightOutColors.dimmed)
                        }
                        .padding(.top, 20)

                        // Language Options
                        VStack(spacing: 8) {
                            ForEach(languages, id: \.0) { language in
                                LanguageOptionRow(
                                    id: language.0,
                                    flag: language.1,
                                    name: language.2,
                                    isSelected: appLanguage == language.0
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        appLanguage = language.0
                                        NightOutHaptics.light()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Note
                        Text("App will restart to apply changes")
                            .font(NightOutTypography.caption)
                            .foregroundStyle(NightOutColors.dimmed)
                            .padding(.top, 12)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Language")
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

// MARK: - Language Option Row
struct LanguageOptionRow: View {
    let id: String
    let flag: String
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(flag)
                    .font(.system(size: 28))

                Text(name)
                    .font(NightOutTypography.body)
                    .foregroundStyle(NightOutColors.silver)

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
    LanguageSettingsView()
}
