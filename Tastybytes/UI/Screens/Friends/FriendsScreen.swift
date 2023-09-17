import EnvironmentModels
import Models
import OSLog
import Repositories
import SwiftUI

struct FriendsScreen: View {
    private let logger = Logger(category: "FriendsScreen")
    @Environment(\.repository) private var repository
    @Environment(FriendEnvironmentModel.self) private var friendEnvironmentModel
    @Environment(ProfileEnvironmentModel.self) private var profileEnvironmentModel
    @Environment(FeedbackEnvironmentModel.self) private var feedbackEnvironmentModel
    @State private var friends: [Friend]
    @State private var searchTerm = ""

    let profile: Profile

    init(profile: Profile, initialFriends: [Friend]? = []) {
        self.profile = profile
        _friends = State(wrappedValue: initialFriends ?? [])
    }

    var body: some View {
        List {
            ForEach(friends) { friend in
                FriendListItemView(profile: friend.getFriend(userId: profile.id)) {}
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Friends (\(friends.count))")
            .navigationBarTitleDisplayMode(.inline)
        }
        .searchable(text: $searchTerm, placement: .navigationBarDrawer(displayMode: .always))
        #if !targetEnvironment(macCatalyst)
            .refreshable {
                await feedbackEnvironmentModel.wrapWithHaptics {
                    await loadFriends()
                }
            }
        #endif
            .task {
                    if friends.isEmpty {
                        await loadFriends()
                    }
                }
                .toolbar {
                    toolbarContent
                }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            if friendEnvironmentModel.hasNoFriendStatus(friend: profile) {
                ProgressButton(
                    "Add friend",
                    systemSymbol: .personFillBadgePlus,
                    action: { await friendEnvironmentModel.sendFriendRequest(receiver: profile.id) }
                )
                .labelStyle(.iconOnly)
                .imageScale(.large)
            }
        }
    }

    func loadFriends() async {
        switch await repository.friend.getByUserId(
            userId: profile.id,
            status: Friend.Status.accepted
        ) {
        case let .success(friends):
            self.friends = friends
        case let .failure(error):
            guard !error.localizedDescription.contains("cancelled") else { return }
            feedbackEnvironmentModel.toggle(.error(.unexpected))
            logger.error("Failed to load friends' . Error: \(error) (\(#file):\(#line))")
        }
    }
}
