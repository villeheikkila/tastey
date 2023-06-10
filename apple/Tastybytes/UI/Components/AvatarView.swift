import SwiftUI

struct AvatarView: View {
  let avatarUrl: URL?
  let size: Double
  let id: UUID

  var body: some View {
    if let avatarUrl {
      AsyncImage(url: avatarUrl) { image in
        image.resizable()
      } placeholder: {
        ProgressView()
      }
      .clipShape(Circle())
      .aspectRatio(contentMode: .fill)
      .frame(width: size, height: size)
      .accessibility(hidden: true)
    } else {
      Image(systemSymbol: .personFill)
        .resizable()
        .padding(.all, size / 5)
        .clipShape(Circle())
        .aspectRatio(contentMode: .fill)
        .frame(width: size, height: size)
        .foregroundColor(Color(seed: id.uuidString))
        .accessibility(hidden: true)
    }
  }
}
