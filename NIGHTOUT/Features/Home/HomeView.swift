import SwiftUI
import Auth

/// Home feed showing friends' nights
@MainActor
struct HomeView: View {
    @State private var nights: [SupabaseNight] = []
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingView()
                } else if nights.isEmpty {
                    EmptyStateView(
                        icon: "moon.zzz",
                        title: "No Nights Yet",
                        message: "Add friends to see their nights here, or start tracking your own!",
                        actionTitle: "Find Friends"
                    ) {
                        // TODO: Navigate to friends
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: NightOutSpacing.lg) {
                            ForEach(nights) { night in
                                NavigationLink {
                                    NightDetailView(nightId: night.id)
                                } label: {
                                    NightCardView(night: night)
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                            }
                        }
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)
                        .padding(.vertical, NightOutSpacing.lg)
                    }
                    .refreshable {
                        await loadFeed()
                    }
                }
            }
            .nightOutBackground()
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(NightOutColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .task {
            await loadFeed()
        }
    }

    private func loadFeed() async {
        guard let userId = SessionManager.shared.currentUser?.id else {
            isLoading = false
            return
        }

        do {
            nights = try await NightService.shared.getFeed(userId: userId, limit: 50)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }
}

#Preview {
    HomeView()
}
