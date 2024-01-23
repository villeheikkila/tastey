import EnvironmentModels
import Models
import SwiftUI

enum SiderBarTab: Int, Identifiable, Hashable, CaseIterable {
    case activity, discover, notifications, admin, profile, friends, settings

    var id: Int {
        rawValue
    }

    @ViewBuilder var label: some View {
        switch self {
        case .activity:
            Label("Activity", systemImage: "list.star")
        case .discover:
            Label("Discover", systemImage: "magnifyingglass")
        case .notifications:
            Label("Notifications", systemImage: "bell")
        case .admin:
            Label("Admin", systemImage: "exclamationmark.lock.fill")
        case .profile:
            Label("Profile", systemImage: "person.fill")
        case .friends:
            Label("Friends", systemImage: "person.2.fill")
        case .settings:
            Label("Settings", systemImage: "gearshape.fill")
        }
    }
}

@MainActor
struct SideBarView: View {
    @Environment(NotificationEnvironmentModel.self) private var notificationEnvironmentModel
    @Environment(FeedbackEnvironmentModel.self) private var feedbackEnvironmentModel
    @Environment(ProfileEnvironmentModel.self) private var profileEnvironmentModel
    @Environment(AppEnvironmentModel.self) private var appEnvironmentModel
    @Environment(\.isPortrait) private var isPortrait
    @AppStorage(.selectedSidebarTab) private var storedSelection = SiderBarTab.activity
    @State private var selection: SiderBarTab? = SiderBarTab.activity {
        didSet {
            if let selection {
                storedSelection = selection
            }
        }
    }

    @State private var scrollToTop: Int = 0
    @State private var router = Router()

    private var shownTabs: [SiderBarTab] {
        if profileEnvironmentModel.hasRole(.admin) {
            SiderBarTab.allCases
        } else {
            SiderBarTab.allCases.filter { $0 != .admin }
        }
    }

    private var columnVisibility: NavigationSplitViewVisibility {
        isPortrait ? .automatic : .all
    }

    var body: some View {
        @Bindable var feedbackEnvironmentModel = feedbackEnvironmentModel
        NavigationSplitView(columnVisibility: .constant(columnVisibility)) {
            List(selection: $selection) {
                HStack(alignment: .firstTextBaseline) {
                    Text(appEnvironmentModel.infoPlist.appName)
                        .font(Font.custom("Comfortaa-Bold", size: 24)).bold()
                    Spacer()
                }
                Color.clear.frame(width: 0, height: 12)
                ForEach(shownTabs) { newTab in
                    Button(action: {
                        if newTab == selection {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                scrollToTop += 1
                                router.reset()
                            }
                        } else {
                            selection = newTab
                        }
                    }, label: {
                        newTab.label
                    })
                    .tag(newTab.id)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(220)
        } detail: {
            @Bindable var router = router
            NavigationStack(path: $router.path) {
                switch selection {
                case .activity:
                    ActivityScreen(scrollToTop: $scrollToTop)
                case .discover:
                    DiscoverScreen(scrollToTop: $scrollToTop)
                case .notifications:
                    NotificationScreen(scrollToTop: $scrollToTop)
                case .admin:
                    AdminScreen()
                case .profile:
                    CurrentProfileScreen(scrollToTop: $scrollToTop)
                case .friends:
                    CurrentUserFriendsScreen()
                case .settings:
                    SettingsScreen()
                case nil:
                    EmptyView()
                }
            }
            .navigationDestination(for: Screen.self) { screen in
                screen.view
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onOpenURL { url in
            if let tab = TabUrlHandler(url: url, deeplinkSchemes: appEnvironmentModel.infoPlist.deeplinkSchemes).sidebarTab {
                selection = tab
            }
        }
        .onAppear {
            selection = storedSelection
        }
        .sensoryFeedback(.selection, trigger: selection)
        .environment(router)
        .environment(appEnvironmentModel)
        .toast(isPresenting: $feedbackEnvironmentModel.show) {
            feedbackEnvironmentModel.toast
        }
    }

    private func getBadgeByTab(_ tab: Tab) -> Int {
        switch tab {
        case .notifications:
            notificationEnvironmentModel.unreadCount
        default:
            0
        }
    }
}
