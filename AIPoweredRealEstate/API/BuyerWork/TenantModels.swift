//
//  TenantModels.swift
//  AIPoweredRealEstate
//
//  Created by Shireen on 18/08/26.
//

import Foundation

//API Response Models

//====Register Model

struct RegisterResponseModel: Codable {
    let message: String?
    let token: String?
    let user: User?
}

////====Profile Model
//struct UserModel: Codable {
//    let id: String?
//    let name: String?
//    let email: String?
//    let phone: String?
//    let role: String?
//    let profileImage: String?
//    let createdAt: String?
//}

////====Login Model
//struct LoginResponseModel: Decodable {
//    let success: Bool?
//    let message: String?
//    let token: String?
//    let user: UserModel?
//
//    enum CodingKeys: String, CodingKey {
//        case success, message, token, user, data
//    }
//
//    init(from decoder: Decoder) throws {
//        let c = try decoder.container(keyedBy: CodingKeys.self)
//        success = try c.decodeIfPresent(Bool.self, forKey: .success)
//        message = try c.decodeIfPresent(String.self, forKey: .message)
//        if let nested = try? c.nestedContainer(keyedBy: CodingKeys.self, forKey: .data) {
//            token = try nested.decodeIfPresent(String.self, forKey: .token)
//                ?? (try? c.decodeIfPresent(String.self, forKey: .token)) ?? nil
//            user = try nested.decodeIfPresent(UserModel.self, forKey: .user)
//                ?? (try? c.decodeIfPresent(UserModel.self, forKey: .user)) ?? nil
//        } else {
//            token = try c.decodeIfPresent(String.self, forKey: .token)
//            user = try c.decodeIfPresent(UserModel.self, forKey: .user)
//        }
//    }
//
//    var resolvedRole: String {
//        (user?.role ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
//    }
//}

////Update Profile Model
//struct UpdateProfileResponseModel: Codable {
//    let message: String?
//    let user: User?
//}
//
////Change Password Model
//struct ChangePasswordResponseModel: Codable {
//    let message: String?
//}


//Dashboard filter
struct FilterOptionsModel: Codable {
    let success: Bool?
    let message: String?
    let data: FilterOptionsData?
}

struct FilterOptionsData: Codable {
    let language: String?
    let listingTypes: [FilterOption]?
    let propertyTypes: [FilterOption]?
    let furnishedStatuses: [FilterOption]?
    let amenities: [Amenity]?

    enum CodingKeys: String, CodingKey {
        case language
        case listingTypes, listing_types
        case propertyTypes, property_types
        case furnishedStatuses, furnished_statuses
        case amenities
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        language = try c.decodeIfPresent(String.self, forKey: .language)
        listingTypes = try c.decodeIfPresent([FilterOption].self, forKey: .listingTypes)
            ?? c.decodeIfPresent([FilterOption].self, forKey: .listing_types)
        propertyTypes = try c.decodeIfPresent([FilterOption].self, forKey: .propertyTypes)
            ?? c.decodeIfPresent([FilterOption].self, forKey: .property_types)
        furnishedStatuses = try c.decodeIfPresent([FilterOption].self, forKey: .furnishedStatuses)
            ?? c.decodeIfPresent([FilterOption].self, forKey: .furnished_statuses)
        amenities = try c.decodeIfPresent([Amenity].self, forKey: .amenities)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(language, forKey: .language)
        try c.encodeIfPresent(listingTypes, forKey: .listingTypes)
        try c.encodeIfPresent(propertyTypes, forKey: .propertyTypes)
        try c.encodeIfPresent(furnishedStatuses, forKey: .furnishedStatuses)
        try c.encodeIfPresent(amenities, forKey: .amenities)
    }

    init(
        language: String?,
        listingTypes: [FilterOption]?,
        propertyTypes: [FilterOption]?,
        furnishedStatuses: [FilterOption]?,
        amenities: [Amenity]?
    ) {
        self.language = language
        self.listingTypes = listingTypes
        self.propertyTypes = propertyTypes
        self.furnishedStatuses = furnishedStatuses
        self.amenities = amenities
    }

    var dashboardChips: [DashboardFilterChip] {
        dashboardGroups.flatMap(\.options)
    }

    var dashboardGroups: [DashboardFilterGroup] {
        var groups: [DashboardFilterGroup] = []
        let listing = (listingTypes ?? []).compactMap { DashboardFilterChip(kind: .listingType, option: $0) }
        if !listing.isEmpty {
            groups.append(DashboardFilterGroup(key: "listingTypes", kind: .listingType, options: listing))
        }
        let types = (propertyTypes ?? []).compactMap { DashboardFilterChip(kind: .propertyType, option: $0) }
        if !types.isEmpty {
            groups.append(DashboardFilterGroup(key: "propertyTypes", kind: .propertyType, options: types))
        }
        let furnished = (furnishedStatuses ?? []).compactMap { DashboardFilterChip(kind: .furnished, option: $0) }
        if !furnished.isEmpty {
            groups.append(DashboardFilterGroup(key: "furnishedStatuses", kind: .furnished, options: furnished))
        }
        let amenityChips = (amenities ?? []).compactMap { amenity -> DashboardFilterChip? in
            let name = amenity.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let id = amenity.id?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !name.isEmpty || !id.isEmpty else { return nil }
            return DashboardFilterChip(kind: .amenity, value: id.isEmpty ? name : id, label: name.isEmpty ? id : name)
        }
        if !amenityChips.isEmpty {
            groups.append(DashboardFilterGroup(key: "amenities", kind: .amenity, options: amenityChips))
        }
        return groups
    }
}

struct FilterOption: Codable {
    let value: String?
    let label: String?
}

struct Amenity: Codable {
    let id: String?
    let name: String?
}

enum DashboardFilterKind: String {
    case listingType
    case propertyType
    case furnished
    case amenity

    var apiParameterKey: String {
        switch self {
        case .listingType: return "listingType"
        case .propertyType: return "propertyType"
        case .furnished: return "furnishedStatus"
        case .amenity: return "amenities"
        }
    }

    var displayTitle: String { apiParameterKey.localizedAPIKey }
}

struct DashboardFilterGroup {
    let key: String
    let kind: DashboardFilterKind
    let options: [DashboardFilterChip]

