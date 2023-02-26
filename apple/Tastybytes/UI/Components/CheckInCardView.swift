import CachedAsyncImage
import SwiftUI
import WrappingHStack

struct CheckInCardView: View {
  @EnvironmentObject private var router: Router
  @State private var showFullPicture = false

  let client: Client
  let checkIn: CheckIn
  let loadedFrom: LoadedFrom

  var body: some View {
    VStack {
      VStack {
        header
        productSection
      }
      .padding([.leading, .trailing], 10)
      checkInImage
      VStack {
        checkInSection
        taggedProfilesSection
        footer
      }
      .padding([.leading, .trailing], 10)
    }
    .padding([.top, .bottom], 10)
    .background(Color(.tertiarySystemBackground))
    .clipped()
    .cornerRadius(8)
    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 2, y: 2)
  }

  private var header: some View {
    HStack {
      AvatarView(avatarUrl: checkIn.profile.avatarUrl, size: 24, id: checkIn.profile.id)
      Text(checkIn.profile.preferredName)
        .font(.caption).bold()
        .foregroundColor(.primary)
      Spacer()
      if let location = checkIn.location {
        Text("\(location.name) \(location.country?.emoji ?? "")")
          .font(.caption).bold()
          .foregroundColor(.primary)
          .if(!loadedFrom.isLoadedFromLocation(location)) { view in
            view
              .contentShape(Rectangle())
              .accessibilityAddTraits(.isLink)
              .onTapGesture {
                router.navigate(to: .location(location), resetStack: false)
              }
          }
      }
    }
    .if(!loadedFrom.isLoadedFromProfile(checkIn.profile)) { view in
      view
        .contentShape(Rectangle())
        .accessibilityAddTraits(.isLink)
        .onTapGesture {
          router.navigate(to: .profile(checkIn.profile), resetStack: false)
        }
    }
  }

  @ViewBuilder
  private var checkInImage: some View {
    if let imageUrl = checkIn.getImageUrl() {
      CachedAsyncImage(url: imageUrl, urlCache: .imageCache) { image in
        image
          .resizable()
          .scaledToFill()
          .frame(height: 200)
          .clipped()
          .contentShape(Rectangle())
          .accessibility(addTraits: .isButton)
          .onTapGesture {
            showFullPicture = true
          }
          .popover(isPresented: $showFullPicture) {
            CachedAsyncImage(url: imageUrl, urlCache: .imageCache) { image in
              image
                .resizable()
                .scaledToFill()
            } placeholder: {
              ProgressView()
            }
          }
      } placeholder: {
        ProgressView()
      }
    }
  }

  private var productSection: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        CategoryView(category: checkIn.product.category, subcategories: checkIn.product.subcategories)
        Spacer()
        if let servingStyle = checkIn.servingStyle {
          ServingStyleLabelView(servingStyleName: servingStyle.name)
        }
      }

      Text(checkIn.product.getDisplayName(.fullName))
        .font(.headline)
        .foregroundColor(.primary)

      if let description = checkIn.product.description {
        Text(description)
          .font(.caption)
      }

      HStack {
        Text(checkIn.product.getDisplayName(.brandOwner))
          .font(.subheadline)
          .foregroundColor(.secondary)
          .contentShape(Rectangle())
          .accessibilityAddTraits(.isLink)
          .onTapGesture {
            router.navigate(to: .company(checkIn.product.subBrand.brand.brandOwner), resetStack: false)
          }

        if let manufacturer = checkIn.variant?.manufacturer,
           manufacturer.id != checkIn.product.subBrand.brand.brandOwner.id
        {
          Text("(\(manufacturer.name))")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }

        Spacer()
      }
    }
    .if(loadedFrom != .product) { view in
      view
        .contentShape(Rectangle())
        .accessibilityAddTraits(.isLink)
        .onTapGesture {
          router.navigate(to: .product(checkIn.product), resetStack: false)
        }
    }
  }

  @ViewBuilder
  private var checkInSection: some View {
    if !checkIn.isEmpty {
      VStack(alignment: .leading, spacing: 6) {
        if let rating = checkIn.rating {
          RatingView(rating: rating)
        }

        if let review = checkIn.review {
          Text(review)
            .fontWeight(.medium)
            .foregroundColor(.primary)
        }

        if let flavors = checkIn.flavors {
          WrappingHStack(flavors, id: \.self, spacing: .constant(4)) { flavor in
            ChipView(title: flavor.label)
          }
        }
      }
      .if(loadedFrom != .checkIn) { view in
        view
          .contentShape(Rectangle())
          .accessibilityAddTraits(.isLink)
          .onTapGesture {
            router.navigate(to: .checkIn(checkIn), resetStack: false)
          }
      }
    }
  }

  @ViewBuilder
  private var taggedProfilesSection: some View {
    if !checkIn.taggedProfiles.isEmpty {
      VStack(spacing: 4) {
        HStack {
          Text(verbatim: "Tagged friends")
            .font(.subheadline)
            .fontWeight(.medium)
          Spacer()
        }
        HStack(spacing: 4) {
          ForEach(checkIn.taggedProfiles, id: \.id) { taggedProfile in
            AvatarView(avatarUrl: taggedProfile.avatarUrl, size: 24, id: taggedProfile.id)
              .if(!loadedFrom.isLoadedFromProfile(taggedProfile)) { view in
                view
                  .contentShape(Rectangle())
                  .accessibilityAddTraits(.isLink)
                  .onTapGesture {
                    router.navigate(to: .profile(taggedProfile), resetStack: false)
                  }
              }
          }
          Spacer()
        }
      }
    }
  }

  private var footer: some View {
    HStack {
      HStack {
        Text(checkIn.isMigrated ? "legacy check-in" : checkIn.createdAt.relativeTime())
          .font(.caption).bold()
        Spacer()
      }
      .if(loadedFrom != .checkIn) { view in
        view
          .contentShape(Rectangle())
          .accessibilityAddTraits(.isLink)
          .onTapGesture {
            router.navigate(to: .checkIn(checkIn), resetStack: false)
          }
      }
      ReactionsView(client, checkIn: checkIn)
    }
  }
}

extension CheckInCardView {
  enum LoadedFrom: Equatable {
    case checkIn
    case product
    case profile(Profile)
    case activity(Profile)
    case location(Location)

    func isLoadedFromLocation(_ location: Location) -> Bool {
      switch self {
      case let .location(fromLocation):
        return fromLocation == location
      default:
        return false
      }
    }

    func isLoadedFromProfile(_ profile: Profile) -> Bool {
      switch self {
      case let .profile(fromProfile):
        return fromProfile == profile
      default:
        return false
      }
    }
  }
}