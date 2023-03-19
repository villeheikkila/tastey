import SwiftUI

struct VerificationScreen: View {
  @StateObject private var viewModel: ViewModel
  @EnvironmentObject private var router: Router
  @EnvironmentObject private var hapticManager: HapticManager

  init(_ client: Client) {
    _viewModel = StateObject(wrappedValue: ViewModel(client))
  }

  var body: some View {
    List {
      switch viewModel.verificationType {
      case .products:
        unverifiedProducts
      case .companies:
        unverifiedCompanies
      case .brands:
        unverifiedBrands
      case .subBrands:
        unverifiedSubBrands
      }
    }
    .listStyle(.plain)
    .sheet(item: $viewModel.editProduct, content: { editProduct in
      NavigationStack {
        DismissableSheet(title: "Edit Product") {
          AddProductView(viewModel.client, mode: .edit(editProduct), onEdit: {
            viewModel.onEditProduct()
          })
        }
      }
    })
    .confirmationDialog("Delete Product Confirmation",
                        isPresented: $viewModel.showDeleteProductConfirmationDialog,
                        presenting: viewModel.deleteProduct)
    { presenting in
      Button(
        "Delete \(presenting.getDisplayName(.fullName)) Product",
        role: .destructive,
        action: { viewModel.deleteProduct(onDelete: {
          hapticManager.trigger(.notification(.success))
          router.removeLast()
        })
        }
      )
    }
    .navigationBarTitle("Unverified \(viewModel.verificationType.label)")
    .toolbar {
      toolbarContent
    }
    .onChange(of: viewModel.verificationType, perform: { _ in
      Task {
        await viewModel.loadData()
      }
    })
    .refreshable {
      await hapticManager.wrapWithHaptics {
        await viewModel.refreshData()
      }
    }
    .task {
      await viewModel.loadData()
    }
  }

  private var unverifiedCompanies: some View {
    ForEach(viewModel.companies) { company in
      RouteLink(to: .company(company)) {
        Text(company.name)
      }
      .swipeActions {
        Button(action: { viewModel.verifyCompany(company) }, label: {
          Label("Verify", systemImage: "checkmark")
        }).tint(.green)
      }
    }
  }

  private var unverifiedSubBrands: some View {
    HStack {}
  }

  private var unverifiedBrands: some View {
    ForEach(viewModel.brands) { brand in
      RouteLink(to: .brand(brand)) {
        HStack {
          Text("\(brand.brandOwner.name): \(brand.name)")
          Spacer()
          Text("(\(brand.getNumberOfProducts()))")
        }
      }
      .swipeActions {
        Button(action: { viewModel.verifyBrand(brand) }, label: {
          Label("Verify", systemImage: "checkmark")
        }).tint(.green)
      }
    }
  }

  private var unverifiedProducts: some View {
    ForEach(viewModel.products) { product in
      VStack {
        if let createdBy = product.createdBy {
          HStack {
            AvatarView(avatarUrl: createdBy.avatarUrl, size: 16, id: createdBy.id)
            Text(createdBy.preferredName).font(.caption).bold()
            Spacer()
            // swiftlint:disable force_try
            if let createdAt = product.createdAt, let date = try! Date(timestamptzString: createdAt) {
              Text(date.customFormat(.relativeTime)).font(.caption).bold()
            }
          }
        }
        ProductItemView(product: product)
          .contentShape(Rectangle())
          .accessibilityAddTraits(.isLink)
          .onTapGesture {
            router.navigate(to: .product(product), resetStack: false)
          }
          .swipeActions {
            Button(action: { viewModel.verifyProduct(product) }, label: {
              Label("Verify", systemImage: "checkmark")
            }).tint(.green)
            Button(action: { viewModel.editProduct = product }, label: {
              Label("Edit", systemImage: "pencil")
            }).tint(.yellow)
            Button(role: .destructive, action: { viewModel.deleteProduct = product }, label: {
              Label("Delete", systemImage: "trash")
            })
          }
      }
    }
  }

  private var toolbarContent: some ToolbarContent {
    ToolbarTitleMenu {
      ForEach(VerificationType.allCases) { type in
        Button {
          viewModel.verificationType = type
        } label: {
          Text("Unverified \(type.label)")
        }
      }
    }
  }
}