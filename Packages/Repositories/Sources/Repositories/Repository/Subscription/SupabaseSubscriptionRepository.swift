import Foundation
import Models
import Supabase

struct SupabaseSubscriptionRepository: SubscriptionRepository {
    let client: SupabaseClient

    func getActiveGroup() async -> Result<SubscriptionGroup.Joined, Error> {
        do {
            let response: SubscriptionGroup.Joined = try await client
                .database
                .from(.subscriptionGroups)
                .select(SubscriptionGroup.getQuery(.joined(false)))
                .eq("is_active", value: true)
                .limit(1)
                .single()
                .execute()
                .value

            return .success(response)
        } catch {
            return .failure(error)
        }
    }
}
