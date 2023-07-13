import SwiftUI

struct NotificationTab: View {
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(FeedbackManager.self) private var feedbackManager
    @State private var scrollToTop: Int = 0
    @Binding var resetNavigationOnTab: Tab?

    var body: some View {
        RouterWrapper(tab: .notifications) { router in
            NotificationScreen(scrollToTop: $scrollToTop)
                .onChange(of: $resetNavigationOnTab.wrappedValue) { _, tab in
                    if tab == .notifications {
                        if router.path.isEmpty {
                            scrollToTop += 1
                        } else {
                            router.reset()
                        }
                        resetNavigationOnTab = nil
                    }
                }
        }
    }
}