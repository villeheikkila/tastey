import Components

import Extensions
import Logging
import Models
import Repositories
import SwiftUI

struct BrandPickerSheet: View {
    private let logger = Logger(label: "BrandPickerSheet")
    @Environment(Repository.self) private var repository
    @Environment(ProfileModel.self) private var profileModel
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var brandsWithSubBrands = [Brand.JoinedSubBrands]()
    @State private var brandName = ""
    @State private var searchTerm: String = ""

    @Binding var brand: Brand.JoinedSubBrands?

    let brandOwner: any CompanyProtocol
    let mode: Mode

    private var filteredBrands: [Brand.JoinedSubBrands] {
        brandsWithSubBrands.filteredBySearchTerm(by: \.name, searchTerm: searchTerm)
    }

    private var showContentUnavailableView: Bool {
        !searchTerm.isEmpty && filteredBrands.isEmpty
    }

    var body: some View {
        List(filteredBrands) { brand in
            BrandSheetRowView(brand: brand) { brand in
                self.brand = brand
                dismiss()
            }
        }
        .listStyle(.plain)
        .foregroundColor(.primary)
        .safeAreaInset(edge: .bottom) {
            if profileModel.hasPermission(.canCreateBrands) {
                Form {
                    Section("brand.addBrandForCompany.title \(brandOwner.name)") {
                        ScanTextFieldView(title: "brand.name.placeholder", text: $brandName)
                        AsyncButton("labels.create", action: { await createNewBrand() })
                            .disabled(!brandName.isValidLength(.normal(allowEmpty: false)))
                    }
                    .customListRowBackground()
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollContentBackground(.hidden)
                .background(.ultraThinMaterial)
                .frame(height: 150)
                .clipShape(.rect(cornerRadius: 8))
                .padding()
            }
        }
        .overlay {
            ContentUnavailableView.search(text: searchTerm)
                .opacity(showContentUnavailableView ? 1 : 0)
        }
        .navigationTitle(mode.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchTerm, placement: .navigationBarDrawer(displayMode: .always))
        .toolbar {
            toolbarContent
        }
        .task {
            await loadBrands(brandOwner)
        }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarDismissAction()
    }

    private func loadBrands(_ brandOwner: any CompanyProtocol) async {
        do {
            let brandsWithSubBrands = try await repository.brand.getByBrandOwnerId(id: brandOwner.id)
            self.brandsWithSubBrands = brandsWithSubBrands
        } catch {
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Failed to load brands for \(brandOwner.id). Error: \(error) (\(#file):\(#line))")
        }
    }

    private func createNewBrand() async {
        do {
            let brandWithSubBrands = try await repository.brand.insert(newBrand: Brand.NewRequest(name: brandName, brandOwnerId: brandOwner.id))
            router.open(.toast(.success("brand.created.toast")))
            if case let .new(onCreate) = mode {
                onCreate(brandWithSubBrands)
            }
            brand = brandWithSubBrands
            dismiss()
        } catch {
            guard !error.isCancelled else { return }
            guard !error.isDuplicate else {
                router.open(.toast(.warning("labels.duplicate.toast")))
                return
            }
            router.open(.alert(.init()))
            logger.error("Failed to create new brand for \(brandOwner.id). Error: \(error) (\(#file):\(#line))")
        }
    }
}

extension BrandPickerSheet {
    enum Mode: Sendable, Hashable {
        case select, new(onCreate: @MainActor (_ brand: Brand.JoinedSubBrands) -> Void)

        var navigationTitle: LocalizedStringKey {
            switch self {
            case .new:
                "brand.add.navigationTitle"
            case .select:
                "brand.select.navigationTitle"
            }
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .select:
                hasher.combine("select")
            case .new:
                hasher.combine("new")
            }
        }

        static func == (lhs: Mode, rhs: Mode) -> Bool {
            switch (lhs, rhs) {
            case (.select, .select):
                true
            case (.new, .new):
                true
            default:
                false
            }
        }
    }
}
