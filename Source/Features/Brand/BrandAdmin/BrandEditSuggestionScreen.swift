import Components
import Logging
import Models
import Repositories
import SwiftUI

struct BrandEditSuggestionScreen: View {
    @Binding var brand: Brand.Detailed
    let initialEditSuggestion: Brand.EditSuggestion.Id?

    var body: some View {
        List(brand.editSuggestions) { editSuggestion in
            BrandEditSuggestionRowView(brand: $brand, editSuggestion: editSuggestion)
        }
        .listStyle(.plain)
        .overlay {
            if brand.editSuggestions.isEmpty {
                ContentUnavailableView("admin.noEditSuggestions.title", systemImage: "tray")
            }
        }
        .navigationTitle("company.admin.editSuggestion.navigationTitle")
        .navigationBarTitleDisplayMode(.inline)
        .scrollToPosition(id: initialEditSuggestion)
    }
}

struct BrandEditSuggestionRowView: View {
    private let logger = Logger(label: "CompanyEditSuggestionRow")
    @Environment(Repository.self) private var repository
    @Environment(Router.self) private var router
    @State private var showApplyConfirmationDialog = false
    @State private var showDeleteConfirmationDialog = false
    @Binding var brand: Brand.Detailed
    let editSuggestion: Brand.EditSuggestion

    var body: some View {
        BrandEditSuggestionView(editSuggestion: editSuggestion, brand: brand)
            .padding(.vertical, 2)
            .swipeActions {
                Button("company.admin.editSuggestion.delete.label", systemImage: "trash") {
                    showDeleteConfirmationDialog = true
                }
                .tint(.red)
                Button("company.admin.editSuggestion.apply.label", systemImage: "checkmark") {
                    showApplyConfirmationDialog = true
                }
                .tint(.green)
            }
            .confirmationDialog(
                "company.admin.editSuggestion.apply.description",
                isPresented: $showApplyConfirmationDialog,
                titleVisibility: .visible,
                presenting: editSuggestion
            ) { presenting in
                AsyncButton(
                    "company.admin.editSuggestion.apply.label \(brand.name) \(presenting.name ?? "-")",
                    action: {
                        await resolveEditSuggestion(presenting)
                    }
                )
                .tint(.green)
            }
            .confirmationDialog(
                "company.admin.editSuggestion.delete.description",
                isPresented: $showDeleteConfirmationDialog,
                titleVisibility: .visible,
                presenting: editSuggestion
            ) { presenting in
                AsyncButton(
                    "company.admin.editSuggestion.delete.label \(presenting.name ?? "-")",
                    action: {
                        await deleteEditSuggestion(presenting)
                    }
                )
                .tint(.green)
            }
            .listRowBackground(Color.clear)
    }

    private func deleteEditSuggestion(_ editSuggestion: Brand.EditSuggestion) async {
        do {
            try await repository.brand.deleteEditSuggestion(editSuggestion: editSuggestion)
            withAnimation {
                brand = brand.copyWith(editSuggestions: brand.editSuggestions.removing(editSuggestion))
            }
        } catch {
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Failed to delete brand edit suggestion '\(editSuggestion.id)'. Error: \(error) (\(#file):\(#line))")
        }
    }

    private func resolveEditSuggestion(_ editSuggestion: Brand.EditSuggestion) async {
        do {
            try await repository.brand.resolveEditSuggestion(editSuggestion: editSuggestion)
            withAnimation {
                brand = brand.copyWith(name: editSuggestion.name, editSuggestions: brand.editSuggestions.replacing(editSuggestion, with: editSuggestion.copyWith(resolvedAt: Date.now)))
            }
            router.removeLast()
        } catch {
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Failed to resolve edit suggestion '\(editSuggestion.id)'. Error: \(error) (\(#file):\(#line))")
        }
    }
}

struct BrandEditSuggestionView: View {
    let brand: Brand.Detailed?
    let editSuggestion: Brand.EditSuggestion

    init(editSuggestion: Brand.EditSuggestion, brand: Brand.Detailed? = nil) {
        self.brand = brand
        self.editSuggestion = editSuggestion
    }

    var body: some View {
        Text("company.admin.editSuggestion.changeNameTo.label \(brand?.name ?? "-") \(editSuggestion.name ?? "-")")
            .font(.callout)
    }
}
