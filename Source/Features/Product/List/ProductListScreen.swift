
import Extensions
import Models
import Logging
import Repositories
import SwiftUI

struct ProductListScreen: View {
    let products: [Product.Joined]

    var body: some View {
        List(products) { product in
            ProductListRowView(product: product)
        }
        .listStyle(.plain)
        .verificationBadgeVisibility(.visible)
        .navigationTitle("product.list.navigationTitle")
    }
}
