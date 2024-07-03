import Components
import EnvironmentModels
import Extensions
import Models
import OSLog
import PhotosUI
import Repositories
import SwiftUI

struct EditSubBrandSheet: View {
    typealias UpdateSubBrandCallback = (_ subBrand: SubBrand.JoinedProduct) async -> Void

    private let logger = Logger(category: "EditSubBrandSheet")
    @Environment(Repository.self) private var repository
    @Environment(Router.self) private var router
    @Environment(FeedbackEnvironmentModel.self) private var feedbackEnvironmentModel
    @Environment(ProfileEnvironmentModel.self) private var profileEnvironmentModel
    @Environment(\.dismiss) private var dismiss
    @State private var newSubBrandName: String
    @State private var subBrand: SubBrand.JoinedProduct

    let onUpdate: UpdateSubBrandCallback
    let brand: Brand.JoinedSubBrandsProductsCompany

    init(
        brand: Brand.JoinedSubBrandsProductsCompany,
        subBrand: SubBrand.JoinedProduct,
        onUpdate: @escaping UpdateSubBrandCallback
    ) {
        self.brand = brand
        _subBrand = State(wrappedValue: subBrand)
        _newSubBrandName = State(wrappedValue: subBrand.name ?? "")
        self.onUpdate = onUpdate
    }

    var invalidNewName: Bool {
        !newSubBrandName.isValidLength(.normal) || subBrand
            .name == newSubBrandName
    }

    var subBrandsToMergeTo: [SubBrand.JoinedProduct] {
        brand.subBrands.filter { $0.name != nil && $0.id != subBrand.id }
    }

    var body: some View {
        Form {
            Section("subBrand.name.title") {
                TextField("subBrand.name.placeholder", text: $newSubBrandName)
                ProgressButton("labels.edit") {
                    await editSubBrand()
                }
                .disabled(invalidNewName)
            }

            if !subBrandsToMergeTo.isEmpty {
                Section("subBrand.mergeToAnotherSubBrand.title") {
                    ForEach(subBrandsToMergeTo) { subBrand in
                        EditSubBrandMergeToRowView(subBrand: subBrand) { mergeTo in
                            await mergeToSubBrand(mergeTo: mergeTo)
                        }
                    }
                }
            }

            if profileEnvironmentModel.hasRole(.admin) {
                Section("labels.info") {
                    LabeledContent("labels.id", value: "\(subBrand.id)")
                        .textSelection(.enabled)
                    LabeledContent("verification.verified.label", value: "\(subBrand.isVerified)".capitalized)
                }.headerProminence(.increased)
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("labels.edit \(subBrand.name.orEmpty)")
        .toolbar {
            toolbarContent
        }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarDoneActionView()
    }

    func mergeToSubBrand(mergeTo: SubBrand.JoinedProduct) async {
        switch await repository.subBrand
            .update(updateRequest: .brand(SubBrand.UpdateBrandRequest(id: subBrand.id, brandId: mergeTo.id)))
        {
        case .success:
            feedbackEnvironmentModel.trigger(.notification(.success))
            await onUpdate(subBrand)
        case let .failure(error):
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Failed to merge to merge sub-brand '\(subBrand.id)' to '\(mergeTo.id)'. Error: \(error) (\(#file):\(#line))")
        }
    }

    func editSubBrand() async {
        switch await repository.subBrand.update(updateRequest: .name(.init(id: subBrand.id, name: newSubBrandName))) {
        case let .success(updatedSubBrand):
            router.open(.toast(.success("subBrand.updated.toast")))
            let updatedSubBrand = subBrand.copyWith(name: updatedSubBrand.name)
            await onUpdate(updatedSubBrand)
        case let .failure(error):
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Failed to edit sub-brand'. Error: \(error) (\(#file):\(#line))")
        }
    }
}

struct EditSubBrandMergeToRowView: View {
    @State private var showMergeConfirmationDialog = false
    let subBrand: SubBrand.JoinedProduct
    let onMerge: (_ mergeTo: SubBrand.JoinedProduct) async -> Void

    var body: some View {
        if let name = subBrand.name {
            Button(name, action: { showMergeConfirmationDialog = true })
                .confirmationDialog(
                    "subBrand.mergeTo.confirmation.description",
                    isPresented: $showMergeConfirmationDialog,
                    titleVisibility: .visible,
                    presenting: subBrand
                ) { presenting in
                    ProgressButton(
                        "subBrand.mergeTo.confirmation.label \(subBrand.label) \(presenting.label)",
                        role: .destructive,
                        action: {
                            await onMerge(subBrand)
                        }
                    )
                }
        }
    }
}

extension SubBrandProtocol {
    var label: String {
        if let name {
            name
        } else {
            String(localized: "subBrand.defaultSubBrand.label")
        }
    }
}
