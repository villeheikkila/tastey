import AVFoundation
import Observation
import OSLog
import PhotosUI
import SwiftUI

@Observable
public final class PermissionEnvironmentModel {
    private let logger = Logger(category: "PermissionEnvironmentModel")
    private let locationEnvironmentModel = CLLocationManager()
    private let notificationEnvironmentModel = UNUserNotificationCenter.current()

    public var pushNotificationStatus: UNAuthorizationStatus = .notDetermined
    public var locationsStatus: CLAuthorizationStatus = .notDetermined

    public init() {}

    public var hasLocationAccess: Bool {
        locationsStatus == .authorizedWhenInUse || locationsStatus == .authorizedAlways
    }

    // push notifications
    public func requestPushNotificationAuthorization() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        notificationEnvironmentModel.requestAuthorization(
            options: authOptions
        ) { _, _ in
            self.getCurrentPushNotificationPermissionAuthorization()
        }
    }

    public func getCurrentPushNotificationPermissionAuthorization() {
        notificationEnvironmentModel.getNotificationSettings(completionHandler: { settings in
            DispatchQueue.main.async { [unowned self] in
                pushNotificationStatus = settings.authorizationStatus
            }
        })
    }

    // location
    public func getCurrentLocationAuthorization() {
        locationsStatus = locationEnvironmentModel.authorizationStatus
    }

    public func requestLocationAuthorization() {
        locationEnvironmentModel.requestWhenInUseAuthorization()
    }

    public func initialize() {
        getCurrentPushNotificationPermissionAuthorization()
        getCurrentLocationAuthorization()
    }
}
