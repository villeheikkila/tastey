import Charts
import Components
import EnvironmentModels
import Extensions
import Models
import OSLog
import PhotosUI
import Repositories
import SwiftUI

@MainActor
struct ProfileView: View {
    private let logger = Logger(category: "ProfileView")
    private let topAnchor = 0
    @Environment(FriendEnvironmentModel.self) private var friendEnvironmentModel
    @State private var checkIns = [CheckIn]()
    @State private var alertError: AlertError?
    @State private var refreshId = 0

    let profile: Profile
    @Binding var scrollToTop: Int
    let isCurrentUser: Bool

    var body: some View {
        CheckInList(
            id: "ProfileView",
            fetcher: .profile(profile),
            checkIns: $checkIns,
            scrollToTop: $scrollToTop,
            onRefresh: {
                refreshId += 1
            },
            topAnchor: topAnchor,
            header: {
                ProfileHeader(
                    profile: profile,
                    refreshId: $refreshId,
                    isCurrentUser: isCurrentUser,
                    topAnchor: topAnchor
                )
            }
        )
        .sensoryFeedback(.success, trigger: friendEnvironmentModel.friends)
        .alertError($alertError)
    }
}
