import Components
import Models
import OSLog
import Repositories
import SwiftUI

struct CompanyEditSuggestionScreen: View {
    @Binding var company: Company.Management

    var body: some View {
        List(company.editSuggestions) { editSuggestion in
            CompanyEditSuggestionRow(company: $company, editSuggestion: editSuggestion)
        }
        .overlay {
            if company.editSuggestions.isEmpty {
                ContentUnavailableView("admin.noEditSuggestions.title", systemImage: "tray")
            }
        }
        .listStyle(.plain)
        .navigationTitle("company.admin.editSuggestion.navigationTitle")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CompanyEditSuggestionRow: View {
    private let logger = Logger(category: "CompanyEditSuggestionRow")
    @Environment(Repository.self) private var repository
    @Environment(Router.self) private var router
    @State private var showApplyConfirmationDialog = false
    @State private var showDeleteConfirmationDialog = false
    @Binding var company: Company.Management
    let editSuggestion: Company.EditSuggestion

    var body: some View {
        HStack(alignment: .top) {
            if let profile = editSuggestion.createdBy {
                Avatar(profile: profile)
                    .avatarSize(.medium)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .top) {
                    Group {
                        if let profile = editSuggestion.createdBy {
                            Text(profile.preferredName)
                        } else {
                            Text("-")
                        }
                    }
                    .font(.caption)
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("\(Image(systemName: "calendar.badge.plus")) \(editSuggestion.createdAt.formatted(.customRelativetime))").font(.caption2)
                        if let resolvedAt = editSuggestion.resolvedAt {
                            Text("\(Image(systemName: "calendar.badge.checkmark")) \(resolvedAt.formatted(.customRelativetime))").font(.caption2)
                        }
                    }
                }
                Text("company.admin.editSuggestion.changeNameTo.label \(company.name) \(editSuggestion.name)")
                    .font(.callout)
            }
            Spacer()
        }
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
            ProgressButton(
                "company.admin.editSuggestion.apply.label \(company.name) \(presenting.name)",
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
            ProgressButton(
                "company.admin.editSuggestion.delete.label \(presenting.name)",
                action: {
                    await deleteEditSuggestion(presenting)
                }
            )
            .tint(.green)
        }
        .listRowBackground(Color.clear)
    }

    func deleteEditSuggestion(_ editSuggestion: Company.EditSuggestion) async {
        switch await repository.company.deleteEditSuggestion(editSuggestion: editSuggestion) {
        case .success:
            withAnimation {
                company = company.copyWith(editSuggestions: company.editSuggestions.removing(editSuggestion))
            }
        case let .failure(error):
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Failed to delete company '\(company.id)'. Error: \(error) (\(#file):\(#line))")
        }
    }

    func resolveEditSuggestion(_ editSuggestion: Company.EditSuggestion) async {
        switch await repository.company.resolveEditSuggestion(editSuggestion: editSuggestion) {
        case .success:
            withAnimation {
                company = company.copyWith(name: editSuggestion.name, editSuggestions: company.editSuggestions.replacing(editSuggestion, with: editSuggestion.copyWith(resolvedAt: Date.now)))
            }
            router.removeLast()
        case let .failure(error):
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Failed to delete company '\(company.id)'. Error: \(error) (\(#file):\(#line))")
        }
    }
}