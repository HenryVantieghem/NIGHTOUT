import SwiftUI
import MapKit

/// Sheet to check in to a venue
@MainActor
struct AddVenueView: View {
    @Environment(\.dismiss) private var dismiss
    let nightId: UUID

    @State private var searchText = ""
    @State private var selectedVenue: MKMapItem?
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var isCheckinIn = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: NightOutSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(NightOutColors.dimmed)

                    TextField("Search venues...", text: $searchText)
                        .foregroundStyle(NightOutColors.chrome)
                        .autocorrectionDisabled()

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(NightOutColors.dimmed)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                }
                .padding(NightOutSpacing.md)
                .background(NightOutColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
                .padding(.horizontal, NightOutSpacing.screenHorizontal)
                .padding(.vertical, NightOutSpacing.md)

                // Results
                if isSearching {
                    Spacer()
                    ProgressView()
                        .tint(NightOutColors.neonPink)
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    EmptyStateView(
                        icon: "mappin.slash",
                        title: "No Results",
                        message: "Try a different search term"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: NightOutSpacing.sm) {
                            ForEach(searchResults, id: \.self) { item in
                                VenueRow(
                                    item: item,
                                    isSelected: selectedVenue == item
                                ) {
                                    selectedVenue = item
                                    NightOutHaptics.light()
                                }
                            }
                        }
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)
                        .padding(.vertical, NightOutSpacing.md)
                    }
                }

                // Check in button
                if selectedVenue != nil {
                    GlassButton(
                        "Check In",
                        icon: "mappin.circle.fill",
                        style: .primary,
                        size: .large,
                        isLoading: isCheckinIn
                    ) {
                        Task { await checkIn() }
                    }
                    .padding(.horizontal, NightOutSpacing.screenHorizontal)
                    .padding(.bottom, NightOutSpacing.lg)
                }
            }
            .nightOutBackground()
            .navigationTitle("Check In")
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
            .onChange(of: searchText) { _, newValue in
                Task { await search(query: newValue) }
            }
        }
    }

    private func search(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            searchResults = response.mapItems
        } catch {
            print("Search error: \(error)")
            searchResults = []
        }
    }

    private func checkIn() async {
        guard selectedVenue != nil else { return }

        isCheckinIn = true
        defer { isCheckinIn = false }

        // TODO: Save venue to Supabase
        NightOutHaptics.success()
        dismiss()
    }
}

// MARK: - Venue Row
@MainActor
struct VenueRow: View {
    let item: MKMapItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: NightOutSpacing.md) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? NightOutColors.neonPink : NightOutColors.silver)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name ?? "Unknown")
                        .font(NightOutTypography.headline)
                        .foregroundStyle(NightOutColors.chrome)

                    // Use address components (placemark.title deprecated in iOS 26)
                    let addressComponents = [
                        item.placemark.thoroughfare,
                        item.placemark.locality
                    ].compactMap { $0 }
                    if !addressComponents.isEmpty {
                        Text(addressComponents.joined(separator: ", "))
                            .font(NightOutTypography.caption)
                            .foregroundStyle(NightOutColors.silver)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(NightOutColors.neonPink)
                }
            }
            .padding(NightOutSpacing.md)
            .background(isSelected ? NightOutColors.neonPink.opacity(0.1) : NightOutColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

#Preview {
    AddVenueView(nightId: UUID())
}
