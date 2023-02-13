import SwiftUI

extension BrandSheetView {
  enum Mode {
    case select, new
  }

  @MainActor class ViewModel: ObservableObject {
    private let logger = getLogger(category: "BrandSheetView")
    let client: Client
    @Published var searchText = ""
    @Published var brandsWithSubBrands = [Brand.JoinedSubBrands]()
    @Published var brandName = ""
    let mode: Mode

    init(_ client: Client, mode: Mode) {
      self.client = client
      self.mode = mode
    }

    func loadBrands(_ brandOwner: Company) {
      Task {
        switch await client.brand.getByBrandOwnerId(brandOwnerId: brandOwner.id) {
        case let .success(brandsWithSubBrands):
          self.brandsWithSubBrands = brandsWithSubBrands
        case let .failure(error):
          logger.error("failed to load brands for \(brandOwner.id): \(error.localizedDescription)")
        }
      }
    }

    func createNewBrand(_ brandOwner: Company, _ onCreation: @escaping (_ brand: Brand.JoinedSubBrands) -> Void) {
      Task {
        switch await client.brand.insert(newBrand: Brand.NewRequest(name: brandName, brandOwnerId: brandOwner.id)) {
        case let .success(brandWithSubBrands):
          onCreation(brandWithSubBrands)
        case let .failure(error):
          logger
            .error(
              """
              failed to create new brand for \(brandOwner.id)\
                 with name \(self.brandName): \(error.localizedDescription)
              """
            )
        }
      }
    }
  }
}