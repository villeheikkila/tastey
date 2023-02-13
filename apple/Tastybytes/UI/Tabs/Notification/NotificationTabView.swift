import SwiftUI

struct NotificationTabView: View {
  let client: Client
  @EnvironmentObject private var notificationManager: NotificationManager
  @StateObject private var router = Router()
  @Binding private var resetNavigationOnTab: Tab?

  init(_ client: Client, resetNavigationOnTab: Binding<Tab?>) {
    self.client = client
    _resetNavigationOnTab = resetNavigationOnTab
  }

  var body: some View {
    NavigationStack(path: $router.path) {
      List {
        ForEach(notificationManager.filteredNotifications) {
          notification in
          HStack {
            switch notification.content {
            case let .message(message):
              MessageNotificationView(message: message)
                .onTapGesture {
                  notificationManager.markAsRead(notification)
                }
            case let .friendRequest(friendRequest):
              FriendRequestNotificationView(friend: friendRequest)
            case let .taggedCheckIn(taggedCheckIn):
              TaggedInCheckInNotificationView(checkIn: taggedCheckIn)
            case let .checkInReaction(checkInReaction):
              CheckInReactionNotificationView(checkInReaction: checkInReaction)
            }
            Spacer()
          }
        }
        .onDelete(perform: {
          index in notificationManager.deleteFromIndex(at: index)
        })
      }
      .refreshable {
        notificationManager.refresh(reset: true)
      }
      .navigationTitle(notificationManager.filter?.label ?? "Notifications")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        toolbarContent
      }
      .onChange(of: $resetNavigationOnTab.wrappedValue) { tab in
        if tab == .notifications {
          if router.path.isEmpty {
            notificationManager.filter = nil
          } else {
            router.reset()
          }
          resetNavigationOnTab = nil
        }
      }
      .withRoutes(client)
    }
    .environmentObject(router)
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItemGroup {
      Menu {
        Button(action: {
          notificationManager.markAllAsRead()
        }) {
          Label("Mark all read", systemImage: "envelope.open")
        }
        Button(action: {
          notificationManager.deleteAll()
        }) {
          Label("Delete all", systemImage: "trash")
        }
      } label: {
        Image(systemName: "ellipsis")
      }
    }
    ToolbarTitleMenu {
      Button {
        notificationManager.filter = nil
      } label: {
        Label("Show All", systemImage: "bell.fill")
      }
      Divider()
      ForEach(NotificationType.allCases, id: \.self) { type in
        Button {
          notificationManager.filter = type
        } label: {
          Label(type.label, systemImage: type.systemImage)
        }
      }
    }
  }
}