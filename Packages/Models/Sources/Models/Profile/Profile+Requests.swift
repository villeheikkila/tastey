import Extensions
import Foundation
public import Tagged

public extension Profile {
    struct UpdateRequest: Encodable, Sendable {
        public let id: Profile.Id
        public var username: String?
        public var firstName: String?
        public var lastName: String?
        public var nameDisplay: String?
        public var isPrivate: Bool?
        public var isOnboarded: Bool?

        enum CodingKeys: String, CodingKey {
            case username
            case firstName = "first_name"
            case lastName = "last_name"
            case nameDisplay = "name_display"
            case isPrivate = "is_private"
            case isOnboarded = "is_onboarded"
        }

        public init(id: Profile.Id, showFullName: Bool) {
            nameDisplay = showFullName ? Profile.NameDisplay.fullName.rawValue : Profile.NameDisplay.username.rawValue
            self.id = id
        }

        public init(id: Profile.Id, isPrivate: Bool) {
            self.isPrivate = isPrivate
            self.id = id
        }

        public init(id: Profile.Id, isOnboarded: Bool) {
            self.isOnboarded = isOnboarded
            self.id = id
        }

        public init(id: Profile.Id, username: String?, firstName: String?, lastName: String?) {
            self.username = username
            self.firstName = firstName
            self.lastName = lastName
            self.id = id
        }

        init(
            id: Profile.Id,
            isPrivate: Bool,
            showFullName: Bool,
            isOnboarded: Bool
        ) {
            self.id = id
            self.isPrivate = isPrivate
            nameDisplay = showFullName ? Profile.NameDisplay.fullName.rawValue : Profile.NameDisplay.username.rawValue
            self.isOnboarded = isOnboarded
        }
    }
}

public extension Profile {
    struct SettingsUpdateRequest: Encodable, Sendable {
        public let id: Profile.Id
        var sendReactionNotifications: Bool?
        var sendTaggedCheckInNotifications: Bool?
        var sendFriendRequestNotifications: Bool?
        var sendCommentNotifications: Bool?

        enum CodingKeys: String, CodingKey {
            case sendReactionNotifications = "send_reaction_notifications"
            case sendTaggedCheckInNotifications = "send_tagged_check_in_notifications"
            case sendFriendRequestNotifications = "send_friend_request_notifications"
            case sendCommentNotifications = "send_comment_notifications"
        }

        public init(
            id: Profile.Id,
            sendReactionNotifications: Bool? = nil,
            sendTaggedCheckInNotifications: Bool? = nil,
            sendFriendRequestNotifications: Bool? = nil,
            sendCommentNotifications: Bool? = nil
        ) {
            self.id = id
            self.sendReactionNotifications = sendReactionNotifications
            self.sendTaggedCheckInNotifications = sendTaggedCheckInNotifications
            self.sendFriendRequestNotifications = sendFriendRequestNotifications
            self.sendCommentNotifications = sendCommentNotifications
        }
    }
}

public extension Profile {
    struct UsernameCheckRequest: Codable, Sendable {
        public init(username: String) {
            self.username = username
        }

        public let username: String

        enum CodingKeys: String, CodingKey {
            case username = "p_username"
        }
    }

    struct PushNotificationToken: Identifiable, Codable, Hashable, Sendable {
        public var id: String { deviceToken.rawValue }

        public let deviceToken: DeviceToken.Id
        public let isDevelopment: Bool

        public init(deviceToken: DeviceToken.Id, isDevelopment: Bool) {
            self.deviceToken = deviceToken
            self.isDevelopment = isDevelopment
        }

        enum CodingKeys: String, CodingKey {
            case deviceToken = "p_device_token"
            case isDevelopment = "p_is_development"
        }
    }
}

public struct NumberOfCheckInsByDayRequest: Sendable, Encodable {
    public let profileId: Profile.Id

    public init(profileId: Profile.Id) {
        self.profileId = profileId
    }

    enum CodingKeys: String, CodingKey {
        case profileId = "p_profile_id"
    }
}

public enum StatisticsTimePeriod: String, CaseIterable, Sendable, Identifiable {
    case week, month, sixMonths = "six_months", year

    public var id: String {
        rawValue
    }
}
