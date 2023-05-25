import Foundation

struct Notification: Identifiable, Hashable {
  enum Content: Hashable {
    case message(String)
    case friendRequest(Friend)
    case taggedCheckIn(CheckIn)
    case checkInReaction(CheckInReaction.JoinedCheckIn)
    case checkInComment(CheckInComment.Joined)
  }

  let id: Int
  let createdAt: Date
  let seenAt: Date?
  let content: Content
}

extension Notification {
  static func getQuery(_ queryType: QueryType) -> String {
    let tableName = "notifications"
    let saved = "id, message, created_at, seen_at"

    switch queryType {
    case .tableName:
      return tableName
    case .joined:
      return [
        saved,
        CheckInReaction.getQuery(.joinedProfileCheckIn(true)),
        CheckInTaggedProfiles.getQuery(.joined(true)),
        Friend.getQuery(.joined(true)),
        CheckInComment.getQuery(.joinedCheckIn(true))
      ].joinComma()
    }
  }

  enum QueryType {
    case tableName
    case joined
  }
}

extension Notification: Decodable {
  enum CodingKeys: String, CodingKey {
    case id
    case message
    case createdAt = "created_at"
    case seenAt = "seen_at"
    case friendRequest = "friends"
    case taggedCheckIn = "check_in_tagged_profiles"
    case checkInReaction = "check_in_reactions"
    case checkInComments = "check_in_comments"
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(Int.self, forKey: .id)

    let timestamp = try values.decode(String.self, forKey: .createdAt)
    if let createdAt = Date(timestamptzString: timestamp) {
      self.createdAt = createdAt
    } else {
      throw DateParsingError.unsupportedFormat
    }

    if let date = try values.decodeIfPresent(String.self, forKey: .seenAt) {
      seenAt = Date(timestamptzString: date)
    } else {
      seenAt = nil
    }

    let message = try values.decodeIfPresent(String.self, forKey: .message)
    let friendRequest = try values.decodeIfPresent(Friend.self, forKey: .friendRequest)
    let taggedCheckIn = try values.decodeIfPresent(CheckInTaggedProfiles.self, forKey: .taggedCheckIn)
    let checkInReaction = try values.decodeIfPresent(CheckInReaction.JoinedCheckIn.self, forKey: .checkInReaction)
    let checkInComment = try values.decodeIfPresent(CheckInComment.Joined.self, forKey: .checkInComments)

    if let message {
      content = Notification.Content.message(message)
    } else if let friendRequest {
      content = Notification.Content.friendRequest(friendRequest)
    } else if let checkIn = taggedCheckIn?.checkIn {
      content = Notification.Content.taggedCheckIn(checkIn)
    } else if let checkInReaction {
      content = Notification.Content.checkInReaction(checkInReaction)
    } else if let checkInComment {
      content = Notification.Content.checkInComment(checkInComment)
    } else {
      content = Notification.Content.message("No content")
    }
  }
}

extension Notification {
  struct CheckInTaggedProfiles: Identifiable, Decodable {
    let id: Int
    let checkIn: CheckIn

    enum CodingKeys: String, CodingKey {
      case id
      case checkIn = "check_ins"
    }

    static func getQuery(_ queryType: QueryType) -> String {
      let tableName = "check_in_tagged_profiles"
      let saved = "id"

      switch queryType {
      case .tableName:
        return tableName
      case let .joined(withTableName):
        return queryWithTableName(tableName, [saved, CheckIn.getQuery(.joined(true))].joinComma(), withTableName)
      }
    }

    enum QueryType {
      case tableName
      case joined(_ withTableName: Bool)
    }
  }

  struct MarkReadRequest: Encodable {
    let id: Int

    enum CodingKeys: String, CodingKey {
      case id = "p_notification_id"
    }
  }

  struct MarkCheckInReadRequest: Encodable {
    let checkInId: Int

    enum CodingKeys: String, CodingKey {
      case checkInId = "p_check_in_id"
    }
  }
}

enum NotificationType: String, CaseIterable, Identifiable, Sendable {
  var id: Self {
    self
  }

  case message, friendRequest, taggedCheckIn, checkInReaction, checkInComment

  var label: String {
    switch self {
    case .message:
      return "Alerts"
    case .friendRequest:
      return "Friend Requests"
    case .taggedCheckIn:
      return "Tagged check-ins"
    case .checkInReaction:
      return "Reactions"
    case .checkInComment:
      return "Comments"
    }
  }

  var systemImage: String {
    switch self {
    case .message:
      return "bell"
    case .friendRequest:
      return "person.badge.plus"
    case .taggedCheckIn:
      return "tag"
    case .checkInReaction:
      return "hand.thumbsup"
    case .checkInComment:
      return "bubble.left"
    }
  }
}

struct ProfilePushNotification: Codable, Identifiable {
  let id: String
  let sendReactionNotifications: Bool
  let sendTaggedCheckInNotifications: Bool
  let sendFriendRequestNotifications: Bool
  let sendCheckInCommentNotifications: Bool

  enum CodingKeys: String, CodingKey {
    case id = "firebase_registration_token"
    case sendReactionNotifications = "send_reaction_notifications"
    case sendTaggedCheckInNotifications = "send_tagged_check_in_notifications"
    case sendFriendRequestNotifications = "send_friend_request_notifications"
    case sendCheckInCommentNotifications = "send_comment_notifications"
  }

  func copyWith(
    sendReactionNotifications: Bool? = nil,
    sendTaggedCheckInNotifications: Bool? = nil,
    sendFriendRequestNotifications: Bool? = nil,
    sendCheckInCommentNotifications: Bool? = nil
  ) -> ProfilePushNotification {
    ProfilePushNotification(id: id,
                            sendReactionNotifications: sendReactionNotifications ?? self.sendReactionNotifications,
                            sendTaggedCheckInNotifications: sendTaggedCheckInNotifications ?? self
                              .sendTaggedCheckInNotifications,
                            sendFriendRequestNotifications: sendFriendRequestNotifications ?? self
                              .sendFriendRequestNotifications,
                            sendCheckInCommentNotifications: sendCheckInCommentNotifications ?? self
                              .sendCheckInCommentNotifications)
  }

  static func getQuery(_ queryType: QueryType) -> String {
    let tableName = "profile_push_notifications"
    let saved =
      "firebase_registration_token, send_reaction_notifications, send_tagged_check_in_notifications, send_friend_request_notifications, send_friend_request_notifications, send_comment_notifications"

    switch queryType {
    case .tableName:
      return tableName
    case let .saved(withTableName):
      return queryWithTableName(tableName, saved, withTableName)
    }
  }

  enum QueryType {
    case tableName
    case saved(_ withTableName: Bool)
  }
}
