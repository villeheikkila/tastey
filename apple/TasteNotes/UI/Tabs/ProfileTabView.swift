import Charts
import GoTrue
import PhotosUI
import SwiftUI

struct ProfileTabView: View {
  @StateObject private var router = Router()
  @State private var scrollToTop = 0
  @EnvironmentObject private var profileManager: ProfileManager
  @Binding var resetNavigationStackOnTab: Tab?

  var body: some View {
    NavigationStack(path: $router.path) {
      WithRoutes {
        ProfileView(profile: profileManager.getProfile(), scrollToTop: $scrollToTop)
          .navigationTitle(profileManager.getProfile().preferredName)
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            toolbarContent
          }
      }
      .onChange(of: $resetNavigationStackOnTab.wrappedValue) { tab in
        if tab == .profile {
          if router.path.isEmpty {
            scrollToTop += 1
          } else {
            router.reset()
          }
          resetNavigationStackOnTab = nil
        }
      }
    }
    .environmentObject(router)
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItemGroup(placement: .navigationBarLeading) {
      NavigationLink(value: Route.currentUserFriends) {
        Image(systemName: "person.2").imageScale(.large)
      }
    }
    ToolbarItemGroup(placement: .navigationBarTrailing) {
      NavigationLink(value: Route.settings) {
        Image(systemName: "gear").imageScale(.large)
      }
    }
  }
}
