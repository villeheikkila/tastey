import Components
import EnvironmentModels
import Extensions
import Models
import OSLog
import Repositories
import SwiftUI

@MainActor
struct DuplicateProductSheet: View {
    private let logger = Logger(category: "DuplicateProductSheet")
    enum Mode {
        case mergeDuplicate, reportDuplicate
    }

    @Environment(Repository.self) private var repository
    @Environment(FeedbackEnvironmentModel.self) private var feedbackEnvironmentModel
    @Environment(\.dismiss) private var dismiss
    @State private var products = [Product.Joined]()
    @State private var showMergeToProductConfirmation = false
    @State private var searchTerm = ""
    @State private var alertError: AlertError?
    @State private var mergeToProduct: Product.Joined? {
        didSet {
            showMergeToProductConfirmation = true
        }
    }

    let mode: Mode
    let product: Product.Joined

    var body: some View {
        List(products) { product in
            Button(action: { mergeToProduct = product }, label: {
                HStack {
                    ProductItemView(product: product)
                    Spacer()
                }
                .contentShape(Rectangle())
            })
            .buttonStyle(.plain)
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .background {
            if products.isEmpty, mode != .reportDuplicate {
                DuplicateProductContentUnavailableView(productName: product.getDisplayName(.fullName))
            }
        }
        .searchable(text: $searchTerm, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search for a duplicate product")
        .disableAutocorrection(true)
        .navigationTitle(mode == .mergeDuplicate ? "Merge duplicates" : "Mark as duplicate")
        .toolbar {
            toolbarContent
        }
        .task(id: searchTerm, milliseconds: 200) {
            await searchProducts(name: searchTerm)
        }
        .alertError($alertError)
        .confirmationDialog("Product Merge Confirmation",
                            isPresented: $showMergeToProductConfirmation,
                            presenting: mergeToProduct)
        { presenting in
            ProgressButton(
                """
                \(mode == .mergeDuplicate ? "Merge" : "Mark") \(product.name) \(
                    mode == .mergeDuplicate ? "to" : "as duplicate of") \(presenting.getDisplayName(.fullName))
                """,
                role: .destructive
            ) {
                switch mode {
                case .reportDuplicate:
                    await reportDuplicate(presenting)
                case .mergeDuplicate:
                    await mergeProducts(presenting)
                }
            }
        }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            CloseButtonView {
                dismiss()
            }
        }
    }

    func reportDuplicate(_ to: Product.Joined) async {
        switch await repository.product.markAsDuplicate(
            productId: product.id,
            duplicateOfProductId: to.id
        ) {
        case .success:
            feedbackEnvironmentModel.trigger(.notification(.success))
            dismiss()
        case let .failure(error):
            guard !error.isCancelled else { return }
            alertError = .init()
            logger
                .error(
                    "reporting duplicate product \(product.id) of \(to.id) failed. error: \(error)"
                )
        }
    }

    func mergeProducts(_ to: Product.Joined) async {
        switch await repository.product.mergeProducts(productId: product.id, toProductId: to.id) {
        case .success:
            feedbackEnvironmentModel.trigger(.notification(.success))
            dismiss()
        case let .failure(error):
            guard !error.isCancelled else { return }
            alertError = .init()
            logger
                .error("Merging product \(product.id) to \(to.id) failed. Error: \(error) (\(#file):\(#line))")
        }
    }

    func searchProducts(name: String) async {
        guard name.count > 1 else { return }
        switch await repository.product.search(searchTerm: name, filter: nil) {
        case let .success(searchResults):
            products = searchResults.filter { $0.id != product.id }
        case let .failure(error):
            guard !error.isCancelled else { return }
            alertError = .init()
            logger.error("Searching products failed. Error: \(error) (\(#file):\(#line))")
        }
    }
}

struct DuplicateProductContentUnavailableView: View {
    let productName: String

    private var title: String {
        "Find a duplicate of\n \(productName)"
    }

    private var description: String {
        "Your request will be reviewed and products will be combined if appropriate."
    }

    private var icon: String {
        "square.filled.on.square"
    }

    var body: some View {
        ContentUnavailableView(title, image: icon, description: Text(description))
    }
}
