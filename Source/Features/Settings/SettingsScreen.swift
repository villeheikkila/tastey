import Components
import EnvironmentModels
import Models
import SwiftUI

@MainActor
struct SettingsScreen: View {
    @Environment(AppEnvironmentModel.self) private var appEnvironmentModel
    @Environment(SubscriptionEnvironmentModel.self) private var subscriptionEnvironmentModel
    @Environment(ProfileEnvironmentModel.self) private var profileEnvironmentModel
    @State private var sheet: Sheet?

    var body: some View {
        List {
            profileSection
            appSection
            aboutSection
            logOutSection
        }
        .listStyle(.insetGrouped)
        .navigationBarTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            toolbarContent
        }
        .sheets(item: $sheet)
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("subscription.callToAction", systemImage: "crown.fill", action: { sheet = .subscribe })
                .labelStyle(.iconOnly)
                .imageScale(.large)
                .foregroundColor(.yellow)
        }
    }

    @ViewBuilder private var profileSection: some View {
        Section {
            RouterLink("profile.title", systemName: "person.fill", color: .indigo, screen: .profileSettings)
            RouterLink("account.title", systemName: "gear", color: .gray, screen: .accountSettings)
            RouterLink("privacy.title", systemName: "key.fill", color: .yellow, screen: .privacySettings)
            RouterLink("blockedUsers.title", systemName: "person.fill.xmark", color: .green, screen: .blockedUsers)
        }
    }

    @ViewBuilder private var appSection: some View {
        Section {
            RouterLink("settings.appearance.title", systemName: "paintbrush.fill", color: .blue, screen: .appearanaceSettings)
            RouterLink(
                "notifications.title",
                systemName: "bell.badge.fill",
                color: .red,
                screen: .notificationSettingsScreen
            )
            RouterLink(screen: .appIcon, label: {
                AppIconLabelRow()
            })
        }
    }

    @ViewBuilder private var aboutSection: some View {
        Section {
            RouterLink(
                "contributions.title",
                systemName: "plus",
                color: .teal,
                screen: .contributions
            )
            RouterLink("about.title", systemName: "at", color: .blue, screen: .about)
        } footer: {
            if case .subscribed = subscriptionEnvironmentModel.subscriptionStatus, let subscriptionName = appEnvironmentModel.subscriptionGroup?.name {
                HStack {
                    Spacer()
                    Text("subscription.thankYou \(appEnvironmentModel.infoPlist.appName) \(subscriptionName)")
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder private var logOutSection: some View {
        Section {
            ProgressButton(action: {
                await profileEnvironmentModel.logOut()
            }, label: {
                Spacer()
                Text("settings.actions.signOut")
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                Spacer()
            })
        }
    }
}

struct AppIconLabelRow: View {
    @Environment(ProfileEnvironmentModel.self) private var profileEnvironmentModel

    var body: some View {
        HStack {
            Image(profileEnvironmentModel.appIcon.icon)
                .resizable()
                .cornerRadius(8)
                .frame(width: 30, height: 30)
                .padding(.trailing, 8)
                .aspectRatio(contentMode: .fill)
                .accessibilityHidden(true)
            Text("settings.appIcon.title")
            Spacer()
            if profileEnvironmentModel.appIcon != .ramune {
                Text(profileEnvironmentModel.appIcon.label)
                    .foregroundColor(.secondary)
            }
        }
    }
}
