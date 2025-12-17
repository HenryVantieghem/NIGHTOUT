import Foundation
import Supabase

/// Service for group nights (multiple friends tracking together)
final class GroupService: @unchecked Sendable {
    static let shared = GroupService()

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Groups

    /// Create a new group
    /// - Parameters:
    ///   - name: Group name
    ///   - description: Optional group description
    ///   - iconEmoji: Optional emoji icon
    /// - Returns: Created group
    @discardableResult
    func createGroup(name: String, description: String? = nil, iconEmoji: String? = nil) async throws -> Group {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let group = GroupInsert(
            name: name,
            description: description,
            iconEmoji: iconEmoji ?? "🎉",
            createdBy: userId
        )

        let response: [Group] = try await client
            .from("groups")
            .insert(group)
            .select()
            .execute()
            .value

        guard let created = response.first else {
            throw ServiceError.invalidData
        }

        // Add creator as admin member
        try await addMember(groupId: created.id, userId: userId, role: .admin)

        return created
    }

    /// Get all groups for current user
    /// - Returns: Array of groups the user is a member of
    func getMyGroups() async throws -> [Group] {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        // Get group IDs from memberships
        let memberships: [GroupMembershipRecord] = try await client
            .from("group_members")
            .select("group_id")
            .eq("user_id", value: userId)
            .execute()
            .value

        let groupIds = memberships.map { $0.groupId }

        guard !groupIds.isEmpty else { return [] }

        // Get groups
        let groups: [Group] = try await client
            .from("groups")
            .select()
            .in("id", values: groupIds)
            .order("created_at", ascending: false)
            .execute()
            .value

        return groups
    }

    /// Get a specific group
    /// - Parameter id: Group ID
    /// - Returns: Group or nil if not found
    func getGroup(id: UUID) async throws -> Group? {
        guard let client else { throw ServiceError.notConfigured }

        let groups: [Group] = try await client
            .from("groups")
            .select()
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value

        return groups.first
    }

    /// Update a group
    /// - Parameters:
    ///   - groupId: Group ID
    ///   - name: New name
    ///   - description: New description
    ///   - iconEmoji: New icon emoji
    func updateGroup(groupId: UUID, name: String? = nil, description: String? = nil, iconEmoji: String? = nil) async throws {
        guard let client else { throw ServiceError.notConfigured }

        var updates: [String: Any] = [:]
        if let name { updates["name"] = name }
        if let description { updates["description"] = description }
        if let iconEmoji { updates["icon_emoji"] = iconEmoji }

        guard !updates.isEmpty else { return }

        try await client
            .from("groups")
            .update(updates)
            .eq("id", value: groupId)
            .execute()
    }

    /// Delete a group (admin only)
    /// - Parameter groupId: Group ID
    func deleteGroup(groupId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }

        // First delete all members
        try await client
            .from("group_members")
            .delete()
            .eq("group_id", value: groupId)
            .execute()

