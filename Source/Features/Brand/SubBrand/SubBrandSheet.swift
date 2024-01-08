import Components
import EnvironmentModels
import Extensions
import Models
import OSLog
import Repositories
import SwiftUI

@MainActor
struct SubBrandSheet: View {
    private let logger = Logger(category: "SubBrandSheet")
    @Environment(\.repository) private var repository
    @Environment(ProfileEnvironmentModel.self) private var profileEnvironmentModel
    @Environment(FeedbackEnvironmentModel.self) private var feedbackEnvironmentModel
    @Environment(\.dismiss) private var dismiss
    @State private var subBrandName = ""
    @State private var searchTerm: String = ""
    @State private var alertError: AlertError?
    @Binding var subBrand: SubBrandProtocol?

    let brandWithSubBrands: Brand.JoinedSubBrands

    var filteredSubBrands: [SubBrand] {
        brandWithSubBrands.subBrands.sorted()
            .filter { sub in
                guard let name = sub.name else { return false }
                return searchTerm.isEmpty || name.lowercased().contains(searchTerm.lowercased())
            }
    }

    var showContentUnavailableView: Bool {
        !searchTerm.isEmpty && filteredSubBrands.isEmpty
    }

    var body: some View {
        List {
            ForEach(filteredSubBrands) { subBrand in
                if let name = subBrand.name {
                    Button(name, action: {
                        self.subBrand = subBrand
                        dismiss()
                    })
                }
            }

            if profileEnvironmentModel.hasPermission(.canCreateBrands) {
                Section("Add new sub-brand for \(brandWithSubBrands.name)") {
                    ScanTextField(title: "Name", text: $subBrandName)
                    ProgressButton("Create", action: { await createNewSubBrand() })
                        .disabled(!subBrandName.isValidLength(.normal))
                }
            }
        }
        .searchable(text: $searchTerm, placement: .navigationBarDrawer(displayMode: .always))
        .overlay {
            ContentUnavailableView.search(text: searchTerm)
                .opacity(showContentUnavailableView ? 1 : 0)
        }
        .alertError($alertError)
        .navigationTitle("Sub-brands")
        .toolbar {
            toolbarContent
        }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .cancellationAction) {
            Button("actions.cancel", role: .cancel, action: { dismiss() })
                .bold()
        }
    }

    func createNewSubBrand() async {
        switch await repository.subBrand
            .insert(newSubBrand: SubBrand.NewRequest(name: subBrandName, brandId: brandWithSubBrands.id))
        {
        case let .success(newSubBrand):
            feedbackEnvironmentModel.toggle(.success("New Sub-brand Created!"))
            subBrand = newSubBrand
            dismiss()
        case let .failure(error):
            guard !error.isCancelled else { return }
            alertError = .init()
            logger.error("Saving sub-brand failed. Error: \(error) (\(#file):\(#line))")
        }
    }
}
