struct Category: Identifiable, Decodable, Hashable {
  let id: Int
  let name: String

  var label: String {
    name.replacingOccurrences(of: "_", with: " ").capitalized
  }

  enum CodingKeys: String, CodingKey {
    case id
    case name
  }
}

extension Category {
  static func getQuery(_ queryType: QueryType) -> String {
    let tableName = "categories"
    let saved = "id, name"

    switch queryType {
    case .tableName:
      return tableName
    case let .saved(withTableName):
      return queryWithTableName(tableName, saved, withTableName)
    case let .joinedSubcategories(withTableName):
      return queryWithTableName(tableName, joinWithComma(saved, Subcategory.getQuery(.saved(true))), withTableName)
    case let .joinedServingStyles(withTableName):
      return queryWithTableName(tableName, joinWithComma(saved, ServingStyle.getQuery(.saved(true))), withTableName)
    case let .joinedSubcaategoriesServingStyles(withTableName):
      return queryWithTableName(
        tableName,
        joinWithComma(saved, Subcategory.getQuery(.saved(true)), ServingStyle.getQuery(.saved(true))),
        withTableName
      )
    }
  }

  enum QueryType {
    case tableName
    case saved(_ withTableName: Bool)
    case joinedSubcategories(_ withTableName: Bool)
    case joinedServingStyles(_ withTableName: Bool)
    case joinedSubcaategoriesServingStyles(_ withTableName: Bool)
  }
}

extension Category {
  struct JoinedSubcategories: Identifiable, Decodable, Hashable, Sendable {
    let id: Int
    let name: String
    let subcategories: [Subcategory]

    var label: String {
      name.replacingOccurrences(of: "_", with: " ").capitalized
    }

    enum CodingKeys: String, CodingKey {
      case id
      case name
      case subcategories
    }
  }

  struct JoinedSubcategoriesServingStyles: Identifiable, Decodable, Hashable, Sendable {
    let id: Int
    let name: String
    let subcategories: [Subcategory]
    let servingStyles: [ServingStyle]

    var label: String {
      name.replacingOccurrences(of: "_", with: " ").capitalized
    }

    enum CodingKeys: String, CodingKey {
      case id
      case name
      case subcategories
      case servingStyles = "serving_styles"
    }
  }

  struct JoinedServingStyles: Identifiable, Decodable, Hashable, Sendable {
    let id: Int
    let name: String
    let servingStyles: [ServingStyle]

    var label: String {
      name.replacingOccurrences(of: "_", with: " ").capitalized
    }

    enum CodingKeys: String, CodingKey {
      case id
      case name
      case servingStyles = "serving_styles"
    }
  }
}