    var firstOption: DashboardFilterChip? { options.first }
}

extension Array where Element == DashboardFilterGroup {
    func selectedFiltersKeepingFirst(
        _ current: [DashboardFilterKind: [DashboardFilterChip]]
    ) -> [DashboardFilterKind: [DashboardFilterChip]] {
        current.filter { !$0.value.isEmpty }
    }
}

struct DashboardFilterChip: Equatable {
    let kind: DashboardFilterKind
    let value: String
    let label: String

    init(kind: DashboardFilterKind, value: String, label: String) {
        self.kind = kind
        self.value = value
        self.label = label
    }

    init?(kind: DashboardFilterKind, option: FilterOption) {
        let value = (option.value ?? option.label ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let label = (option.label ?? option.value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        self.kind = kind
        self.value = value
        self.label = label.isEmpty ? value : label
    }

    func apply(to request: inout PropertyFilterRequest) {
        switch kind {
        case .listingType:
            request.listingType = value.apiListingType
        case .propertyType:
            request.propertyType = value.apiPropertyType
        case .furnished:
            request.furnishedStatus = value.apiFurnishedStatus
        case .amenity:
            var current = request.amenities ?? []
            let alreadySelected = current.contains {
                $0.caseInsensitiveCompare(value) == .orderedSame
            }
            if !alreadySelected {
                current.append(value)
            }
            request.amenities = current
        }
    }
}

struct PropertyFilterRequest {
    var listingType: String?
    var location: String?
    var minPrice: Int?
    var maxPrice: Int?
    var propertyType: String?
    var bedrooms: Int?
    var bathrooms: Int?
    var furnishedStatus: String?
    var amenities: [String]?
    var minSize: Int?
    var maxSize: Int?
    var page: Int?
    var limit: Int?

    static func dashboard(chip: DashboardFilterChip?) -> PropertyFilterRequest {
        dashboard(selections: [chip].compactMap { $0 })
    }

    static func dashboard(selections: [DashboardFilterChip]) -> PropertyFilterRequest {
        var request = PropertyFilterRequest()
        request.amenities = []
        selections.forEach { $0.apply(to: &request) }
        return request
    }

    mutating func apply(_ criteria: PropertySearchCriteria) {
        if listingType == nil, let value = criteria.listingType, value.isEmpty == false {
            listingType = value.apiListingType
        }
        if location == nil {
            let value = criteria.location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if value.isEmpty == false { location = value }
        }
        if propertyType == nil, let value = criteria.propertyType, value.isEmpty == false {
            propertyType = value.apiPropertyType
        }
        if minPrice == nil { minPrice = criteria.minPrice }
        if maxPrice == nil { maxPrice = criteria.maxPrice }
        if bedrooms == nil { bedrooms = criteria.minBedrooms }
        if bathrooms == nil { bathrooms = criteria.minBathrooms }
        if furnishedStatus == nil, let furnished = criteria.furnished {
            furnishedStatus = furnished ? "FURNISHED" : "UNFURNISHED"
        }
        if (amenities == nil || amenities?.isEmpty == true), criteria.amenities.isEmpty == false {
            amenities = Array(criteria.amenities)
        }
        if minSize == nil { minSize = criteria.minArea }
        if maxSize == nil { maxSize = criteria.maxArea }
    }

    func asParameters() -> [String: Any] {
        var param: [String: Any] = [:]
        param["listingType"] = listingType ?? ""
        if let location, location.isEmpty == false { param["location"] = location }
        param["minPrice"] = minPrice ?? ""
        param["maxPrice"] = maxPrice ?? ""
        param["propertyType"] = propertyType ?? ""
        param["bedrooms"] = bedrooms ?? ""
        param["bathrooms"] = bathrooms ?? ""
        param["furnishedStatus"] = furnishedStatus ?? ""
        param["amenities"] = amenities ?? []
        param["minSize"] = minSize ?? ""
        param["maxSize"] = maxSize ?? ""
        if let limit { param["limit"] = limit }
        return param
    }

    mutating func apply(_ extra: PropertyRangeFilters) {
        bedrooms = extra.bedrooms
        bathrooms = extra.bathrooms
        minPrice = extra.minPrice
        maxPrice = extra.maxPrice
        minSize = extra.minSize
        maxSize = extra.maxSize
    }
}

struct PropertySearchResponse: Decodable {
    let success: Bool?
    let message: String?
    let data: PropertyFilterData?
}

struct PropertyCompareResponse: Decodable {
    let success: Bool?
    let message: String?
    let data: PropertyCompareData?
    let rootProperties: [APIProperty]?

    enum CodingKeys: String, CodingKey {
        case success, message, data, properties
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        success = try c.decodeIfPresent(Bool.self, forKey: .success)
        message = try c.decodeIfPresent(String.self, forKey: .message)
        data = try c.decodeIfPresent(PropertyCompareData.self, forKey: .data)
        rootProperties = try c.decodeIfPresent([APIProperty].self, forKey: .properties)
    }

    var properties: [APIProperty] {
        if let data { return data.properties }
        return rootProperties ?? []
    }
}

struct PropertyCompareData: Decodable {
    let properties: [APIProperty]

    enum CodingKeys: String, CodingKey {
        case properties, comparison, items, results
    }

    init(from decoder: Decoder) throws {
        if let array = try? decoder.singleValueContainer().decode([APIProperty].self) {
            properties = array
            return
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        properties = try c.decodeIfPresent([APIProperty].self, forKey: .properties)
            ?? c.decodeIfPresent([APIProperty].self, forKey: .comparison)
            ?? c.decodeIfPresent([APIProperty].self, forKey: .items)
            ?? c.decodeIfPresent([APIProperty].self, forKey: .results)
            ?? []
    }
}

struct PropertyDetailsResponse: Decodable {
    let success: Bool?
    let message: String?
    let data: PropertyDetailsData?
}

struct PropertyDetailsData: Decodable {
    let language: String?
    let property: APIProperty?
}

struct RecentlyViewedResponse: Decodable {
    let success: Bool?
    let message: String?
    let data: PropertiesListData?
    let rootProperties: [APIProperty]?
    let rootFavorites: [APIProperty]?
    let rootRecentlyViewed: [APIRecentlyViewedRecord]?

    enum CodingKeys: String, CodingKey {
        case success, message, data, properties, favorites, recentlyViewed
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        success = try c.decodeIfPresent(Bool.self, forKey: .success)
        message = try c.decodeIfPresent(String.self, forKey: .message)
        data = try c.decodeIfPresent(PropertiesListData.self, forKey: .data)
        rootProperties = try c.decodeIfPresent([APIProperty].self, forKey: .properties)
        rootFavorites = try c.decodeIfPresent([APIProperty].self, forKey: .favorites)
        rootRecentlyViewed = try c.decodeIfPresent([APIRecentlyViewedRecord].self, forKey: .recentlyViewed)
    }

    var properties: [APIProperty] {
        if let data { return data.items }
        return rootProperties ?? rootFavorites ?? []
    }

    var viewedItems: [PropertyItem] {
        if let records = data?.recentlyViewed, records.isEmpty == false {
            return records.map { $0.asPropertyItem() }
        }
        if let records = rootRecentlyViewed, records.isEmpty == false {
            return records.map { $0.asPropertyItem() }
        }
        return properties.map { $0.asPropertyItem() }
    }
}

struct PropertiesListData: Decodable {
    let count: Int?
    let language: String?
    let properties: [APIProperty]?
    let favorites: [APIProperty]?
    let recentlyViewed: [APIRecentlyViewedRecord]?

    var items: [APIProperty] {
        if let properties { return properties }
        if let favorites { return favorites }
        return recentlyViewed?.map(\.property) ?? []
    }
}

struct APIRecentlyViewedRecord: Decodable {
    let viewId: String
    let property: APIProperty

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case altId = "id"
        case property, propertyId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let wrapperId = try c.decodeIfPresent(String.self, forKey: .id)
            ?? c.decodeIfPresent(String.self, forKey: .altId)
            ?? ""
        if let nested = (try? c.decode(APIProperty.self, forKey: .property))
            ?? (try? c.decode(APIProperty.self, forKey: .propertyId)) {
            viewId = wrapperId.isEmpty ? nested.id : wrapperId
            property = nested
            return
        }
        property = try APIProperty(from: decoder)
        viewId = wrapperId.isEmpty ? property.id : wrapperId
    }

    func asPropertyItem() -> PropertyItem {
        var item = property.asPropertyItem()
        item.recentlyViewedId = viewId
        return item
    }
}

struct APIStatusResponse: Decodable {
    let success: Bool?
    let message: String?
}

struct FavoriteToggleResponse: Decodable {
    let success: Bool?
    let message: String?
    let isFav: Bool?

    enum CodingKeys: String, CodingKey {
        case success, message, data
        case isFav, isFavorite, favorited, liked
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        success = try c.decodeIfPresent(Bool.self, forKey: .success)
        message = try c.decodeIfPresent(String.self, forKey: .message)
        if let value = try Self.decodeFlag(c) {
            isFav = value
            return
        }
        if let nested = try? c.nestedContainer(keyedBy: CodingKeys.self, forKey: .data),
           let value = try Self.decodeFlag(nested) {
            isFav = value
            return
        }
        isFav = nil
    }

    private static func decodeFlag(_ c: KeyedDecodingContainer<CodingKeys>) throws -> Bool? {
        if let v = try c.decodeIfPresent(Bool.self, forKey: .isFav) { return v }
        if let v = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) { return v }
        if let v = try c.decodeIfPresent(Bool.self, forKey: .favorited) { return v }
        if let v = try c.decodeIfPresent(Bool.self, forKey: .liked) { return v }
        return nil
    }
}

struct PropertyFilterData: Decodable {
    let language: String?
    let count: Int?
    let properties: [APIProperty]?
    let page: Int?
    let limit: Int?
    let total: Int?
    let totalPages: Int?
    let hasMore: Bool?

