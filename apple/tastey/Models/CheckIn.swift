import Foundation

struct CheckIn: Identifiable {
    let id: Int
    let rating: Int?
    let review: String?
    let imageUrl: String?
    let createdAt: Date
    let profile: Profile
    let product: ProductJoined
    let checkInReactions: [CheckInReaction]
    let taggedProfiles: [Profile]
    let flavors: [Flavor]
    let variant: ProductVariant?
    
    func isEmpty() -> Bool {
        return [rating == nil, (review == nil || review == ""), flavors.count == 0].allSatisfy { $0 }
    }
    
    func getImageUrl() -> URL? {
        if let imageUrl = imageUrl {
            let bucketId = "migrated"
            let urlString = "\(Supabase.urlString)/storage/v1/object/public/\(bucketId)/\(imageUrl).jpeg"
            guard let url = URL(string: urlString) else { return nil }
            return url
        } else {
            return nil
        }
    }
    
}

extension CheckIn: Hashable {
    static func == (lhs: CheckIn, rhs: CheckIn) -> Bool {
        return lhs.id == rhs.id
    }
}

extension CheckIn: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case rating
        case review
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case profile = "profiles"
        case product = "products"
        case checkInReactions = "check_in_reactions"
        case taggedProfiles = "check_in_tagged_profiles"
        case flavors = "check_in_flavors"
        case variant = "product_variants"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        rating = try values.decodeIfPresent(Int.self, forKey: .rating)
        review = try values.decodeIfPresent(String.self, forKey: .review)
        imageUrl = try values.decodeIfPresent(String.self, forKey: .imageUrl)
        createdAt = try parseDate(from: try values.decode(String.self, forKey: .createdAt))
        profile = try values.decode(Profile.self, forKey: .profile)
        product = try values.decode(ProductJoined.self, forKey: .product)
        checkInReactions = try values.decode([CheckInReaction].self, forKey: .checkInReactions)
        taggedProfiles = try values.decode([CheckInTaggedProfile].self, forKey: .taggedProfiles).compactMap { $0.profile }
        flavors = try values.decode([CheckInFlavors].self, forKey: .flavors).compactMap { $0.flavor }
        variant = try values.decodeIfPresent(ProductVariant.self, forKey: .variant)
        
    }
}

struct NewCheckInParams: Encodable {
    let p_product_id: Int
    let p_rating: Int?
    let p_review: String?
    let p_manufacturer_id: Int?
    let p_serving_style_id: Int?
    let p_friend_ids: [String]?
    let p_flavor_ids: [Int]?
    
    init (productId: Int, rating: Int?, review: String?, manufacturerId: Int?, servingStyleId: Int?, friendIds: [UUID], flavorIds: [Int]?) {
        self.p_product_id = productId
        self.p_rating = rating
        self.p_review = review
        self.p_manufacturer_id = manufacturerId
        self.p_serving_style_id = servingStyleId
        self.p_friend_ids = friendIds.map { $0.uuidString.lowercased() }
        self.p_flavor_ids = flavorIds
    }
}

struct CheckInTaggedProfile: Decodable {
    let profile: Profile
    
    enum CodingKeys: String, CodingKey {
        case profile = "profiles"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        profile = try values.decode(Profile.self, forKey: .profile)
    }
}

struct CheckInFlavors: Decodable {
    let flavor: Flavor
    
    enum CodingKeys: String, CodingKey {
        case flavor = "flavors"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        flavor = try values.decode(Flavor.self, forKey: .flavor)
    }
}
