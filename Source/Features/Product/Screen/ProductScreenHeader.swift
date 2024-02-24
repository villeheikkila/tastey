import Components
import EnvironmentModels
import Extensions
import Models
import OSLog
import Repositories
import SwiftUI

@MainActor
struct ProductScreenHeader: View {
    let product: Product.Joined
    let summary: Summary?
    let checkInImages: [ImageEntity.JoinedCheckIn]
    let isLoadingCheckInImages = false
    let loadMoreImages: () -> Void
    let onRefreshCheckIns: () -> Void
    @Binding var isOnWishlist: Bool
    
    var productItemViewExtras: Set<ProductItemView.Extra> {
         product.logos.isEmpty ? [.companyLink] : [.companyLink, .logoOnRight]
    }

    var body: some View {
        ProductItemView(product: product, extras: productItemViewExtras)
        SummaryView(summary: summary)
        ProductScreenActionSection(
            isOnWishlist: $isOnWishlist,
            product: product,
            onRefreshCheckIns: onRefreshCheckIns
        )
        if !checkInImages.isEmpty {
            ProfileCheckInImagesSection(
                checkInImages: checkInImages,
                isLoading: isLoadingCheckInImages,
                onLoadMore: loadMoreImages
            )
        }
    }
}