    enum CodingKeys: String, CodingKey {
        case language, count, properties, page, limit, total
        case totalPages, total_pages
        case hasMore, has_more, nextPage, next_page
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        language = try c.decodeIfPresent(String.self, forKey: .language)
        count = Self.decodeInt(c, keys: [.count, .total])
        properties = try c.decodeIfPresent([APIProperty].self, forKey: .properties)
        page = Self.decodeInt(c, keys: [.page])
        limit = Self.decodeInt(c, keys: [.limit])
        total = Self.decodeInt(c, keys: [.total, .count])
        totalPages = Self.decodeInt(c, keys: [.totalPages, .total_pages])
        if let flag = try c.decodeIfPresent(Bool.self, forKey: .hasMore)
            ?? c.decodeIfPresent(Bool.self, forKey: .has_more) {
            hasMore = flag
        } else if let next = Self.decodeInt(c, keys: [.nextPage, .next_page]) {
            hasMore = next > 0
        } else {
            hasMore = nil
        }
    }

    private static func decodeInt(_ c: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> Int? {
        for key in keys {
            if let value = try? c.decodeIfPresent(Int.self, forKey: key) { return value }
            if let value = try? c.decodeIfPresent(Double.self, forKey: key) { return Int(value) }
            if let value = try? c.decodeIfPresent(String.self, forKey: key), let intValue = Int(value) {
                return intValue
            }
        }
        return nil
    }
}

struct PropertySearchPage {
    let items: [PropertyItem]
    let page: Int
    let limit: Int
    let total: Int?
    let hasMore: Bool
}

struct APIProperty: Decodable {
    let id: String
    let title: String
    let description: String?
    let location: APIPropertyLocation?
    let ownerContact: APIOwnerContact?
    let agentDetails: APIOwnerContact?
    let propertyType: String?
    let listingType: String?
    let price: Double?
    let bedrooms: Int?
    let bathrooms: Int?
    let size: Double?
    let sizeUnit: String?
    let furnishedStatus: String?
    let amenities: [APIAmenityItem]?
    let images: [String]?
    let isFav: Bool?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case altId = "id"
        case title, description, location, ownerContact, agentDetails
        case propertyType, listingType, price, bedrooms, bathrooms
        case size, sizeUnit, furnishedStatus, amenities, images, isFav
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id)
            ?? c.decodeIfPresent(String.self, forKey: .altId)
            ?? ""
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try c.decodeIfPresent(String.self, forKey: .description)
        location = try c.decodeIfPresent(APIPropertyLocation.self, forKey: .location)
        ownerContact = try c.decodeIfPresent(APIOwnerContact.self, forKey: .ownerContact)
        agentDetails = try c.decodeIfPresent(APIOwnerContact.self, forKey: .agentDetails)
        propertyType = try c.decodeIfPresent(String.self, forKey: .propertyType)
        listingType = try c.decodeIfPresent(String.self, forKey: .listingType)
        price = Self.decodeFlexibleDouble(c, key: .price)
        bedrooms = Self.decodeFlexibleInt(c, key: .bedrooms)
        bathrooms = Self.decodeFlexibleInt(c, key: .bathrooms)
        size = Self.decodeFlexibleDouble(c, key: .size)
        sizeUnit = try c.decodeIfPresent(String.self, forKey: .sizeUnit)
        furnishedStatus = try c.decodeIfPresent(String.self, forKey: .furnishedStatus)
        amenities = try c.decodeIfPresent([APIAmenityItem].self, forKey: .amenities)
        images = try c.decodeIfPresent([String].self, forKey: .images)
        isFav = try c.decodeIfPresent(Bool.self, forKey: .isFav)
    }

