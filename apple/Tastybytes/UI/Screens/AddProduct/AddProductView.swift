import SwiftUI

struct ProductSheetView: View {
  @EnvironmentObject private var router: Router
  @EnvironmentObject private var toastManager: ToastManager
  @StateObject private var viewModel: ViewModel
  @FocusState private var focusedField: Focusable?

  let onEdit: (() -> Void)?

  init(
    _ client: Client,
    mode: Mode,
    initialBarcode: Barcode? = nil,
    onEdit: (() -> Void)? = nil
  ) {
    _viewModel = StateObject(wrappedValue: ViewModel(client, mode: mode, barcode: initialBarcode))
    self.onEdit = onEdit
  }

  var body: some View {
    List {
      categorySection
      brandSection
      productSection

      Button(viewModel.mode.doneLabel, action: {
        switch viewModel.mode {
        case .editSuggestion:
          viewModel.createProductEditSuggestion(onComplete: {
            toastManager.toggle(.success("Edit suggestion sent!"))
          })
        case .edit:
          viewModel.editProduct(onComplete: {
            if let onEdit {
              onEdit()
            }
          })
        case .new, .addToBrand:
          viewModel.createProduct(onCreation: {
            product in router.navigate(to: .product(product), resetStack: false)
          })
        }
      })
      .disabled(!viewModel.isValid())
    }
    .navigationTitle(viewModel.mode.navigationTitle)
    .sheet(item: $viewModel.activeSheet) { sheet in
      NavigationStack {
        switch sheet {
        case .subcategories:
          if let subcategoriesForCategory = viewModel.category?.subcategories {
            SubcategorySheetView(
              subcategories: $viewModel.subcategories,
              availableSubcategories: subcategoriesForCategory,
              onCreate: {
                newSubcategoryName in viewModel.createSubcategory(newSubcategoryName: newSubcategoryName)
              }
            )
          }
        case .brandOwner:
          CompanySearchSheet(viewModel.client, onSelect: { company, createdNew in
            viewModel.setBrandOwner(company)
            if createdNew {
              toastManager.toggle(.success(viewModel.getToastText(.createdCompany)))
            }
            viewModel.dismissSheet()
          })
        case .brand:
          if let brandOwner = viewModel.brandOwner {
            BrandSheetView(viewModel.client, brandOwner: brandOwner, mode: .select, onSelect: { brand, createdNew in
              if createdNew {
                toastManager.toggle(.success(viewModel.getToastText(.createdSubBrand)))
              }
              viewModel.setBrand(brand: brand)
            })
          }

        case .subBrand:
          if let brand = viewModel.brand {
            SubBrandSheetView(viewModel.client, brandWithSubBrands: brand, onSelect: { subBrand, createdNew in
              if createdNew {
                toastManager.toggle(.success(viewModel.getToastText(.createdSubBrand)))
              }
              viewModel.subBrand = subBrand
              viewModel.dismissSheet()

            })
          }
        case .barcode:
          BarcodeScannerSheetView(onComplete: {
            barcode in viewModel.barcode = barcode
          })
        }
      }.if(sheet == .barcode, transform: { view in view.presentationDetents([.medium]) })
    }
    .task {
      viewModel.loadMissingData()
    }
  }

  private var categorySection: some View {
    Section {
      if !viewModel.categories.isEmpty {
        Picker("Category", selection: $viewModel.categoryName) {
          ForEach(viewModel.categories.map(\.name)) { category in
            Text(category.label).tag(category)
          }
        }
        .onChange(of: viewModel.category) { _ in
          withAnimation {
            viewModel.subcategories.removeAll()
          }
        }
      }

      Button(action: {
        viewModel.setActiveSheet(.subcategories)
      }) {
        HStack {
          if viewModel.subcategories.isEmpty {
            Text("Subcategories")
          } else {
            HStack { ForEach(viewModel.subcategories) { subcategory in
              ChipView(title: subcategory.name)
            }}
          }
        }
      }
    }
    header: {
      Text("Category")
        .onTapGesture {
          self.focusedField = nil
        }
    }
    .headerProminence(.increased)
  }

  private var brandSection: some View {
    Section {
      Button(action: {
        viewModel.setActiveSheet(.brandOwner)
      }) {
        Text(viewModel.brandOwner?.name ?? "Company")
      }

      if viewModel.brandOwner != nil {
        Button(action: {
          viewModel.setActiveSheet(.brand)
        }) {
          Text(viewModel.brand?.name ?? "Brand")
        }
        .disabled(viewModel.brandOwner == nil)
      }

      if viewModel.brand != nil {
        Toggle("Has sub-brand?", isOn: $viewModel.hasSubBrand)
      }

      if viewModel.hasSubBrand {
        Button(action: {
          viewModel.setActiveSheet(.subBrand)
        }) {
          Text(viewModel.subBrand?.name ?? "Sub-brand")
        }
        .disabled(viewModel.brand == nil)
      }

    } header: {
      Text("Brand")
        .onTapGesture {
          self.focusedField = nil
        }
    }
    .headerProminence(.increased)
  }

  private var productSection: some View {
    Section {
      TextField("Name", text: $viewModel.name)
        .focused($focusedField, equals: .name)

      TextField("Description (optional)", text: $viewModel.description)
        .focused($focusedField, equals: .description)

      if viewModel.mode == .new {
        Button(action: {
          viewModel.setActiveSheet(.barcode)
        }) {
          if viewModel.barcode != nil {
            Text("Barcode Added!")
          } else {
            Text("Add Barcode")
          }
        }
      }
    } header: {
      Text("Product")
        .onTapGesture {
          self.focusedField = nil
        }
    }
    .headerProminence(.increased)
  }
}