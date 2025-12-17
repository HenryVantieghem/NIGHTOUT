import Foundation
import Supabase

/// Service for comment operations
final class CommentService: @unchecked Sendable {
    static let shared = CommentService()

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Fetch

    /// Get comments for a night
    func getComments(nightId: UUID) async throws -> [SupabaseComment] {
        guard let client else { throw ServiceError.notConfigured }

        let response: [SupabaseComment] = try await client
            .from("comments")
            .select()
            .eq("night_id", value: nightId)
            .order("timestamp", ascending: true)
            .execute()
            .value

        return response
    }

    /// Get comments with author profiles
    func getCommentsWithAuthors(nightId: UUID) async throws -> [CommentWithAuthor] {
        let comments = try await getComments(nightId: nightId)

        var result: [CommentWithAuthor] = []
        for comment in comments {
            let author = try? await UserService.shared.getProfile(userId: comment.authorId)
            result.append(CommentWithAuthor(comment: comment, author: author))
        }

        return result
    }

    /// Get comment count for a night
    func getCommentCount(nightId: UUID) async throws -> Int {
        let comments = try await getComments(nightId: nightId)
        return comments.count
    }

    // MARK: - Create

    /// Add a comment to a night
    func addComment(nightId: UUID, text: String) async throws -> SupabaseComment {
        guard let client else { throw ServiceError.notConfigured }

        let insert = SupabaseCommentInsert(nightId: nightId, text: text)

        let response: [SupabaseComment] = try await client
            .from("comments")
            .insert(insert)
            .select()
            .execute()
            .value

        guard let comment = response.first else {
            throw ServiceError.invalidData
        }

        return comment
    }

    // MARK: - Update

    /// Edit a comment
    func editComment(id: UUID, text: String) async throws {
        guard let client else { throw ServiceError.notConfigured }

        try await client
            .from("comments")
            .update(["text": text, "edited_at": Date().ISO8601Format()])
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Delete

    /// Delete a comment
    func deleteComment(id: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }

        try await client
            .from("comments")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