    private static func decodeFlexibleDouble(_ c: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Double? {
        if let value = try? c.decodeIfPresent(Double.self, forKey: key) { return value }
        if let value = try? c.decodeIfPresent(Int.self, forKey: key) { return Double(value) }
        if let value = try? c.decodeIfPresent(String.self, forKey: key) { return Double(value) }
        return nil
    }

    private static func decodeFlexibleInt(_ c: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Int? {
        if let value = try? c.decodeIfPresent(Int.self, forKey: key) { return value }
        if let value = try? c.decodeIfPresent(Double.self, forKey: key) { return Int(value) }
        if let value = try? c.decodeIfPresent(String.self, forKey: key) { return Int(value) }
        return nil
    }

    func asPropertyItem() -> PropertyItem {
       
        let listing = listingType ?? "Buy"
        let type = propertyType ?? "House"
        let priceValue = Int(price ?? 0)
        let beds = bedrooms ?? 0
        let baths = bathrooms ?? 0
        let areaValue = Int(size ?? 0)
        let unit = (sizeUnit ?? "sq ft").trimmingCharacters(in: .whitespacesAndNewlines)
        let area = areaValue > 0 ? "\(areaValue) \(unit)" : ""
        let city = [location?.area, location?.city].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
        let gallery = (images ?? []).map(Constant.mediaURL)
        let rawFurnished = (furnishedStatus ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let furnished = rawFurnished.lowercased().contains("furnish")
            && !rawFurnished.lowercased().contains("unfurnish")
       
        let amenityNames = (amenities ?? []).compactMap { item in
            let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return name.isEmpty ? nil : name
        }
        
        let contact = agentDetails ?? ownerContact
        
        return PropertyItem(
            id: id,
            title: title,
            location: city.isEmpty ? (location?.address ?? "") : city,
            priceText: Self.priceText(priceValue, listingType: listing),
            priceValue: priceValue,
            listingType: listing,
            propertyType: type,
            bedrooms: beds,
            bathrooms: baths,
            area: area,
            areaValue: areaValue,
            summary: description ?? "",
            amenities: amenityNames,
            isFurnished: furnished,
            furnishedStatus: rawFurnished,
            source: "SpeddyProp",
            listedDate: Date(),
            galleryIcons: ["house.fill"],
            agentName: contact?.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Listing agent",
            agentAgency: contact?.email ?? "",
            iconName: "house.fill",
            imageName: gallery.first ?? "",
            remoteGallery: gallery,
            isFav: isFav ?? false
        )
        
    }

    private static func priceText(_ value: Int, listingType: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let amount = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        if listingType.apiListingType == "RENT" {
            return "$\(amount)/mo"
        }
        return "$\(amount)"
    }
    
}

struct APIPropertyLocation: Decodable {
    let address: String?
    let area: String?
    let city: String?
    let state: String?
    let country: String?
    let pincode: String?
}

struct APIOwnerContact: Decodable {
    let name: String?
    let phone: String?
    let email: String?
}

struct APIAmenityItem: Decodable {
   
    let id: String?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
    }
    
}

struct AgentsListResponse: Decodable {
    let success: Bool?
    let message: String?
    let data: AgentsListData?
    let rootAgents: [APIAgent]?

    enum CodingKeys: String, CodingKey {
        case success, message, data, agents, users, results
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        success = try c.decodeIfPresent(Bool.self, forKey: .success)
        message = try c.decodeIfPresent(String.self, forKey: .message)
        data = try c.decodeIfPresent(AgentsListData.self, forKey: .data)
        rootAgents = try c.decodeIfPresent([APIAgent].self, forKey: .agents)
            ?? c.decodeIfPresent([APIAgent].self, forKey: .users)
            ?? c.decodeIfPresent([APIAgent].self, forKey: .results)
    }

    var agents: [APIAgent] {
        if let data {
            return data.agents
        }
        return rootAgents ?? []
    }
}

struct AgentsListData: Decodable {
    let agents: [APIAgent]

    enum CodingKeys: String, CodingKey {
        case agents, users, results, list, data
    }

    init(from decoder: Decoder) throws {
        if let array = try? decoder.singleValueContainer().decode([APIAgent].self) {
            agents = array
            return
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        agents = try c.decodeIfPresent([APIAgent].self, forKey: .agents)
            ?? c.decodeIfPresent([APIAgent].self, forKey: .users)
            ?? c.decodeIfPresent([APIAgent].self, forKey: .results)
            ?? c.decodeIfPresent([APIAgent].self, forKey: .list)
            ?? c.decodeIfPresent([APIAgent].self, forKey: .data)
            ?? []
    }
}

struct APIAgent: Decodable {
    let id: String
    let name: String
    let agency: String
    let email: String
    let phone: String
    let whatsapp: String?
    let serviceAreas: [String]
    let specialization: [String]
    let languages: [String]
    let rating: Double
    let totalDeals: Int
    let responseTimeHours: Int
    let availabilityStatus: String
    let profileImageURL: String?
    let isVerified: Bool
    let isAvailable: Bool
    let licenseNumber: String
    let documentURL: String?
    let status: String
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case altId = "id"
        case name, fullName, agency, agencyName, agency_name, company, companyName, email, phone, mobile, whatsapp
        case serviceAreas, locations, areas, specialization, specializations
        case languages, rating, totalDeals, deals, responseTimeHours, responseTime
        case availabilityStatus, status, profileImageURL, profileImage, avatar, image
        case isVerified, verified, isAvailable, available, isActive, is_active
        case licenseNumber, license_number, document
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id)
            ?? c.decodeIfPresent(String.self, forKey: .altId)
            ?? ""
        name = try c.decodeIfPresent(String.self, forKey: .name)
            ?? c.decodeIfPresent(String.self, forKey: .fullName)
            ?? ""
        agency = try c.decodeIfPresent(String.self, forKey: .agency)
            ?? c.decodeIfPresent(String.self, forKey: .agencyName)
            ?? c.decodeIfPresent(String.self, forKey: .agency_name)
            ?? c.decodeIfPresent(String.self, forKey: .company)
            ?? c.decodeIfPresent(String.self, forKey: .companyName)
            ?? ""
        email = try c.decodeIfPresent(String.self, forKey: .email) ?? ""
        phone = try c.decodeIfPresent(String.self, forKey: .phone)
            ?? c.decodeIfPresent(String.self, forKey: .mobile)
            ?? ""
        whatsapp = try c.decodeIfPresent(String.self, forKey: .whatsapp)
        serviceAreas = try c.decodeIfPresent([String].self, forKey: .serviceAreas)
            ?? c.decodeIfPresent([String].self, forKey: .locations)
            ?? c.decodeIfPresent([String].self, forKey: .areas)
            ?? []
        specialization = try c.decodeIfPresent([String].self, forKey: .specialization)
            ?? c.decodeIfPresent([String].self, forKey: .specializations)
            ?? []
        languages = try c.decodeIfPresent([String].self, forKey: .languages) ?? []
        rating = Self.decodeDouble(c, keys: [.rating]) ?? 0
        totalDeals = Self.decodeInt(c, keys: [.totalDeals, .deals]) ?? 0
        responseTimeHours = Self.decodeInt(c, keys: [.responseTimeHours, .responseTime]) ?? 0
        status = (try c.decodeIfPresent(String.self, forKey: .status) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        isActive = try c.decodeIfPresent(Bool.self, forKey: .isActive)
            ?? c.decodeIfPresent(Bool.self, forKey: .is_active)
            ?? true
        availabilityStatus = try c.decodeIfPresent(String.self, forKey: .availabilityStatus)
            ?? (isActive ? "active" : "inactive")
        profileImageURL = try c.decodeIfPresent(String.self, forKey: .profileImageURL)
            ?? c.decodeIfPresent(String.self, forKey: .profileImage)
            ?? c.decodeIfPresent(String.self, forKey: .avatar)
            ?? c.decodeIfPresent(String.self, forKey: .image)
        licenseNumber = try c.decodeIfPresent(String.self, forKey: .licenseNumber)
            ?? c.decodeIfPresent(String.self, forKey: .license_number)
            ?? ""
        documentURL = try c.decodeIfPresent(String.self, forKey: .document)
        isVerified = try c.decodeIfPresent(Bool.self, forKey: .isVerified)
            ?? c.decodeIfPresent(Bool.self, forKey: .verified)
            ?? (status.lowercased() == "approved")
        isAvailable = try c.decodeIfPresent(Bool.self, forKey: .isAvailable)
            ?? c.decodeIfPresent(Bool.self, forKey: .available)
            ?? isActive
    }

    private static func decodeDouble(
        _ c: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]
    ) -> Double? {
        for key in keys {
            if let value = try? c.decodeIfPresent(Double.self, forKey: key) { return value }
            if let value = try? c.decodeIfPresent(Int.self, forKey: key) { return Double(value) }
            if let value = try? c.decodeIfPresent(String.self, forKey: key) { return Double(value) }
        }
        return nil
    }

    private static func decodeInt(
        _ c: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]
    ) -> Int? {
        for key in keys {
            if let value = try? c.decodeIfPresent(Int.self, forKey: key) { return value }
            if let value = try? c.decodeIfPresent(Double.self, forKey: key) { return Int(value) }
            if let value = try? c.decodeIfPresent(String.self, forKey: key) { return Int(value) }
        }
        return nil
    }

