import Foundation
import Supabase

/// Service for drink tracking operations
final class DrinkService: @unchecked Sendable {
    static let shared = DrinkService()

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Fetch

    /// Get all drinks for a night
    func getDrinks(nightId: UUID) async throws -> [SupabaseDrink] {
        guard let client else { throw ServiceError.notConfigured }

        let response: [SupabaseDrink] = try await client
            .from("drinks")
            .select()
            .eq("night_id", value: nightId)
            .order("timestamp", ascending: true)
            .execute()
            .value

        return response
    }

    /// Get drink by ID
    func getDrink(id: UUID) async throws -> SupabaseDrink? {
        guard let client else { throw ServiceError.notConfigured }

        let response: [SupabaseDrink] = try await client
            .from("drinks")
            .select()
            .eq("id", value: id)
            .execute()
            .value

        return response.first
    }

    // MARK: - Create

    /// Add a drink to a night
    func addDrink(
        nightId: UUID,
        type: DrinkType,
        customName: String? = nil,
        customEmoji: String? = nil
    ) async throws -> SupabaseDrink {
        guard let client else { throw ServiceError.notConfigured }

        let insert = SupabaseDrinkInsert(
            nightId: nightId,
            type: type,
            customName: customName,
            customEmoji: customEmoji
        )

        let response: [SupabaseDrink] = try await client
            .from("drinks")
            .insert(insert)
            .select()
            .execute()
            .value

        guard let drink = response.first else {
            throw ServiceError.invalidData
        }

        return drink
    }

    // MARK: - Delete

    /// Delete a drink
    func deleteDrink(id: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }

        try await client
            .from("drinks")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    /// Delete all drinks for a night
    func deleteDrinksForNight(nightId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }

        try await client
            .from("drinks")
            .delete()
            .eq("night_id", value: nightId)
            .execute()
    }

    // MARK: - Stats

    /// Get drink count for a night
    func getDrinkCount(nightId: UUID) async throws -> Int {
        let drinks = try await getDrinks(nightId: nightId)
        return drinks.count
    }

    /// Get total standard drinks for a night
    func getStandardDrinks(nightId: UUID) async throws -> Double {
        let drinks = try await getDrinks(nightId: nightId)
        return drinks.reduce(0) { total, drink in
            let drinkType = DrinkType(rawValue: drink.type) ?? .custom
            return total + drinkType.standardDrinks
        }
    }
}
