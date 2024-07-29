import Components

import Models
import SwiftUI

public struct CheckInEntityView: View {
    let checkIn: CheckIn.Joined
    let hideHeader: Bool

    init(checkIn: CheckIn.Joined, hideHeader: Bool = false) {
        self.checkIn = checkIn
        self.hideHeader = hideHeader
    }

    public var body: some View {
        VStack {
            VStack {
                if !hideHeader {
                    header
                }
                productSection
            }
            checkInImage
            VStack(alignment: .leading, spacing: 4) {
                checkInSection
                taggedProfilesSection
                footer
            }
        }
        .padding(.vertical, 4)
    }

    private var header: some View {
        HStack {
            AvatarView(profile: checkIn.profile)
            Text(checkIn.profile.preferredName)
                .font(.caption).bold()
                .foregroundColor(.primary)
            Spacer()
            if let location = checkIn.location {
                Text(location.formatted(.withEmoji))
                    .font(.caption).bold()
                    .foregroundColor(.primary)
            }
        }
    }

    @ViewBuilder private var checkInImage: some View {
        CheckInImageReelView(checkIn: checkIn, onDeleteImage: nil)
    }

    private var productSection: some View {
        HStack(spacing: 12) {
            if !checkIn.product.logos.isEmpty {
                ProductLogoView(product: checkIn.product, size: 32)
                    .padding(.leading, 10)
            }
            VStack(alignment: .leading, spacing: 4) {
                CategoryView(
                    category: checkIn.product.category,
                    subcategories: checkIn.product.subcategories,
                    servingStyle: checkIn.servingStyle
                )

                Text(checkIn.product.formatted(.fullName))
                    .font(.headline)
                    .textSelection(.enabled)
                    .foregroundColor(.primary)

                if let description = checkIn.product.description {
                    Text(description)
                        .font(.caption)
                        .textSelection(.enabled)
                }

                Text(checkIn.product.formatted(.brandOwner))
                    .font(.subheadline)
                    .textSelection(.enabled)
                    .foregroundColor(.secondary)
                    .contentShape(.rect)

                if let manufacturer = checkIn.variant?.manufacturer,
                   manufacturer.id != checkIn.product.subBrand.brand.brandOwner.id
                {
                    Text(manufacturer.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }

    @ViewBuilder private var checkInSection: some View {
        if !checkIn.isEmpty {
            if let rating = checkIn.rating {
                HStack {
                    RatingView(rating: rating)
                    Spacer()
                }
            }

            if let review = checkIn.review {
                Text(review)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }

            FlavorsView(flavors: checkIn.flavors.map(\.flavor))
            if let purchaseLocation = checkIn.purchaseLocation {
                Text("checkIn.location.purchasedFrom __\(purchaseLocation.name)__")
            }
        }
    }

    @ViewBuilder private var taggedProfilesSection: some View {
        if !checkIn.taggedProfiles.isEmpty {
            HStack {
                Text("checkIn.friends.tagged.label")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            HStack(spacing: 4) {
                ForEach(checkIn.taggedProfiles.map(\.profile)) { taggedProfile in
                    AvatarView(profile: taggedProfile)
                }
                Spacer()
            }
        }
    }

    private var footer: some View {
        HStack {
            if let checkInAt = checkIn.checkInAt {
                Text(checkInAt.formatted(.customRelativetime))
            } else {
                Text("checkIn.legacy.label")
            }
            Spacer()
        }
        .font(.caption).bold()
    }
}