    func asPlatformRealtor() -> PlatformRealtor {
        PlatformRealtor(
            id: id,
            name: name.isEmpty ? "Agent".localized : name,
            agency: agency,
            email: email,
            phone: phone,
            whatsapp: whatsapp ?? phone,
            serviceAreas: serviceAreas,
            specialization: specialization,
            locationExpertise: serviceAreas,
            languages: languages.isEmpty ? ["English"] : languages,
            rating: rating,
            totalDeals: totalDeals,
            responseTimeHours: responseTimeHours,
            availabilityStatus: availabilityStatus.isEmpty ? "active" : availabilityStatus,
            profileImageURL: profileImageURL.map { Constant.mediaURL($0) },
            isVerified: isVerified,
            isAvailable: isAvailable,
            openRequestCount: 0,
            licenseNumber: licenseNumber,
            documentURL: documentURL.map { Constant.mediaURL($0) },
            status: status,
            isActive: isActive
        )
    }
}

struct MyLeadsResponse: Decodable {
    let success: Bool?
    let message: String?
    let data: MyLeadsData?
    let rootLeads: [APIMyLead]?

    enum CodingKeys: String, CodingKey {
        case success, message, data, leads, results
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        success = try c.decodeIfPresent(Bool.self, forKey: .success)
        message = try c.decodeIfPresent(String.self, forKey: .message)
        data = try c.decodeIfPresent(MyLeadsData.self, forKey: .data)
        rootLeads = try c.decodeIfPresent([APIMyLead].self, forKey: .leads)
            ?? c.decodeIfPresent([APIMyLead].self, forKey: .results)
    }

    var leads: [APIMyLead] {
        if let data { return data.leads }
        return rootLeads ?? []
    }
}

struct MyLeadsData: Decodable {
    let leads: [APIMyLead]

    enum CodingKeys: String, CodingKey {
        case leads, results, list, data, items, docs
    }

