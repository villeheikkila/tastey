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
    @Environment(AppEnvironmentModel.self) private var appEnvironmentModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteBrandConfirmationDialog = false
    @State private var name: String
    @State private var brandOwner: Company
    @State private var brand: Brand.JoinedSubBrandsProductsCompany
    @State private var newCompanyName = ""
    @State private var selectedLogo: PhotosPickerItem?

    let onUpdate: BrandUpdateCallback
    let initialBrandOwner: Company

    init(
        brand: Brand.JoinedSubBrandsProductsCompany,
        onUpdate: @escaping BrandUpdateCallback
    ) {
        self.onUpdate = onUpdate
        initialBrandOwner = brand.brandOwner
        _brand = State(wrappedValue: brand)
        _brandOwner = State(wrappedValue: brand.brandOwner)
        _name = State(wrappedValue: brand.name)
    }

    var body: some View {
        Form {
            Section("brand.admin.section.brand") {
                HStack {
                    Text(brand.name)
                }
            }

            Section("brand.edit.name.title") {
                TextField("brand.edit.name.placeholder", text: $name)
                ProgressButton("labels.edit") {
                    await editBrand { updatedBrand in
                        await onUpdate(updatedBrand)
                    }
                }.disabled(!name.isValidLength(.normal) || brand.name == name)
            }
            
            CreationInfoView(createdBy: brand.createdBy, createdAt: brand.createdAt)

            Section("brand.edit.brandOwner.title") {
                RouterLink(brandOwner.name, open: .sheet(.companySearch(onSelect: { company in
                    brandOwner = company
                })))
                ProgressButton("brand.edit.brandOwner.label") {
                    await editBrand { updatedBrand in
                        await onUpdate(updatedBrand)
                    }
                }.disabled(brandOwner.id == initialBrandOwner.id)
            }

            EditLogoSection(logos: brand.logos, onUpload: { imageData in
                await uploadLogo(data: imageData)
            }, onDelete: { imageEntity in
                await deleteLogo(entity: imageEntity)
            })

            if profileEnvironmentModel.hasRole(.admin) {
                Section("labels.info") {
                    LabeledContent("labels.id", value: "\(brand.id)")
                        .textSelection(.enabled)
                    LabeledContent("verification.verified.label", value: "\(brand.isVerified)".capitalized)
                }
            }

            Section {
                Button(
                    "labels.delete",
                    systemImage: "trash.fill",
                    role: .destructive,
                    action: { showDeleteBrandConfirmationDialog = true }
                )
                .foregroundColor(.red)
                .disabled(brand.isVerified)
                .confirmationDialog(
                    "brand.delete.disclaimer",
                    isPresented: $showDeleteBrandConfirmationDialog,
                    titleVisibility: .visible,
                    presenting: brand
                ) { presenting in
                    ProgressButton(
                        "brand.delete.label \(presenting.name)", role: .destructive,
                        action: {
                            await deleteBrand(presenting)
                        }
                    )
                }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("brand.admin.navigationTitle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .initialTask {
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

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarDismissAction()
    }
    
    func loadData() async {
        switch await repository.brand.getDetailed(id: brand.id) {
        case let .success(brand):
            self.brand = brand
        case let .failure(error):
            guard !error.isCancelled else { return }
            logger.error("Failed to edit brand. Error: \(error) (\(#file):\(#line))")
        }
    }

    func editBrand(onSuccess: @escaping BrandUpdateCallback) async {
        switch await repository.brand.update(updateRequest: .init(id: brand.id, name: name, brandOwnerId: brandOwner.id)) {
        case let .success(brand):
            router.open(.toast(.success("brand.edit.success.toast")))
            self.brand = brand
            await onSuccess(brand)
        case let .failure(error):
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Failed to edit brand. Error: \(error) (\(#file):\(#line))")
        }
    }

    func uploadLogo(data: Data) async {
        switch await repository.brand.uploadLogo(brandId: brand.id, data: data) {
        case let .success(imageEntity):
            withAnimation {
                brand = brand.copyWith(logos: brand.logos + [imageEntity])
            }
            logger.info("Succesfully uploaded logo \(imageEntity.file)")
            await onUpdate(brand)
        case let .failure(error):
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Uploading of a brand logo failed. Error: \(error) (\(#file):\(#line))")
        }
    }

    func deleteLogo(entity: ImageEntity) async {
        switch await repository.imageEntity.delete(from: .brandLogos, entity: entity) {
        case .success:
            withAnimation {
                brand = brand.copyWith(logos: brand.logos.removing(entity))
            }
        case let .failure(error):
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Failed to delete image. Error: \(error) (\(#file):\(#line))")
        }
    }

    func deleteBrand(_ brand: Brand.JoinedSubBrandsProductsCompany) async {
        switch await repository.brand.delete(id: brand.id) {
        case .success:
            dismiss()
        case let .failure(error):
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Failed to delete brand. Error: \(error) (\(#file):\(#line))")
        }
    }
}
