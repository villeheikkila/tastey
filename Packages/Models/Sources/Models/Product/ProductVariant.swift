public struct ProductVariant: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let manufacturer: Company

    enum CodingKeys: String, CodingKey {
        case id
        case manufacturer = "companies"
    }
}

public extension ProductVariant {
    static func getQuery(_ queryType: QueryType) -> String {
        let tableName = Database.Table.productVariants.rawValue
        let saved = "id"

        switch queryType {
        case let .joined(withTableName):
            return queryWithTableName(tableName, [saved, Company.getQuery(.saved(true))].joinComma(), withTableName)
        }
    }

    enum QueryType {
        case joined(_ withTableName: Bool)
    }
}