    init(from decoder: Decoder) throws {
        if let array = try? decoder.singleValueContainer().decode([APIMyLead].self) {
            leads = array
            return
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        var decoded: [APIMyLead] = []
        for key in [CodingKeys.leads, .results, .list, .items, .docs, .data] {
            if let value = try c.decodeIfPresent([APIMyLead].self, forKey: key) {
                decoded = value
                break
            }
        }
        leads = decoded
    }
}

struct APIMyLead: Decodable {
    let id: String
    let leadCode: String
    let statusRaw: String
    let description: String
    let agentId: String?
    let agentName: String?
    let createdAt: Date
    let buyerName: String
    let buyerEmail: String
    let buyerPhone: String
    let propertyId: String?
    let propertyTitle: String?

    private struct NestedPerson: Decodable {
        let id: String?
        let name: String?
        let email: String?
        let phone: String?

        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case altId = "id"
            case name, fullName, email, phone, mobile
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decodeIfPresent(String.self, forKey: .id)
                ?? c.decodeIfPresent(String.self, forKey: .altId)
            name = try c.decodeIfPresent(String.self, forKey: .name)
                ?? c.decodeIfPresent(String.self, forKey: .fullName)
            email = try c.decodeIfPresent(String.self, forKey: .email)
            phone = try c.decodeIfPresent(String.self, forKey: .phone)
                ?? c.decodeIfPresent(String.self, forKey: .mobile)
        }
    }

    private struct NestedProperty: Decodable {
        let id: String?
        let title: String?
        let location: String?

        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case altId = "id"
            case title, name, location, address
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decodeIfPresent(String.self, forKey: .id)
                ?? c.decodeIfPresent(String.self, forKey: .altId)
            title = try c.decodeIfPresent(String.self, forKey: .title)
                ?? c.decodeIfPresent(String.self, forKey: .name)
            location = try c.decodeIfPresent(String.self, forKey: .location)
                ?? c.decodeIfPresent(String.self, forKey: .address)
        }
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case altId = "id"
        case leadCode, lead_code, code
        case status
        case description, requirements, message, notes
        case agent, agentId, agent_id, assignedAgent, assignedRealtor
        case agentName, agent_name
        case createdAt, created_at, date
        case name, buyerName, email, buyerEmail, phone, buyerPhone
        case buyer, user, client, tenant
        case property, propertyId, property_id
        case propertyTitle, property_title
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.firstString(c, [.id, .altId]) ?? UUID().uuidString
        leadCode = Self.firstString(c, [.leadCode, .lead_code, .code]) ?? ""
        statusRaw = try c.decodeIfPresent(String.self, forKey: .status) ?? "new"
        description = Self.firstString(c, [.description, .requirements, .message, .notes]) ?? ""

        var parsedAgentId: String?
        var parsedAgentName: String?
        if let agent = try? c.decodeIfPresent(APIAgent.self, forKey: .agent) {
            parsedAgentId = agent.id
            parsedAgentName = agent.name
        } else if let agent = try? c.decodeIfPresent(APIAgent.self, forKey: .assignedAgent) {
            parsedAgentId = agent.id
            parsedAgentName = agent.name
        } else if let agent = try? c.decodeIfPresent(APIAgent.self, forKey: .assignedRealtor) {
            parsedAgentId = agent.id
            parsedAgentName = agent.name
        } else {
            parsedAgentId = Self.firstString(c, [.agent, .agentId, .agent_id])
        }
        if parsedAgentName == nil {
            parsedAgentName = Self.firstString(c, [.agentName, .agent_name])
        }
        agentId = parsedAgentId
        agentName = parsedAgentName

        createdAt = Self.decodeDate(c, keys: [.createdAt, .created_at, .date]) ?? Date()

        let person = Self.firstValue(NestedPerson.self, c, [.buyer, .user, .client, .tenant])
        buyerName = Self.firstString(c, [.buyerName, .name]) ?? person?.name ?? ""
        buyerEmail = Self.firstString(c, [.buyerEmail, .email]) ?? person?.email ?? ""
        buyerPhone = Self.firstString(c, [.buyerPhone, .phone]) ?? person?.phone ?? ""

        let nestedProperty = try? c.decodeIfPresent(NestedProperty.self, forKey: .property)
        propertyId = Self.firstString(c, [.propertyId, .property_id])
            ?? nestedProperty?.id
            ?? (try? c.decodeIfPresent(String.self, forKey: .property))
        let nestedTitle = [nestedProperty?.title, nestedProperty?.location]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
        propertyTitle = Self.firstString(c, [.propertyTitle, .property_title])
            ?? (nestedTitle.isEmpty ? nil : nestedTitle)
    }

    private static func firstString(
        _ c: KeyedDecodingContainer<CodingKeys>,
        _ keys: [CodingKeys]
    ) -> String? {
        firstValue(String.self, c, keys)
    }

    private static func firstValue<T: Decodable>(
        _ type: T.Type,
        _ c: KeyedDecodingContainer<CodingKeys>,
        _ keys: [CodingKeys]
    ) -> T? {
        for key in keys {
            if let value = try? c.decodeIfPresent(type, forKey: key) {
                return value
            }
        }
        return nil
    }

    private static func decodeDate(
        _ c: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]
    ) -> Date? {
        for key in keys {
            if let date = try? c.decodeIfPresent(Date.self, forKey: key) { return date }
            if let value = try? c.decodeIfPresent(String.self, forKey: key) {
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = iso.date(from: value) { return date }
                iso.formatOptions = [.withInternetDateTime]
                if let date = iso.date(from: value) { return date }
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                if let date = formatter.date(from: value) { return date }
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                if let date = formatter.date(from: value) { return date }
            }
            if let value = try? c.decodeIfPresent(Double.self, forKey: key) {
                return Date(timeIntervalSince1970: value > 10_000_000_000 ? value / 1000 : value)
            }
        }
        return nil
    }

    private var mappedStatus: LeadStatus {
        switch statusRaw.lowercased() {
        case "assigned", "pending": return .assigned
        case "contacted", "approved": return .contacted
        case "viewing": return .viewing
        case "closed", "completed", "qualified", "won": return .closed
        case "lost", "rejected", "cancelled", "canceled": return .lost
        default: return .new
        }
    }

    func asPlatformLead(useLocalAccount: Bool = true) -> PlatformLead {
        let accountName = useLocalAccount ? TenantAccount.shared.name : ""
        let accountEmail = useLocalAccount ? TenantAccount.shared.email : ""
        let accountPhone = useLocalAccount ? TenantAccount.shared.phone : ""
        let requirementText: String = {
            let title = propertyTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let body = description.trimmingCharacters(in: .whitespacesAndNewlines)
            if title.isEmpty { return body }
            if body.isEmpty || body.caseInsensitiveCompare(title) == .orderedSame { return title }
            return "\(title)\n\(body)"
        }()
        return PlatformLead(
            id: id,
            leadCode: leadCode,
            buyerId: buyerEmail.isEmpty ? accountEmail : buyerEmail,
            assignedRealtorId: agentId,
            assignedAgentName: agentName,
            propertyId: propertyId,
            requirements: requirementText,
            budgetMin: nil,
            budgetMax: nil,
            preferredLanguage: useLocalAccount ? TenantAccount.shared.language : nil,
            preferredContactMethod: .email,
            status: mappedStatus,
            source: .propertyListing,
            assignmentMetadata: nil,
            contactHistory: [],
            createdAt: createdAt,
            updatedAt: createdAt,
            buyerName: buyerName.isEmpty ? accountName : buyerName,
            buyerEmail: buyerEmail.isEmpty ? accountEmail : buyerEmail,
            buyerPhone: buyerPhone.isEmpty ? accountPhone : buyerPhone,
            assistanceRequestId: nil,
            apiStatus: statusRaw
        )
    }
}

