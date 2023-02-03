import SwiftUI

struct ProductScreenView: View {
  @StateObject private var viewModel: ViewModel
  @EnvironmentObject private var profileManager: ProfileManager
  @State private var scrollToTop: Int = 0

  init(product: Product.Joined) {
    _viewModel = StateObject(wrappedValue: ViewModel(product: product))
  }

  var body: some View {
    CheckInListView(
      fetcher: .product(viewModel.product),
      scrollToTop: $scrollToTop,
      resetView: $viewModel.resetView,
      onRefresh: {
        viewModel.refresh()
      }
    ) {
      productInfo
      if let summary = viewModel.summary, summary.averageRating != nil {
        Section {
          SummaryView(summary: summary)
        }
      }
    }
    .task {
      viewModel.loadProductSummary()
    }
    .navigationBarItems(
      trailing: Menu {
        Button(action: {
          viewModel.setActiveSheet(.checkIn)
        }) {
          Text("Check-in!").bold(
          )
        }.disabled(!profileManager.hasPermission(.canCreateCheckIns))

        ShareLink("Share", item: NavigatablePath.product(id: viewModel.product.id).url)
        Divider()

        if profileManager.hasPermission(.canEditCompanies) {
          Button(action: {
            viewModel.setActiveSheet(.editProduct)
          }) {
            Label("Edit", systemImage: "pencil")
          }
        } else {
          Button(action: {
            viewModel.setActiveSheet(.editSuggestion)
          }) {
            Label("Edit Suggestion", systemImage: "pencil")
          }
        }

        if viewModel.product.isVerified {
          Label("Verified", systemImage: "checkmark.circle")
        } else if profileManager.hasPermission(.canVerify) {
          Button(action: {
            viewModel.verifyProduct()
          }) {
            Label("Verify product", systemImage: "checkmark")
          }
        } else {
          Label("Not verified", systemImage: "x.circle")
        }

        if profileManager.hasPermission(.canDeleteProducts) {
          Button(action: {
            viewModel.showDeleteConfirmation()
          }) {
            Label("Delete", systemImage: "trash.fill")
              .disabled(viewModel.product.isVerified)
          }
        }
      } label: {
        Image(systemName: "ellipsis")
      }
    )
    .sheet(item: $viewModel.activeSheet) { sheet in
      NavigationStack {
        switch sheet {
        case .checkIn:
          CheckInSheetView(product: viewModel.product, onCreation: {
            _ in viewModel.refreshCheckIns()
          })
        case .editSuggestion:
          ProductSheetView(mode: .editSuggestion, initialProduct: viewModel.product)
        case .editProduct:
          ProductSheetView(mode: .edit, initialProduct: viewModel.product, onEdit: {
            viewModel.onEditCheckIn()
          })
        }
      }
    }
    .confirmationDialog("Delete Product Confirmation",
                        isPresented: $viewModel.showDeleteProductConfirmationDialog,
                        presenting: viewModel.product) { presenting in
      Button(
        "Delete \(presenting.getDisplayName(.fullName)) Product",
        role: .destructive,
        action: { viewModel.deleteProduct()
        }
      )
    }
  }

  private var productInfo: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(viewModel.product.getDisplayName(.fullName))
          .font(.system(size: 18, weight: .bold, design: .default))
          .foregroundColor(.primary)

        if let description = viewModel.product.description {
          Text(description)
            .font(.system(size: 12, weight: .medium, design: .default))
        }

        HStack {
          NavigationLink(value: Route.company(viewModel.product.subBrand.brand.brandOwner)) {
            Text(viewModel.product.getDisplayName(.brandOwner))
              .font(.system(size: 16, weight: .bold, design: .default))
              .foregroundColor(.secondary)
          }
        }

        HStack {
          CategoryNameView(category: viewModel.product.category)

          ForEach(viewModel.product.subcategories, id: \.id) { subcategory in
            ChipView(title: subcategory.name, cornerRadius: 5)
          }
        }
      }.padding([.leading, .trailing], 10)
      Spacer()
    }
  }
}

extension ProductScreenView {
  enum Sheet: Identifiable {
    var id: Self { self }
    case checkIn
    case editSuggestion
    case editProduct
  }

  @MainActor class ViewModel: ObservableObject {
    @Published var product: Product.Joined
    @Published var activeSheet: Sheet?
    @Published var summary: Summary?
    @Published var showDeleteProductConfirmationDialog = false
    @Published var resetView: Int = 0

    init(product: Product.Joined) {
      self.product = product
    }

    func setActiveSheet(_ sheet: Sheet) {
      activeSheet = sheet
    }

    func showDeleteConfirmation() {
      showDeleteProductConfirmationDialog.toggle()
    }

    func onEditCheckIn() {
      activeSheet = nil
      refresh()
      refreshCheckIns()
    }

    func refresh() {
      Task {
        switch await repository.product.getById(id: product.id) {
        case let .success(refreshedProduct):
          withAnimation {
            product = refreshedProduct
            print(refreshedProduct)
          }
        case let .failure(error):
          print(error)
        }
      }
    }

    func refreshCheckIns() {
      resetView += 1 // TODO: get rid of this hack 29.1.2023
    }

    func loadProductSummary() {
      Task {
        switch await repository.product.getSummaryById(id: product.id) {
        case let .success(summary):
          self.summary = summary
        case let .failure(error):
          print(error)
        }
      }
    }

    func verifyProduct() {
      Task {
        switch await repository.product.verifyProduct(productId: product.id) {
        case .success:
          print("Verified")
        case let .failure(error):
          print(error)
        }
      }
    }

    func deleteProduct() {
      Task {
        switch await repository.product.delete(id: product.id) {
        case .success:
          print("TODO HANDLE THIS!!")
        case let .failure(error):
          print(error)
        }
      }
    }
  }
}