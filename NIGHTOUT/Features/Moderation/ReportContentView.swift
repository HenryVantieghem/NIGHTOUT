//
//  ReportContentView.swift
//  NIGHTOUT
//
//  Report content (night, comment, profile, media)
//

import SwiftUI

enum ReportType: String, CaseIterable {
    case night = "night"
    case comment = "comment"
    case profile = "profile"
    case media = "media"
    
    var displayName: String {
        switch self {
        case .night: return "Night Post"
        case .comment: return "Comment"
        case .profile: return "Profile"
        case .media: return "Media"
        }
    }
}

enum ReportReason: String, CaseIterable {
    case spam = "spam"
    case harassment = "harassment"
    case inappropriate = "inappropriate"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .spam: return "Spam"
        case .harassment: return "Harassment"
        case .inappropriate: return "Inappropriate Content"
        case .other: return "Other"
        }
    }
}

struct ReportContentView: View {
    let reportType: ReportType
    let reportedUserId: UUID?
    let nightId: UUID?
    let commentId: UUID?
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedReason: ReportReason = .spam
    @State private var description: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                NightOutColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Report \(reportType.displayName)")
                                .font(NightOutTypography.title2)
                                .foregroundStyle(NightOutColors.chrome)
                            
                            Text("Help us keep NIGHTOUT safe by reporting content that violates our community guidelines.")
                                .font(NightOutTypography.body)
                                .foregroundStyle(NightOutColors.dimmed)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)
                        
                        // Reason Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("REASON")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.dimmed)
                            
                            VStack(spacing: 2) {
                                ForEach(ReportReason.allCases, id: \.self) { reason in
                                    Button(action: {
                                        NightOutHaptics.light()
                                        selectedReason = reason
                                    }) {
                                        HStack {
                                            Text(reason.displayName)
                                                .font(NightOutTypography.body)
                                                .foregroundStyle(NightOutColors.chrome)
                                            
                                            Spacer()
                                            
                                            if selectedReason == reason {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(NightOutColors.partyPurple)
                                            } else {
                                                Circle()
                                                    .stroke(NightOutColors.dimmed, lineWidth: 2)
                                                    .frame(width: 20, height: 20)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background {
                                            RoundedRectangle(cornerRadius: NightOutRadius.md)
                                                .fill(NightOutColors.surface)
                                                .overlay {
                                                    if selectedReason == reason {
                                                        RoundedRectangle(cornerRadius: NightOutRadius.md)
                                                            .stroke(NightOutColors.partyPurple.opacity(0.5), lineWidth: 1)
                                                    }
                                                }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Description Field
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ADDITIONAL DETAILS (Optional)")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.dimmed)
                            
                            TextField("Provide more information...", text: $description, axis: .vertical)
                                .font(NightOutTypography.body)
                                .foregroundStyle(NightOutColors.chrome)
                                .padding(16)
                                .frame(minHeight: 100, alignment: .topLeading)
                                .background {
                                    RoundedRectangle(cornerRadius: NightOutRadius.md)
                                        .fill(NightOutColors.surface)
                                }
                        }
                        .padding(.horizontal)
                        
                        // Submit Button
                        GlassButton(
                            isSubmitting ? "Submitting..." : "Submit Report",
                            style: .prominent,
                            size: .large
                        ) {
                            submitReport()
                        }
                        .disabled(isSubmitting)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
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
            .alert("Report Submitted", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for helping keep NIGHTOUT safe. We'll review your report.")
            }
        }
    }
    
    private func submitReport() {
        guard !isSubmitting else { return }
        
        isSubmitting = true
        NightOutHaptics.medium()
        
        Task {
            do {
                _ = try await ModerationService.shared.reportContent(
                    type: reportType.rawValue,
                    reason: selectedReason.rawValue,
                    description: description.isEmpty ? nil : description,
                    reportedUserId: reportedUserId,
                    nightId: nightId,
                    commentId: commentId
                )
                
                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                    NightOutHaptics.success()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "Failed to submit report: \(error.localizedDescription)"
                    showError = true
                    NightOutHaptics.error()
                }
            }
        }
    }
}

#Preview {
    ReportContentView(
        reportType: .night,
        reportedUserId: UUID(),
        nightId: UUID(),
        commentId: nil
    )
}