struct AIChatResponseModel: Decodable {
    let success: Bool?
    let message: String?
    let data: AIChatData?
}

struct AIChatData: Decodable {
    let langInput: String?
    let savedSearchId: String?
    let message: String?
    let extractedFilters: AIExtractedFilters?
    let totalFound: Int?
    let properties: [APIProperty]

    enum CodingKeys: String, CodingKey {
        case langInput, savedSearchId, message, extractedFilters, totalFound, properties
    }

    init(message: String?, properties: [APIProperty]) {
        langInput = nil
        savedSearchId = nil
        self.message = message
        extractedFilters = nil
        totalFound = properties.count
        self.properties = properties
    }

    init(
        langInput: String? = nil,
        savedSearchId: String? = nil,
        message: String?,
        extractedFilters: AIExtractedFilters? = nil,
        totalFound: Int? = nil,
        properties: [APIProperty]
    ) {
        self.langInput = langInput
        self.savedSearchId = savedSearchId
        self.message = message
        self.extractedFilters = extractedFilters
        self.totalFound = totalFound
        self.properties = properties
    }

    static func merged(from response: AIChatResponseModel, userMessage: String) -> AIChatData {
        let data = response.data
        let user = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        func isEcho(_ text: String) -> Bool {
            text.caseInsensitiveCompare(user) == .orderedSame
        }
        let candidates = [response.message, data?.message]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
        let reply = candidates.first { isEcho($0) == false }
        return AIChatData(
            langInput: data?.langInput,
            savedSearchId: data?.savedSearchId,
            message: reply,
            extractedFilters: data?.extractedFilters,
            totalFound: data?.totalFound,
            properties: data?.properties ?? []
        )
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        langInput = try c.decodeIfPresent(String.self, forKey: .langInput)
        if let value = try? c.decodeIfPresent(String.self, forKey: .savedSearchId) {
            savedSearchId = value
        } else if let value = try? c.decodeIfPresent(Int.self, forKey: .savedSearchId) {
            savedSearchId = String(value)
        } else {
            savedSearchId = nil
        }
        message = try c.decodeIfPresent(String.self, forKey: .message)
        extractedFilters = try c.decodeIfPresent(AIExtractedFilters.self, forKey: .extractedFilters)
        if let value = try? c.decodeIfPresent(Int.self, forKey: .totalFound) {
            totalFound = value
        } else if let value = try? c.decodeIfPresent(String.self, forKey: .totalFound) {
            totalFound = Int(value)
        } else {
            totalFound = nil
        }
        properties = (try c.decodeIfPresent([APIProperty].self, forKey: .properties)) ?? []
    }

    var items: [PropertyItem] {
        properties.map { $0.asPropertyItem() }.filter { !$0.id.isEmpty }
    }
}

struct AIExtractedFilters: Decodable {
    let langInput: String?
    let listingType: String?
    let propertyType: String?
    let location: String?
    let bedrooms: Int?
    let bathrooms: Int?
    let minPrice: Int?
    let maxPrice: Int?
    let furnishedStatus: String?
    let amenities: [String]

    enum CodingKeys: String, CodingKey {
        case langInput, listingType, propertyType, location
        case bedrooms, bathrooms, minPrice, maxPrice, furnishedStatus, amenities
    }

    init(
        langInput: String? = nil,
        listingType: String? = nil,
        propertyType: String? = nil,
        location: String? = nil,
        bedrooms: Int? = nil,
        bathrooms: Int? = nil,
        minPrice: Int? = nil,
        maxPrice: Int? = nil,
        furnishedStatus: String? = nil,
        amenities: [String] = []
    ) {
        self.langInput = langInput
        self.listingType = listingType
        self.propertyType = propertyType
        self.location = location
        self.bedrooms = bedrooms
        self.bathrooms = bathrooms
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.furnishedStatus = furnishedStatus
        self.amenities = amenities
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        langInput = try c.decodeIfPresent(String.self, forKey: .langInput)
        listingType = Self.cleaned(try c.decodeIfPresent(String.self, forKey: .listingType))
        propertyType = Self.cleaned(try c.decodeIfPresent(String.self, forKey: .propertyType))
        location = Self.cleaned(try c.decodeIfPresent(String.self, forKey: .location))
        bedrooms = Self.decodeInt(c, key: .bedrooms)
        bathrooms = Self.decodeInt(c, key: .bathrooms)
        minPrice = Self.decodeInt(c, key: .minPrice)
        maxPrice = Self.decodeInt(c, key: .maxPrice)
        furnishedStatus = Self.cleaned(try c.decodeIfPresent(String.self, forKey: .furnishedStatus))
        amenities = (try c.decodeIfPresent([String].self, forKey: .amenities)) ?? []
    }