        // Then delete the group
        try await client
            .from("groups")
            .delete()
            .eq("id", value: groupId)
            .execute()
    }

    // MARK: - Group Members

    /// Add a member to a group
    /// - Parameters:
    ///   - groupId: Group ID
    ///   - userId: User ID to add
    ///   - role: Member role (default: member)
    func addMember(groupId: UUID, userId: UUID, role: GroupRole = .member) async throws {
        guard let client else { throw ServiceError.notConfigured }

        let member = GroupMemberInsert(
            groupId: groupId,
            userId: userId,
            role: role.rawValue
        )

        try await client
            .from("group_members")
            .insert(member)
            .execute()
    }

    /// Remove a member from a group
    /// - Parameters:
    ///   - groupId: Group ID
    ///   - userId: User ID to remove
    func removeMember(groupId: UUID, userId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }

        try await client
            .from("group_members")
            .delete()
            .eq("group_id", value: groupId)
            .eq("user_id", value: userId)
            .execute()
    }

    /// Get all members of a group
    /// - Parameter groupId: Group ID
    /// - Returns: Array of group members
    func getMembers(groupId: UUID) async throws -> [GroupMember] {
        guard let client else { throw ServiceError.notConfigured }

        let members: [GroupMember] = try await client
            .from("group_members")
            .select()
            .eq("group_id", value: groupId)
            .order("joined_at", ascending: true)
            .execute()
            .value

        return members
    }

    /// Update a member's role
    /// - Parameters:
    ///   - groupId: Group ID
    ///   - userId: User ID
    ///   - role: New role
    func updateMemberRole(groupId: UUID, userId: UUID, role: GroupRole) async throws {
        guard let client else { throw ServiceError.notConfigured }

        try await client
            .from("group_members")
            .update(["role": role.rawValue])
            .eq("group_id", value: groupId)
            .eq("user_id", value: userId)
            .execute()
    }

    /// Check if current user is a member of a group
    /// - Parameter groupId: Group ID
    /// - Returns: True if user is a member
    func isMember(groupId: UUID) async throws -> Bool {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let members: [GroupMember] = try await client
            .from("group_members")
            .select()
            .eq("group_id", value: groupId)
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value

        return !members.isEmpty
    }

    /// Check if current user is admin of a group
    /// - Parameter groupId: Group ID
    /// - Returns: True if user is admin
    func isAdmin(groupId: UUID) async throws -> Bool {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let members: [GroupMember] = try await client
            .from("group_members")
            .select()
            .eq("group_id", value: groupId)
            .eq("user_id", value: userId)
            .eq("role", value: GroupRole.admin.rawValue)
            .limit(1)
            .execute()
            .value

        return !members.isEmpty
    }

    // MARK: - Invitations

    /// Invite friends to a group
    /// - Parameters:
    ///   - groupId: Group ID
    ///   - userIds: Array of user IDs to invite
    func inviteMembers(groupId: UUID, userIds: [UUID]) async throws {
        for userId in userIds {
            try await addMember(groupId: groupId, userId: userId, role: .invited)
        }
    }

    /// Accept group invitation
    /// - Parameter groupId: Group ID
    func acceptInvitation(groupId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        try await client
            .from("group_members")
            .update(["role": GroupRole.member.rawValue])
            .eq("group_id", value: groupId)
            .eq("user_id", value: userId)
            .eq("role", value: GroupRole.invited.rawValue)
            .execute()
    }

    /// Decline group invitation
    /// - Parameter groupId: Group ID
    func declineInvitation(groupId: UUID) async throws {
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        try await removeMember(groupId: groupId, userId: userId)
    }

    /// Get pending invitations for current user
    /// - Returns: Array of groups with pending invitations
    func getPendingInvitations() async throws -> [Group] {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        // Get group IDs from invited memberships
        let memberships: [GroupMembershipRecord] = try await client
            .from("group_members")
            .select("group_id")
            .eq("user_id", value: userId)
            .eq("role", value: GroupRole.invited.rawValue)
            .execute()
            .value

        let groupIds = memberships.map { $0.groupId }

        guard !groupIds.isEmpty else { return [] }

        // Get groups
        let groups: [Group] = try await client
            .from("groups")
            .select()
            .in("id", values: groupIds)
            .execute()
            .value

        return groups
    }

    // MARK: - Group Nights

    /// Link a night to a group (group night)
    /// - Parameters:
    ///   - nightId: Night ID
    ///   - groupId: Group ID
    func linkNightToGroup(nightId: UUID, groupId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }

        try await client
            .from("nights")
            .update(["group_id": groupId.uuidString])
            .eq("id", value: nightId)
            .execute()
    }

    /// Get nights for a group
    /// - Parameters:
    ///   - groupId: Group ID
    ///   - limit: Maximum number of nights
    /// - Returns: Array of nights associated with the group
    func getGroupNights(groupId: UUID, limit: Int = 20) async throws -> [SupabaseNight] {
        guard let client else { throw ServiceError.notConfigured }

        let nights: [SupabaseNight] = try await client
            .from("nights")
            .select()
            .eq("group_id", value: groupId)
            .order("start_time", ascending: false)
            .limit(limit)
            .execute()
            .value

        return nights
    }
}

// MARK: - Types

enum GroupRole: String, CaseIterable, Sendable {
    case admin = "admin"
    case member = "member"
    case invited = "invited"
}

// MARK: - DTOs

private struct GroupInsert: Encodable, Sendable {
    let name: String
    let description: String?
    let iconEmoji: String
    let createdBy: UUID

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case iconEmoji = "icon_emoji"
        case createdBy = "created_by"
    }
}

struct Group: Codable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let description: String?
    let iconEmoji: String
    let createdBy: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case iconEmoji = "icon_emoji"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

private struct GroupMemberInsert: Encodable, Sendable {
    let groupId: UUID
    let userId: UUID
    let role: String

    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case userId = "user_id"
        case role
    }
}

struct GroupMember: Codable, Identifiable, Sendable {
    let id: UUID
    let groupId: UUID
    let userId: UUID
    let role: String
    let joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
    }

    var memberRole: GroupRole {
        GroupRole(rawValue: role) ?? .member
    }

    var isAdmin: Bool {
        memberRole == .admin
    }

    var isInvited: Bool {
        memberRole == .invited
    }
}

private struct GroupMembershipRecord: Decodable {
    let groupId: UUID

    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
    }
}
