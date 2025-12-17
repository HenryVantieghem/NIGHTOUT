import SwiftUI
import MapKit
import Auth

/// Live map showing friends who are out
@MainActor
struct LiveView: View {
    @State private var liveFriends: [SupabaseNight] = []
    @State private var isLoading = true
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            ZStack {
                // Map
                Map(position: $cameraPosition) {
                    ForEach(liveFriends) { night in
                        if let lat = night.currentLatitude, let lon = night.currentLongitude {
                            Annotation(night.currentVenueName ?? "Live", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                                LiveMarker()
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic, emphasis: .muted, pointsOfInterest: .excludingAll))
                .ignoresSafeArea(edges: .bottom)

                // Overlay content
                VStack {
                    Spacer()

                    // Live friends count
                    if !liveFriends.isEmpty {
                        HStack {
                            LiveIndicator()
                            Text("\(liveFriends.count) friend\(liveFriends.count == 1 ? "" : "s") out now")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.chrome)
                        }
                        .padding(.horizontal, NightOutSpacing.lg)
                        .padding(.vertical, NightOutSpacing.md)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, NightOutSpacing.lg)
                    } else if !isLoading {
                        GlassCard {
                            VStack(spacing: NightOutSpacing.sm) {
                                Image(systemName: "moon.zzz")
                                    .font(.system(size: 32))
                                    .foregroundStyle(NightOutColors.dimmed)

                                Text("No friends out right now")
                                    .font(NightOutTypography.body)
                                    .foregroundStyle(NightOutColors.silver)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)
                        .padding(.bottom, NightOutSpacing.lg)
                    }
                }
            }
            .navigationTitle("Live")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(NightOutColors.chrome)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }
        }
        .task {
            await loadLiveFriends()
        }
    }

    private func loadLiveFriends() async {
        guard let userId = SessionManager.shared.currentUser?.id else {
            isLoading = false
            return
        }

        do {
            liveFriends = try await NightService.shared.getLiveFriends(userId: userId)
        } catch {
            print("Error loading live friends: \(error)")
        }

        isLoading = false
    }

    private func refresh() async {
        isLoading = true
        await loadLiveFriends()
    }
}

// MARK: - Live Marker
@MainActor
struct LiveMarker: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(NightOutColors.liveRed.opacity(0.3))
                .frame(width: 40, height: 40)
                .scaleEffect(isPulsing ? 1.5 : 1.0)
                .opacity(isPulsing ? 0 : 1)

            Circle()
                .fill(NightOutColors.liveRed)
                .frame(width: 16, height: 16)

            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 16, height: 16)
        }
        .onAppear {
            withAnimation(Animation.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    LiveView()
}
