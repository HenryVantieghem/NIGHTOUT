//
//  SupabaseBlockedUser.swift
//  NIGHTOUT
//
//  Codable model for Supabase blocked_users table
//

import Foundation

struct SupabaseBlockedUser: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let blockedUserId: UUID
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case blockedUserId = "blocked_user_id"
        case createdAt = "created_at"
    }
}
