import Foundation
import Models

public protocol ProductRepository: Sendable {
    func search(searchTerm: String, filter: Product.Filter?) async throws -> [Product.Joined]
    func search(barcode: Barcode) async throws -> [Product.Joined]
    func getById(id: Product.Id) async throws -> Product.Joined
    func getDetailed(id: Product.Id) async throws -> Product.Detailed
    func getByProfile(id: Profile.Id) async throws -> [Product.Joined]
    func getFeed(_ type: Product.FeedType, from: Int, to: Int, categoryFilterId: Models.Category.Id?) async throws -> [Product.Joined]
    func delete(id: Product.Id) async throws
    func create(newProductParams: Product.NewRequest) async throws -> Product.Joined
    func getUnverified() async throws -> [Product.Joined]
    func checkIfOnWishlist(id: Product.Id) async throws -> Bool
    func removeFromWishlist(productId: Product.Id) async throws
    func getWishlistItems(profileId: Profile.Id) async throws -> [ProfileWishlist.Joined]
    func addToWishlist(productId: Product.Id) async throws
    func uploadLogo(productId: Product.Id, data: Data) async throws -> ImageEntity
    func getSummaryById(id: Product.Id) async throws -> Summary
    func getCreatedByUserId(id: Profile.Id) async throws -> [Product.Joined]
    func mergeProducts(productId: Product.Id, toProductId: Product.Id) async throws
    func markAsDuplicate(productId: Product.Id, duplicateOfProductId: Product.Id) async throws
    func editProduct(productEditParams: Product.EditRequest) async throws -> Product.Joined
    func createUpdateSuggestion(productEditSuggestionParams: Product.EditSuggestionRequest) async throws
    func verification(id: Product.Id, isVerified: Bool) async throws
    func deleteEditSuggestion(editSuggestion: Product.EditSuggestion) async throws
    func resolveEditSuggestion(editSuggestion: Product.EditSuggestion) async throws
    func getEditSuggestions() async throws -> [Product.EditSuggestion]
}
