import EnvironmentModels
import Models
import SwiftUI

@MainActor
public struct CheckInShareLinkView: View {
    @Environment(AppEnvironmentModel.self) private var appEnvironmentModel
    let checkIn: CheckIn

    public init(checkIn: CheckIn) {
        self.checkIn = checkIn
    }

    public var link: URL {
        NavigatablePath.checkIn(id: checkIn.id).getUrl(baseUrl: appEnvironmentModel.infoPlist.baseUrl)
    }

    private var title: String {
        "\(checkIn.profile.preferredName) had \(checkIn.product.formatted(.fullName))"
    }

    public var body: some View {
        ShareLink(item: link, subject: Text("Check-in"), message: Text(title))
    }
}
