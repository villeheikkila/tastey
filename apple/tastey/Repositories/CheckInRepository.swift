import Foundation

protocol CheckInRepository {
    func loadCurrentUserActivityFeed(from: Int, to: Int) async throws -> [CheckIn]
    func loadByProfileId(id: UUID, from: Int, to: Int) async throws -> [CheckIn]
    func loadByProductId(id: Int, from: Int, to: Int) async throws -> [CheckIn]
    func createCheckIn(newCheckInParams: NewCheckInParams) async throws -> CheckIn
    func deleteById(id: Int) async throws -> Void
    func getSummaryByProfileId(id: UUID) async throws -> ProfileSummary
}

struct SupabaseCheckInRepository: CheckInRepository {
    private let database = Supabase.client.database
    private let tableName = "check_ins"
    private let checkInJoined = "id, rating, review, created_at, serving_styles (id, name), profiles (id, username, first_name, last_name, avatar_url, name_display), products (id, name, description, sub_brands (id, name, brands (id, name, companies (id, name))), subcategories (id, name, categories (id, name))), check_in_reactions (id, created_by, profiles (id, username, first_name, last_name, avatar_url, name_display)), check_in_flavors (flavors (id, name)), check_in_tagged_profiles (profiles (id, username, first_name, last_name, avatar_url, name_display)), product_variants (id, companies (id, name))"
    
    func loadCurrentUserActivityFeed(from: Int, to: Int) async throws -> [CheckIn] {
        return try await database
            .rpc(fn: "fnc__get_activity_feed")
            .select(columns: checkInJoined)
            .range(from: from, to: to)
            .execute()
            .decoded(to: [CheckIn].self)
    }
    
    func loadByProfileId(id: UUID, from: Int, to: Int) async throws -> [CheckIn] {
        return try await database
            .from(tableName)
            .select(columns: checkInJoined)
            .eq(column: "created_by", value: id.uuidString.lowercased())
            .order(column: "id", ascending: false)
            .range(from: from, to: to)
            .execute()
            .decoded(to: [CheckIn].self)
    }
    
    func loadByProductId(id: Int, from: Int, to: Int) async throws -> [CheckIn] {
        return try await database
            .from(tableName)
            .select(columns: checkInJoined)
            .eq(column: "product_id", value: id)
            .order(column: "created_at", ascending: false)
            .range(from: from, to: to)
            .execute()
            .decoded(to: [CheckIn].self)
    }
    
    func createCheckIn(newCheckInParams: NewCheckInParams) async throws -> CheckIn {
        return try await database
            .rpc(fn: "fnc__create_check_in", params: newCheckInParams)
            .select(columns: checkInJoined)
            .limit(count: 1)
            .single()
            .execute()
            .decoded(to: CheckIn.self)
    }
    
    func deleteById(id: Int) async throws -> Void {
        try await database
            .from(tableName)
            .delete()
            .eq(column: "id", value: id)
            .execute()
    }
    
    func getSummaryByProfileId(id: UUID) async throws -> ProfileSummary {
        struct GetProfileSummaryParams: Encodable {
            let p_uid: String
        }
        
        return try await database
            .rpc(fn: "fnc__get_profile_summary", params: GetProfileSummaryParams(p_uid: id.uuidString))
            .select()
            .limit(count: 1)
            .single()
            .execute()
            .decoded(to: ProfileSummary.self)
    }
}

