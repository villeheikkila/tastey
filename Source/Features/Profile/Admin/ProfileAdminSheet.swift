import Components
import EnvironmentModels
import Models
import OSLog
import Repositories
import SwiftUI

struct ProfileAdminSheet: View {
    let logger = Logger(category: "ProfileAdminSheet")
    @Environment(ProfileEnvironmentModel.self) private var profileEnvironmentModel
    @Environment(Repository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @State private var state: ScreenState = .loading
    @State private var profile = Profile.Detailed()
    @State private var summary: ProfileSummary?

    let id: Profile.Id
    let onDelete: (_ profile: Profile.Detailed) -> Void

    private var isProfileDeletable: Bool {
        if let summary {
            profileEnvironmentModel.hasRole(.superAdmin) && summary.totalCheckIns > 0
        } else {
            false
        }
    }

    var body: some View {
        Form {
            if state.isPopulated, let summary {
                content(summary: summary)
            }
        }
        .scrollContentBackground(.hidden)
        .animation(.default, value: profile)
        .navigationTitle("profile.admin.navigationTitle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .task {
            await load()
        }
    }

    @ViewBuilder private func content(summary: ProfileSummary) -> some View {
        Section("profile.admin.section.profile") {
            RouterLink(open: .screen(.profile(.init(profile: profile)))) {
                ProfileEntityView(profile: profile)
            }
        }
        .customListRowBackground()
        Section("admin.section.details") {
            LabeledIdView(id: id.uuidString)
            LabeledContent("profile.admin.joinedAt.label", value: profile.joinedAt.formatted(.dateTime
                    .year()
                    .month(.wide)
                    .day()))
            LabeledContent("settings.profile.username", value: profile.username ?? "-")
            LabeledContent("settings.profile.firstName", value: profile.firstName ?? "-")
            LabeledContent("settings.profile.lastName", value: profile.lastName ?? "-")
            LabeledContent("profile.admin.avatars.count", value: profile.avatars.count.formatted())
            Toggle("profile.admin.isOnboarded", isOn: .init(get: {
                profile.isOnboarded
            }, set: { _ in }))
                .disabled(true)
            LabeledContent("profile.uniqueCheckIns", value: summary.uniqueCheckIns.formatted())
            LabeledContent("profile.totalCheckIns", value: summary.totalCheckIns.formatted())
        }
        .customListRowBackground()
        Section {
            RouterLink(
                "admin.section.reports.title",
                systemImage: "exclamationmark.bubble",
                count: profile.reports.count,
                open: .screen(
                    .withReportsAdmin(reports: $profile.map(getter: { location in
                        location.reports
                    }, setter: { reports in
                        profile.copyWith(reports: reports)
                    }))
                )
            )
            RouterLink("contributions.title", systemImage: "plus", open: .screen(.contributions(id)))
            if profileEnvironmentModel.hasRole(.superAdmin) {
                RouterLink(
                    "profile.rolePickerSheet.navigationTitle",
                    systemImage: "lock",
                    open: .screen(.roleSuperAdminPicker(profile: $profile, roles: profile.roles))
                )
            }
        }
        .customListRowBackground()
        Section {
            ConfirmedDeleteButtonView(
                presenting: profile,
                action: delete,
                description: "profile.delete.confirmation.description",
                label: "profile.delete.confirmation.label \(profile.preferredName)",
                isDisabled: isProfileDeletable
            )
        }
        .customListRowBackground()
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarDismissAction()
    }

    private func load() async {
        do {
            profile = try await repository.profile.getDetailed(id: id)
            summary = try await repository.checkIn.getSummaryByProfileId(id: id)
            state = .populated
        } catch {
            guard !error.isCancelled else { return }
            state = .error([error])
            logger.error("Failed to load profile data. Error: \(error) (\(#file):\(#line))")
        }
    }

    private func delete(_ profile: Profile.Detailed) async {
        do {
            try await repository.profile.deleteUserAsSuperAdmin(profile.id)
            onDelete(profile)
            dismiss()
        } catch {
            guard !error.isCancelled else { return }
            logger.error("Failed to delete profile. Error: \(error) (\(#file):\(#line))")
        }
    }
}
