//
//  BlockUserView.swift
//  NIGHTOUT
//
//  Block user confirmation sheet
//

import SwiftUI

struct BlockUserView: View {
    let userId: UUID
    let username: String
    let displayName: String
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var isBlocking = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                NightOutColors.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Warning Icon
                    Text("🚫")
                        .font(.system(size: 60))
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("Block \(displayName)?")
                            .font(NightOutTypography.title2)
                            .foregroundStyle(NightOutColors.chrome)
                        
                        Text("@\(username)")
                            .font(NightOutTypography.body)
                            .foregroundStyle(NightOutColors.dimmed)
                    }
                    
                    // Explanation
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When you block someone:")
                            .font(NightOutTypography.headline)
                            .foregroundStyle(NightOutColors.chrome)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BlockFeatureRow(text: "They won't be able to see your nights or interact with you")
                            BlockFeatureRow(text: "You won't see their nights or content in your feed")
                            BlockFeatureRow(text: "They won't be notified that you blocked them")
                            BlockFeatureRow(text: "You can unblock them anytime in settings")
                        }
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: NightOutRadius.lg)
                            .fill(NightOutColors.surface)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Actions
                    VStack(spacing: 12) {
                        GlassButton(
                            isBlocking ? "Blocking..." : "Block User",
                            style: .prominent,
                            size: .large
                        ) {
                            blockUser()
                        }
                        .disabled(isBlocking)
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Cancel")
                                .font(NightOutTypography.headline)
                                .foregroundStyle(NightOutColors.silver)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
                .padding(.top, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(NightOutColors.silver)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private func blockUser() {
        guard !isBlocking else { return }
        
        isBlocking = true
        NightOutHaptics.medium()
        
        Task {
            do {
                try await ModerationService.shared.blockUser(userId: userId)
                
                await MainActor.run {
                    isBlocking = false
                    NightOutHaptics.success()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isBlocking = false
                    errorMessage = "Failed to block user: \(error.localizedDescription)"
                    showError = true
                    NightOutHaptics.error()
                }
            }
        }
    }
}

// MARK: - Block Feature Row
struct BlockFeatureRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(NightOutTypography.body)
                .foregroundStyle(NightOutColors.dimmed)
            
            Text(text)
                .font(NightOutTypography.body)
                .foregroundStyle(NightOutColors.silver)
            
            Spacer()
        }
    }
}

#Preview {
    BlockUserView(
        userId: UUID(),
        username: "johndoe",
        displayName: "John Doe"
    )
}
