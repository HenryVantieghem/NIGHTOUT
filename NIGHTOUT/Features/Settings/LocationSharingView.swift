//
//  LocationSharingView.swift
//  NIGHTOUT
//
//  Location sharing privacy settings
//

import SwiftUI

struct LocationSharingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("locationSharing") private var locationSharing = "friends"

    private let options = [
        ("everyone", "Everyone", "All NIGHTOUT users can see your location"),
        ("friends", "Friends Only", "Only your friends can see your location"),
        ("nobody", "Nobody", "Your location is hidden from everyone")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                NightOutColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Text("📍")
                                .font(.system(size: 60))

                            Text("Location Sharing")
                                .font(NightOutTypography.title2)
                                .foregroundStyle(NightOutColors.chrome)

                            Text("Control who can see your location when you're out")
                                .font(NightOutTypography.body)
                                .foregroundStyle(NightOutColors.dimmed)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)

                        // Options
                        VStack(spacing: 8) {
                            ForEach(options, id: \.0) { option in
                                LocationOptionRow(
                                    id: option.0,
                                    title: option.1,
                                    description: option.2,
                                    isSelected: locationSharing == option.0
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        locationSharing = option.0
                                        NightOutHaptics.light()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Info Box
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(NightOutColors.electricBlue)
                                Text("Privacy Note")
                                    .font(NightOutTypography.headline)
                                    .foregroundStyle(NightOutColors.silver)
                            }

                            Text("Your location is only shared during active nights. When you end your night, location sharing stops automatically.")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.dimmed)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: NightOutRadius.md)
                                .fill(NightOutColors.surface)
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Location Sharing")
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

// MARK: - Location Option Row
struct LocationOptionRow: View {
    let id: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(NightOutTypography.body)
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
    LocationSharingView()
}
