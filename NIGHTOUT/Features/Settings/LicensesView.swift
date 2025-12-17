//
//  LicensesView.swift
//  NIGHTOUT
//
//  Open source licenses and attributions
//

import SwiftUI

struct LicensesView: View {
    @Environment(\.dismiss) private var dismiss

    private let licenses = [
        License(
            name: "Supabase Swift",
            url: "https://github.com/supabase/supabase-swift",
            license: "MIT License",
            description: "Swift client for Supabase"
        ),
        License(
            name: "SwiftUI",
            url: "https://developer.apple.com/xcode/swiftui/",
            license: "Apple SDK License",
            description: "Apple's UI framework"
        ),
        License(
            name: "MapKit",
            url: "https://developer.apple.com/documentation/mapkit/",
            license: "Apple SDK License",
            description: "Apple's mapping framework"
        ),
        License(
            name: "AVFoundation",
            url: "https://developer.apple.com/av-foundation/",
            license: "Apple SDK License",
            description: "Audio and video framework"
        ),
        License(
            name: "CoreLocation",
            url: "https://developer.apple.com/documentation/corelocation",
            license: "Apple SDK License",
            description: "Location services framework"
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                NightOutColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Text("📜")
                                .font(.system(size: 60))

                            Text("Open Source Licenses")
                                .font(NightOutTypography.title2)
                                .foregroundStyle(NightOutColors.chrome)

                            Text("NIGHTOUT uses the following open source software")
                                .font(NightOutTypography.body)
                                .foregroundStyle(NightOutColors.dimmed)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        .padding(.horizontal)

                        // Licenses List
                        VStack(spacing: 12) {
                            ForEach(licenses) { license in
                                LicenseRow(license: license)
                            }
                        }
                        .padding(.horizontal)

                        // Thank You
                        VStack(spacing: 8) {
                            Text("❤️")
                                .font(.system(size: 32))
                            Text("Thank you to all open source contributors!")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.dimmed)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Licenses")
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

// MARK: - License Model
struct License: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    let license: String
    let description: String
}

// MARK: - License Row
struct LicenseRow: View {
    let license: License

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(license.name)
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.silver)

                Spacer()

                Text(license.license)
                    .font(NightOutTypography.caption)
                    .foregroundStyle(NightOutColors.electricBlue)
            }

            Text(license.description)
                .font(NightOutTypography.caption)
                .foregroundStyle(NightOutColors.dimmed)

            if let url = URL(string: license.url) {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.system(size: 12))
                        Text("View Source")
                            .font(NightOutTypography.caption)
                    }
                    .foregroundStyle(NightOutColors.neonPink)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: NightOutRadius.md)
                .fill(NightOutColors.surface)
        }
    }
}

#Preview {
    LicensesView()
}
