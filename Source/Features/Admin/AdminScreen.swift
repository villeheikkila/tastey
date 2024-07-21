import EnvironmentModels
import SwiftUI

struct AdminScreen: View {
    @Environment(AdminEnvironmentModel.self) private var adminEnvironmentModel

    var body: some View {
        List {
            Section("admin.section.activity.title") {
                RouterLink(
                    "admin.events.title",
                    systemImage: "bell.badge",
                    count: adminEnvironmentModel.events.count,
                    open: .screen(.adminEvent)
                )
                RouterLink(
                    "admin.verification.title",
                    systemImage: "checkmark.seal",
                    count: adminEnvironmentModel.unverified.count,
                    open: .screen(.verification)
                )
                RouterLink(
                    "admin.editsSuggestions.title",
                    systemImage: "slider.horizontal.2.square.on.square",
                    count: adminEnvironmentModel.editSuggestions.count,
                    open: .screen(.editSuggestionsAdmin)
                )
                RouterLink("report.admin.navigationTitle", systemImage: "exclamationmark.bubble", open: .screen(.reports()))
            }

            Section("admin.section.management.title") {
                RouterLink("admin.category.title", systemImage: "rectangle.stack", open: .screen(.categoryAdmin))
                RouterLink("flavor.navigationTitle", systemImage: "face.smiling", open: .screen(.flavorAdmin))
                RouterLink("admin.locations.title", systemImage: "mappin.square", open: .screen(.locationAdmin))
                RouterLink("admin.profiles.title", systemImage: "person", open: .screen(.profilesAdmin))
            }
        }
        .listStyle(.insetGrouped)
        .navigationBarTitle("admin.navigationTitle")
    }
}
