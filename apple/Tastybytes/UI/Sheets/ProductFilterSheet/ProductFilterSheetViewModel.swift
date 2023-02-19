import SwiftUI

extension ProductFilterSheetView {
  enum Sections {
    case category, checkIns, sortBy
  }

  @MainActor class ViewModel: ObservableObject {
    private let logger = getLogger(category: "SeachFilterSheetView")
    let client: Client
    @Published var categories: [Category.JoinedSubcategories] = []
    @Published var categoryFilter: Category.JoinedSubcategories?
    @Published var subcategoryFilter: Subcategory?
    @Published var sortBy: Product.Filter.SortBy?
    @Published var onlyNonCheckedIn: Bool = false

    init(_ client: Client, initialFilter: Product.Filter?) {
      self.client = client
      subcategoryFilter = initialFilter?.subcategory
      categoryFilter = initialFilter?.category
      onlyNonCheckedIn = initialFilter?.onlyNonCheckedIn ?? false
      sortBy = initialFilter?.sortBy
    }

    func loadCategories() async {
      switch await client.category.getAllWithSubcategories() {
      case let .success(categories):
        self.categories = categories
      case let .failure(error):
        logger.error("failed to load categories: \(error.localizedDescription)")
      }
    }

    func getFilter() -> Product.Filter? {
      if categoryFilter != nil || subcategoryFilter != nil || onlyNonCheckedIn == true || sortBy != nil {
        return Product.Filter(
          category: categoryFilter,
          subcategory: subcategoryFilter,
          onlyNonCheckedIn: onlyNonCheckedIn,
          sortBy: sortBy
        )
      } else {
        return nil
      }
    }

    func resetFilter() {
      withAnimation {
        categoryFilter = nil
        subcategoryFilter = nil
        onlyNonCheckedIn = false
        categoryFilter = nil
        sortBy = nil
      }
    }
  }
}