    var hasListingType: Bool { listingType != nil }
    var hasPropertyType: Bool { propertyType != nil }
    var hasLocation: Bool { location != nil }
    var hasPrice: Bool { minPrice != nil || maxPrice != nil }
    var hasBedrooms: Bool { Self.validRoomCount(bedrooms) != nil }
    var hasBathrooms: Bool { Self.validRoomCount(bathrooms) != nil }
    var hasFurnished: Bool { furnishedStatus != nil }
    var hasAmenities: Bool { !amenities.isEmpty }

    var isComplete: Bool {
        hasListingType && hasPropertyType && hasLocation && hasBedrooms
            && hasBathrooms && hasPrice && hasFurnished && hasAmenities
    }

    func mergingMissing(from other: AIExtractedFilters) -> AIExtractedFilters {
        AIExtractedFilters(
            langInput: langInput ?? other.langInput,
            listingType: listingType ?? other.listingType,
            propertyType: propertyType ?? other.propertyType,
            location: location ?? other.location,
            bedrooms: Self.validRoomCount(bedrooms) ?? Self.validRoomCount(other.bedrooms),
            bathrooms: Self.validRoomCount(bathrooms) ?? Self.validRoomCount(other.bathrooms),
            minPrice: minPrice ?? other.minPrice,
            maxPrice: maxPrice ?? other.maxPrice,
            furnishedStatus: furnishedStatus ?? other.furnishedStatus,
            amenities: amenities.isEmpty ? other.amenities : amenities
        )
    }

    func chatSummary(amenityTitle: ((String) -> String)? = nil) -> String {
        let needed = "Needed".localized
        let amenityNames = amenities.compactMap { raw -> String? in
            let title = amenityTitle?(raw) ?? raw
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.isMongoObjectId { return nil }
            return trimmed
        }
        let amenityText = amenityNames.isEmpty ? needed : amenityNames.joined(separator: ", ")
        let rows: [(String, String)] = [
            ("Buy / Rent".localized, listingType ?? needed),
            ("Property type".localized, propertyType ?? needed),
            ("Location".localized, location ?? needed),
            ("Bedrooms".localized, Self.validRoomCount(bedrooms).map { "\($0)" } ?? needed),
            ("Bathrooms".localized, Self.validRoomCount(bathrooms).map { "\($0)" } ?? needed),
            ("Min Price".localized, minPrice.map { "\($0)" } ?? needed),
            ("Max Price".localized, maxPrice.map { "\($0)" } ?? needed),
            ("Furnished".localized, furnishedStatus ?? needed),
            ("Amenities".localized, amenityText)
        ]
        let body = rows.map { "• \($0.0): \($0.1)" }.joined(separator: "\n")
        return "Search Parameters".localized + "\n" + body
    }

    func asRequestBody() -> [String: Any] {
        var body: [String: Any] = [:]
        if let listingType { body["listingType"] = listingType }
        if let propertyType { body["propertyType"] = propertyType }
        if let location { body["location"] = location }
        if let bedrooms = Self.validRoomCount(bedrooms) { body["bedrooms"] = bedrooms }
        if let bathrooms = Self.validRoomCount(bathrooms) { body["bathrooms"] = bathrooms }
        if let minPrice { body["minPrice"] = minPrice }
        if let maxPrice { body["maxPrice"] = maxPrice }
        if let furnishedStatus { body["furnishedStatus"] = furnishedStatus }
        if amenities.isEmpty == false { body["amenities"] = amenities }
        return body
    }

    func sanitized() -> AIExtractedFilters {
        AIExtractedFilters(
            langInput: langInput,
            listingType: listingType,
            propertyType: propertyType,
            location: location,
            bedrooms: Self.validRoomCount(bedrooms),
            bathrooms: Self.validRoomCount(bathrooms),
            minPrice: minPrice,
            maxPrice: maxPrice,
            furnishedStatus: furnishedStatus,
            amenities: amenities
        )
    }

    static func validRoomCount(_ value: Int?) -> Int? {
        guard let value, (1...15).contains(value) else { return nil }
        return value
    }

    private static func cleaned(_ value: String?) -> String? {
        let text = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty || text.lowercased() == "null" { return nil }
        return text
    }

    private static func decodeInt(_ c: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Int? {
        if let value = try? c.decodeIfPresent(Int.self, forKey: key) { return value }
        if let value = try? c.decodeIfPresent(Double.self, forKey: key) { return Int(value) }
        if let value = try? c.decodeIfPresent(String.self, forKey: key) {
            let digits = value.replacingOccurrences(of: ",", with: "")
            if let intValue = Int(digits) { return intValue }
            if let doubleValue = Double(digits) { return Int(doubleValue) }
        }
        return nil
    }
}

extension String {
   
    var apiListingType: String {
        let value = uppercased()
        if value == "SALE" || value == "BUY" { return "BUY" }
        if value == "RENT" { return "RENT" }
        return value
    }

    var apiPropertyType: String { uppercased().replacingOccurrences(of: " ", with: "_") }

    /// `listingType` → `Listing Type`, `min_price` → `Min Price`
    var spacedAPIKey: String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        let normalized = trimmed
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
        let spaced = normalized.unicodeScalars.reduce(into: "") { result, scalar in
            if CharacterSet.uppercaseLetters.contains(scalar), let last = result.last, last != " ", last != "\n" {
                result.append(" ")
            }
            result.append(Character(scalar))
        }
        return spaced
            .split(whereSeparator: { $0.isWhitespace })
            .map { $0.lowercased().capitalized }
            .joined(separator: " ")
    }

    var localizedAPIKey: String { spacedAPIKey.localized }

    var apiFurnishedStatus: String {
        let value = lowercased().replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "-", with: "_")
        if ["furnished", "yes", "true", "1"].contains(value) { return "FURNISHED" }
        if ["unfurnished", "no", "false", "0"].contains(value) { return "UNFURNISHED" }
        if value.contains("semi") { return "SEMI_FURNISHED" }
        return uppercased()
    }

    var displayListingType: String {
        apiListingType == "RENT" ? "Rent" : "Buy"
    }

    var displayPropertyType: String {
        lowercased().replacingOccurrences(of: "_", with: " ").capitalized
    }

    var isMongoObjectId: Bool {
        count == 24 && allSatisfy { $0.isHexDigit }
    }
    
}
