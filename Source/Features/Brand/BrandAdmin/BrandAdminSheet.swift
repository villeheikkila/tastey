import Components
import EnvironmentModels
import Extensions
import Models
import OSLog
import PhotosUI
import Repositories
import SwiftUI

struct BrandAdminSheet: View {
    typealias BrandUpdateCallback = (_ updatedBrand: Brand.JoinedSubBrandsProductsCompany) async -> Void
    private let logger = Logger(category: "BrandAdminSheet")
    @Environment(Repository.self) private var repository
    @Environment(Router.self) private var router
    @Environment(ProfileEnvironmentModel.self) private var profileEnvironmentModel
    @Environment(\.dismiss) private var dismiss
    @State private var state: ScreenState = .loading
    @State private var showDeleteBrandConfirmationDialog = false
    @State private var name: String = ""
    @State private var brandOwner: Company?
    @State private var brand = Brand.Detailed()
    @State private var newCompanyName = ""
    @State private var selectedLogo: PhotosPickerItem?

    let id: Brand.Id
    let onUpdate: BrandUpdateCallback
    let onDelete: BrandUpdateCallback

    private var isValidNameUpdate: Bool {
        name.isValidLength(.normal(allowEmpty: false)) && brand.name != name
    }

    private var isValidBrandOwnerUpdate: Bool {
        if let brandOwner {
            brandOwner.id == brand.brandOwner.id
        } else {
            false
        }
    }

    private var isValidUpdate: Bool {
        isValidNameUpdate || isValidBrandOwnerUpdate
    }

    var body: some View {
        Form {
            if state.isPopulated {
                content
            }
        }
        .scrollContentBackground(.hidden)
        .animation(.default, value: brand)
        .navigationTitle("brand.admin.navigationTitle")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            ScreenStateOverlayView(state: state) {
                await loadData()
            }
        }
        .toolbar {
            toolbarContent
        }
        .task {
            await loadData()
        }
        .task(id: selectedLogo) {
            guard let selectedLogo else { return }
            guard let data = await selectedLogo.getJPEG() else {
                logger.error("Failed to convert image to JPEG")
                return
            }
            await uploadLogo(data: data)
        }
    }

    @ViewBuilder private var content: some View {
        Section("brand.admin.section.brand") {
            RouterLink(open: .screen(.brand(.init(brand: brand)))) {
                BrandEntityView(brand: brand)
            }
        }
        .customListRowBackground()
        ModificationInfoView(modificationInfo: brand)
        Section("admin.section.details") {
            LabeledTextFieldView(title: "brand.admin.changeName.label", text: $name)
            LabeledContent("brand.admin.changeBrandOwner.label") {
                RouterLink(brandOwner?.name ?? "", open: .sheet(.companyPicker(onSelect: { company in
                    brandOwner = company
                })))
            }
        }
        .customListRowBackground()
        EditLogoSection(logos: brand.logos, onUpload: uploadLogo, onDelete: deleteLogo)
        Section("labels.info") {
            LabeledIdView(id: brand.id.rawValue.formatted())
            LabeledContent("brand.admin.subBrand.count", value: brand.subBrands.count.formatted())
            LabeledContent("brand.admin.products.count", value: brand.subBrands.reduce(0) { result, subBrand in
                result + subBrand.products.count
            }.formatted())
            VerificationAdminToggleView(isVerified: brand.isVerified, action: verifyBrand)
        }
        .customListRowBackground()
        Section {
            RouterLink(
                "admin.section.reports.title",
                systemImage: "exclamationmark.bubble",
                count: brand.reports.count,
                open: .screen(
                    .reports(reports: $brand.map(getter: { location in
                        location.reports
                    }, setter: { reports in
                        brand.copyWith(reports: reports)
                    }))
                )
            )
            RouterLink("admin.section.editSuggestions.title", systemImage: "square.and.pencil", count: brand.editSuggestions.unresolvedCount, open: .screen(.brandEditSuggestionAdmin(brand: $brand)))
        }
        .customListRowBackground()
        Section {
            ConfirmedDeleteButtonView(
                presenting: brand,
                action: deleteBrand,
                description: "brand.delete.disclaimer",
                label: "brand.delete.label \(brand.name)",
                isDisabled: brand.isVerified
            )
        }
        .customListRowBackground()
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarDismissAction()
        ToolbarItem(placement: .primaryAction) {
            AsyncButton("labels.edit") {
                await editBrand(brand: brand)
            }
            .disabled(!isValidUpdate)
        }
    }

    private func loadData() async {
        do {
            let brand = try await repository.brand.getDetailed(id: id)
            withAnimation {
                self.brand = brand
                brandOwner = brand.brandOwner
                name = brand.name
                state = .populated
            }
        } catch {
            guard !error.isCancelled else { return }
            state = .error([error])
            logger.error("Failed to load detailed brand info. Error: \(error) (\(#file):\(#line))")
        }
    }

    private func verifyBrand(isVerified: Bool) async {
        do {
            try await repository.brand.verification(id: brand.id, isVerified: isVerified)
            brand = brand.copyWith(isVerified: isVerified)
        } catch {
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Failed to verify brand'. Error: \(error) (\(#file):\(#line))")
        }
    }

    private func editBrand(brand: Brand.Detailed) async {
        do {
            let brand = try await repository.brand.update(
                updateRequest: .init(
                    id: id,
                    name: isValidNameUpdate ? name : brand.name,
                    brandOwnerId: isValidBrandOwnerUpdate ? brandOwner?.id : nil
                )
            )
            router.open(.toast(.success("brand.edit.success.toast")))
            self.brand = brand
            await onUpdate(.init(brand: brand))
        } catch {
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Failed to edit brand. Error: \(error) (\(#file):\(#line))")
        }
    }

    private func uploadLogo(data: Data) async {
        do {
            let imageEntity = try await repository.brand.uploadLogo(brandId: brand.id, data: data)
            withAnimation {
                brand = brand.copyWith(logos: brand.logos + [imageEntity])
            }
            logger.info("Succesfully uploaded logo \(imageEntity.file)")
            await onUpdate(.init(brand: brand))
        } catch {
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Uploading of a brand logo failed. Error: \(error) (\(#file):\(#line))")
        }
    }

    private func deleteLogo(entity: ImageEntity) async {
        do {
            try await repository.imageEntity.delete(from: .brandLogos, entity: entity)
            withAnimation {
                brand = brand.copyWith(logos: brand.logos.removing(entity))
            }
        } catch {
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Failed to delete image. Error: \(error) (\(#file):\(#line))")
        }
    }

    private func deleteBrand(_ brand: Brand.Detailed) async {
        do {
            try await repository.brand.delete(id: brand.id)
            await onDelete(.init(brand: brand))
            dismiss()
        } catch {
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Failed to delete brand. Error: \(error) (\(#file):\(#line))")
        }
    }
}
