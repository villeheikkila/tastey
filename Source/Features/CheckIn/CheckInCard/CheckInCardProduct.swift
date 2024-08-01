import Components
import Models
import SwiftUI

struct CheckInCardProduct: View {
    @Environment(\.checkInCardLoadedFrom) private var checkInCardLoadedFrom
    let product: Product.Joined
    let productVariant: Product.Variant.JoinedCompany?
    let servingStyle: ServingStyle.Saved?

    var body: some View {
        RouterLink(open: .screen(.product(product.id))) {
            HStack(spacing: 4) {
                VStack(alignment: .leading, spacing: 4) {
                    CategoryView(
                        category: product.category,
                        subcategories: product.subcategories,
                        servingStyle: servingStyle
                    )

                    Text(product.formatted(.fullName))
                        .font(.headline)
                        .foregroundColor(.primary)
                        .textSelection(.enabled)

                    if let description = product.description {
                        Text(description)
                            .font(.caption)
                    }

                    HStack {
                        RouterLink(open: .screen(.company(product.subBrand.brand.brandOwner.id))) {
                            Text(product.formatted(.brandOwner))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                        }

                        if let manufacturer = productVariant?.manufacturer,
                           manufacturer.id != product.subBrand.brand.brandOwner.id
                        {
                            RouterLink(open: .screen(.company(manufacturer.id))) {
                                Text("(\(manufacturer.name))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }
                }
                if product.effectiveLogo != nil {
                    ProductLogoView(product: product, size: 48)
                }
            }
            .contentShape(.rect)
        }
        .routerLinkDisabled(checkInCardLoadedFrom == .product)
    }
}
