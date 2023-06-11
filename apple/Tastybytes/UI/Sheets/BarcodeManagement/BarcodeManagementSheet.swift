import OSLog
import SwiftUI

struct BarcodeManagementSheet: View {
    private let logger = Logger(category: "BarcodeManagementSheet")
    @Environment(Repository.self) private var repository
    @Environment(FeedbackManager.self) private var feedbackManager
    @Environment(\.dismiss) private var dismiss
    @State private var barcodes: [ProductBarcode.JoinedWithCreator] = []

    let product: Product.Joined

    var body: some View {
        Form {
            ForEach(barcodes) { barcode in
                BarcodeManagementRow(barcode: barcode)
                    .swipeActions {
                        ProgressButton("Delete", systemSymbol: .trashFill, role: .destructive, action: {
                            await deleteBarcode(barcode)
                            feedbackManager.trigger(.notification(.success))
                        })
                    }
                    .contextMenu {
                        ProgressButton("Delete", systemSymbol: .trashFill, role: .destructive, action: {
                            await deleteBarcode(barcode)
                            feedbackManager.trigger(.notification(.success))
                        })
                    }
            }
        }
        .task {
            await getBarcodes()
        }
        .navigationTitle("Barcodes")
        .toolbar {
            toolbarContent
        }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .cancellationAction) {
            Button("Done", role: .cancel, action: { dismiss() })
        }
    }

    func deleteBarcode(_ barcode: ProductBarcode.JoinedWithCreator) async {
        switch await repository.productBarcode.delete(id: barcode.id) {
        case .success:
            await MainActor.run {
                withAnimation {
                    barcodes.remove(object: barcode)
                }
            }
        case let .failure(error):
            guard !error.localizedDescription.contains("cancelled") else { return }
            feedbackManager.toggle(.error(.unexpected))
            logger.error("Failed to fetch barcodes for product. Error: \(error) (\(#file):\(#line))")
        }
    }

    func getBarcodes() async {
        switch await repository.productBarcode.getByProductId(id: product.id) {
        case let .success(barcodes):
            await MainActor.run {
                withAnimation {
                    self.barcodes = barcodes
                }
            }
        case let .failure(error):
            guard !error.localizedDescription.contains("cancelled") else { return }
            feedbackManager.toggle(.error(.unexpected))
            logger.error("Failed to fetch barcodes for product. Error: \(error) (\(#file):\(#line))")
        }
    }
}

struct BarcodeManagementRow: View {
    let barcode: ProductBarcode.JoinedWithCreator

    var body: some View {
        HStack {
            AvatarView(avatarUrl: barcode.profile.avatarUrl, size: 32, id: barcode.profile.id)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(barcode.profile.preferredName).font(.caption)
                    Spacer()
                    Text(barcode.createdAt.customFormat(.relativeTime)).font(.caption2)
                }
                Text(barcode.barcode).font(.callout)
            }
            Spacer()
        }
    }
}
