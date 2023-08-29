import Foundation
import Models
import Supabase

public protocol ReportRepository {
    func insert(report: Report.NewRequest) async -> Result<Void, Error>
}

public struct SupabaseReportRepository: ReportRepository {
    let client: SupabaseClient

    public func insert(report: Report.NewRequest) async -> Result<Void, Error> {
        do {
            try await client
                .database
                .from(.reports)
                .insert(values: report, returning: .none)
                .execute()

            return .success(())
        } catch {
            return .failure(error)
        }
    }
}