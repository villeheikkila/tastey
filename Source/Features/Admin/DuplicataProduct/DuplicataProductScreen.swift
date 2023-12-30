import Components
import EnvironmentModels
import Extensions
import Models
import OSLog
import Repositories
import SwiftUI

@MainActor
struct DuplicateProductScreen: View {
    private let logger = Logger(category: "ProductVerificationScreen")
    @Environment(\.repository) private var repository
    @Environment(Router.self) private var router
    @Environment(FeedbackEnvironmentModel.self) private var feedbackEnvironmentModel
    @State private var products = [Product.Joined]()
    @State private var alertError: AlertError?
    @State private var deleteProduct: Product.Joined? {
        didSet {
            showDeleteProductConfirmationDialog = true
        }
    }

    @State private var showDeleteProductConfirmationDialog = false

    var body: some View {
        List(products) { product in
            VStack {
                if let createdBy = product.createdBy {
                    HStack {
                        AvatarView(avatarUrl: createdBy.avatarUrl, size: 16, id: createdBy.id)
                        Text(createdBy.preferredName).font(.caption).bold()
                        Spacer()
                        if let createdAt = product.createdAt, let date = Date(timestamptzString: createdAt) {
                            Text(date.customFormat(.relativeTime)).font(.caption).bold()
                        }
                    }
                }
                ProductItemView(product: product)
                    .contentShape(Rectangle())
                    .accessibilityAddTraits(.isLink)
                    .onTapGesture {
                        router.navigate(screen: .product(product))
                    }
                    .swipeActions {
                        ProgressButton("Verify", systemImage: "checkmark", action: { await verifyProduct(product) })
                            .tint(.green)
                        RouterLink("Edit", systemImage: "pencil", sheet: .productEdit(product: product, onEdit: {
                            await loadProducts()
                        })).tint(.yellow)
                        Button(
                            "Delete",
                            systemImage: "trash",
                            role: .destructive,
                            action: { deleteProduct = product }
                        )
                    }
            }
        }
        .listStyle(.plain)
        .alertError($alertError)
        .confirmationDialog("Are you sure you want to delete the product and all of its check-ins?",
                            isPresented: $showDeleteProductConfirmationDialog,
                            titleVisibility: .visible,
                            presenting: deleteProduct)
        { presenting in
            ProgressButton(
                "Delete \(presenting.getDisplayName(.fullName))",
                role: .destructive,
                action: { await deleteProduct(presenting) }
            )
        }
        .navigationBarTitle("Unverified Products")
        #if !targetEnvironment(macCatalyst)
            .refreshable {
                await loadProducts(withHaptics: true)
            }
        #endif
            .task {
                    await loadProducts()
                }
    }

    func verifyProduct(_ product: Product.Joined) async {
        switch await repository.product.verification(id: product.id, isVerified: true) {
        case .success:
            withAnimation {
                products.remove(object: product)
            }
        case let .failure(error):
            guard !error.isCancelled else { return }
            alertError = .init()
            logger.error("Failed to verify product \(product.id). Error: \(error) (\(#file):\(#line))")
        }
    }

    func deleteProduct(_ product: Product.Joined) async {
        switch await repository.product.delete(id: product.id) {
        case .success:
            feedbackEnvironmentModel.trigger(.notification(.success))
            router.removeLast()
        case let .failure(error):
            guard !error.isCancelled else { return }
            alertError = .init()
            logger.error("Failed to delete product \(product.id). Error: \(error) (\(#file):\(#line))")
        }
    }

    func loadProducts(withHaptics: Bool = false) async {
        if withHaptics {
            feedbackEnvironmentModel.trigger(.impact(intensity: .low))
        }
        switch await repository.product.getUnverified() {
        case let .success(products):
            withAnimation {
                self.products = products
            }
            if withHaptics {
                feedbackEnvironmentModel.trigger(.notification(.success))
            }

        case let .failure(error):
            guard !error.isCancelled else { return }
            alertError = .init()
            logger.error("fetching flavors failed. Error: \(error) (\(#file):\(#line))")
        }
    }
}
