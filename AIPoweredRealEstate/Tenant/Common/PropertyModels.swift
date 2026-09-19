//
//  PropertyModels.swift
//  AIPoweredRealEstate
//

import UIKit

enum PropertySort: String, CaseIterable {
    case recommended = "Recommended"
    case priceLowToHigh = "Price Low → High"
    case priceHighToLow = "Price High → Low"
    case newest = "Newest"
}

struct PropertySearchCriteria {
    var keyword: String = ""
    var listingType: String?
    var location: String?
    var propertyType: String?
    var minPrice: Int?
    var maxPrice: Int?
    var minBedrooms: Int?
    var minBathrooms: Int?
    var minArea: Int?
    var maxArea: Int?
    var furnished: Bool?
    var amenities: Set<String> = []
    var source: String?
    var sort: PropertySort = .recommended

    var activeFilterCount: Int {
        var count = 0
        if location != nil { count += 1 }
        if propertyType != nil { count += 1 }
        if source != nil { count += 1 }
        if minPrice != nil || maxPrice != nil { count += 1 }
        if minBedrooms != nil { count += 1 }
        if minBathrooms != nil { count += 1 }
        if minArea != nil || maxArea != nil { count += 1 }
        if furnished != nil { count += 1 }
        if !amenities.isEmpty { count += 1 }
        return count
    }

    mutating func resetFilters() {
        location = nil
        propertyType = nil
        minPrice = nil
        maxPrice = nil
        minBedrooms = nil
        minBathrooms = nil
        minArea = nil
        maxArea = nil
        furnished = nil
        amenities = []
        source = nil
    }
}

final class TenantAccount {
    static let shared = TenantAccount()

    private let defaults = UserDefaults.standard

    var name = ""
    var email = ""
    var phone = ""
    var address = ""
    var language: String { didSet { defaults.set(language, forKey: "tenantLanguage") } }
    var currency: String { didSet { defaults.set(currency, forKey: "tenantCurrency") } }
    var imageName: String { "tenantProfile" }

    var profileImage: UIImage {
        UIImage(named: imageName) ?? UIImage(named: "profile") ?? UIImage()
    }

    func apply(user: User) {
        name = user.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        email = user.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        phone = user.phone?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func clear() {
        name = ""
        email = ""
        phone = ""
        address = ""
        ["tenantName", "tenantEmail", "tenantPhone", "tenantAddress"].forEach {
            defaults.removeObject(forKey: $0)
        }
        try? FileManager.default.removeItem(at: Self.profileImageURL)
    }

    private static var profileImageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("tenantProfile.jpg")
    }

    var notifyMatching: Bool { didSet { defaults.set(notifyMatching, forKey: "notifyMatching") } }
    var notifySavedUpdates: Bool { didSet { defaults.set(notifySavedUpdates, forKey: "notifySavedUpdates") } }
    var notifySearchAlerts: Bool { didSet { defaults.set(notifySearchAlerts, forKey: "notifySearchAlerts") } }
    var notifyEnquiries: Bool { didSet { defaults.set(notifyEnquiries, forKey: "notifyEnquiries") } }

    var preferredTypes: Set<String> {
        didSet { defaults.set(Array(preferredTypes), forKey: "prefTypes") }
    }
    var preferredLocations: Set<String> {
        didSet { defaults.set(Array(preferredLocations), forKey: "prefLocations") }
    }
    var budgetMax: Int? {
        didSet { defaults.set(budgetMax, forKey: "prefBudget") }
    }
    var minBedrooms: Int? {
        didSet { defaults.set(minBedrooms, forKey: "prefBeds") }
    }
    var preferredAmenities: Set<String> {
        didSet { defaults.set(Array(preferredAmenities), forKey: "prefAmenities") }
    }

    static let languages = ["English", "Español"]
    static let currencies = ["USD", "DOP", "EUR"]

    private init() {
        language = defaults.string(forKey: "tenantLanguage") ?? "English"
        currency = defaults.string(forKey: "tenantCurrency") ?? "USD"
        notifyMatching = defaults.object(forKey: "notifyMatching") as? Bool ?? true
        notifySavedUpdates = defaults.object(forKey: "notifySavedUpdates") as? Bool ?? true
        notifySearchAlerts = defaults.object(forKey: "notifySearchAlerts") as? Bool ?? true
        notifyEnquiries = defaults.object(forKey: "notifyEnquiries") as? Bool ?? true
        preferredTypes = Set(defaults.stringArray(forKey: "prefTypes") ?? [])
        preferredLocations = Set(defaults.stringArray(forKey: "prefLocations") ?? [])
        let storedBudget = defaults.object(forKey: "prefBudget") as? Int
        budgetMax = storedBudget == 0 ? nil : storedBudget
        let storedBeds = defaults.object(forKey: "prefBeds") as? Int
        minBedrooms = storedBeds == 0 ? nil : storedBeds
        preferredAmenities = Set(defaults.stringArray(forKey: "prefAmenities") ?? [])
        ["tenantName", "tenantEmail", "tenantPhone", "tenantAddress"].forEach {
            defaults.removeObject(forKey: $0)
        }
    }
}

struct EnquiryItem {
    let id: String
    let propertyId: String
    let propertyTitle: String
    let agentName: String
    let listingAgentName: String
    let source: String
    let message: String
    let contactName: String
    let email: String
    let phone: String
    let date: Date
    let kind: AgentLeadKind
    let requestId: String?
}

struct PropertyItem {
    let id: String
    let title: String
    let location: String
    let priceText: String
    let priceValue: Int
    let listingType: String
    let propertyType: String
    let bedrooms: Int
    let bathrooms: Int
    let area: String
    let areaValue: Int
    let summary: String
    let amenities: [String]
    let isFurnished: Bool
    var furnishedStatus: String = ""
    let source: String
    let listedDate: Date
    let galleryIcons: [String]
    let agentName: String
    let agentAgency: String
    let iconName: String
    let imageName: String
    var remoteGallery: [String] = []
    var isFav: Bool = false
    var recentlyViewedId: String = ""

    var galleryImageNames: [String] {
        if !remoteGallery.isEmpty { return remoteGallery }
        if imageName.lowercased().hasPrefix("http") { return [imageName] }
        let pool = [
            "propertyOceanVilla",
            "propertyLuxuryVilla",
            "propertyBeachCondo",
            "propertyFamilyHouse",
            "propertyGardenTownhouse",
            "propertyCityApartment",
            "propertyGolfApartment",
            "propertyDowntownStudio"
        ]
        guard let index = pool.firstIndex(of: imageName) else {
            return [imageName]
        }
        return (0..<3).map { pool[(index + $0) % pool.count] }
    }

    var specsText: String {
        "%d bd  ·  %d ba  ·  %@".localized(bedrooms, bathrooms, area)
    }

    var detailSpecsText: String {
        "%@  ·  %d Bedrooms  ·  %d Bathrooms  ·  %@".localized(propertyType.localized, bedrooms, bathrooms, area)
    }

    var costPerSquareMeter: Int {
        areaValue > 0 ? priceValue / areaValue : 0
    }

    var costPerSquareMeterText: String {
        "$\(costPerSquareMeter)/m²"
    }

    func hasAmenity(_ name: String) -> Bool {
        let aliases: [String: [String]] = [
            "A/C": ["A/C", "AC", "Air Conditioning", "Air Conditioner", "Air-Conditioning"],
            "Power Backup": ["Power Backup", "Backup", "Generator", "Powerbackup"],
            "Pool": ["Pool", "Swimming Pool"],
            "Gym": ["Gym", "Fitness Center", "Fitness Centre"],
            "Security": ["Security", "Gated Security", "24x7 Security"]
        ]
        let targets = aliases[name] ?? [name]
        return amenities.contains { amenity in
            targets.contains { target in amenity.caseInsensitiveCompare(target) == .orderedSame }
        }
    }

    func matches(filter: String) -> Bool {
        matches(chip: DashboardFilterChip(kind: .listingType, value: filter, label: filter))
            || matches(chip: DashboardFilterChip(kind: .propertyType, value: filter, label: filter))
            || matches(chip: DashboardFilterChip(kind: .furnished, value: filter, label: filter))
            || matches(chip: DashboardFilterChip(kind: .amenity, value: filter, label: filter))
    }

    func matches(chip: DashboardFilterChip) -> Bool {
        switch chip.kind {
        case .listingType:
            return listingType.apiListingType == chip.value.apiListingType
        case .propertyType:
            return propertyType.apiPropertyType == chip.value.apiPropertyType
        case .furnished:
            let status = chip.value.apiFurnishedStatus
            if status == "UNFURNISHED" { return !isFurnished }
            return isFurnished
        case .amenity:
            return hasAmenity(chip.value) || hasAmenity(chip.label)
        }
    }

    func matches(_ criteria: PropertySearchCriteria) -> Bool {
        if let listingType = criteria.listingType, listingType.lowercased() != self.listingType.lowercased() {
            return false
        }
        if let location = criteria.location, location.lowercased() != self.location.lowercased() {
            return false
        }
        if let propertyType = criteria.propertyType, propertyType.lowercased() != self.propertyType.lowercased() {
            return false
        }
        if let source = criteria.source, source.lowercased() != self.source.lowercased() {
            return false
        }
        if let minPrice = criteria.minPrice, priceValue < minPrice {
            return false
        }
        if let maxPrice = criteria.maxPrice, priceValue > maxPrice {
            return false
        }
        if let minBedrooms = criteria.minBedrooms, bedrooms < minBedrooms {
            return false
        }
        if let minBathrooms = criteria.minBathrooms, bathrooms < minBathrooms {
            return false
        }
        if let minArea = criteria.minArea, areaValue < minArea {
            return false
        }
        if let maxArea = criteria.maxArea, areaValue > maxArea {
            return false
        }
        if let furnished = criteria.furnished, isFurnished != furnished {
            return false
        }
        if !criteria.amenities.isEmpty {
            let available = Set(amenities.map { $0.lowercased() })
            for amenity in criteria.amenities where !available.contains(amenity.lowercased()) {
                return false
            }
        }

        return matchesKeyword(criteria.keyword)
    }

    func matchesKeyword(_ raw: String) -> Bool {
        let query = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        let haystack = keywordHaystack
        let tokens = query.lowercased().split {
            $0.isWhitespace || $0 == "," || $0 == "·" || $0 == "/"
        }.map(String.init).filter { !$0.isEmpty }
        return tokens.allSatisfy { token in
            haystack.contains(token) || matchesKeywordDigits(token, in: haystack)
        }
    }

    private var keywordHaystack: String {
        let texts = [
            title,
            location,
            source,
            listingType,
            listingType.localized,
            propertyType,
            propertyType.localized,
            "\(listingType) · \(propertyType)",
            priceText,
            "\(priceValue)",
            specsText,
            area,
            "\(areaValue)",
            "\(bedrooms) bd",
            "\(bedrooms) bed",
            "\(bedrooms) beds",
            "\(bedrooms) bhk",
            "\(bathrooms) ba",
            "\(bathrooms) bath",
            "\(bathrooms) baths",
            summary,
            amenities.joined(separator: " "),
            agentName,
            agentAgency,
            isFurnished ? "furnished" : "unfurnished"
        ]
        return texts
            .joined(separator: " ")
            .lowercased()
            .replacingOccurrences(of: ",", with: "")
    }

    private func matchesKeywordDigits(_ token: String, in haystack: String) -> Bool {
        let digits = token.filter(\.isNumber)
        guard digits.count >= 2 else { return false }
        let haystackDigits = haystack.filter { $0.isNumber || $0.isWhitespace }
        return haystack.contains(digits) || haystackDigits.contains(digits)
    }

    static let samples: [PropertyItem] = [
        PropertyItem(
            id: "p1",
            title: "Oceanview Villa",
            location: "Punta Cana",
            priceText: "$485,000",
            priceValue: 485_000,
            listingType: "Buy",
            propertyType: "Villa",
            bedrooms: 4,
            bathrooms: 3,
            area: "320 m²",
            areaValue: 320,
            summary: "A bright beachside villa with an open living area, private pool, and walking distance to the sand.",
            amenities: ["Pool", "Parking", "Furnished", "Garden", "A/C"],
            isFurnished: true,
            source: "Encuentra24",
            listedDate: Date().addingTimeInterval(-3 * 86_400),
            galleryIcons: ["house.lodge.fill", "water.waves", "sun.max.fill"],
            agentName: "Maria Santos",
            agentAgency: "Caribbean Homes",
            iconName: "house.lodge.fill",
            imageName: "propertyOceanVilla"
        ),
        PropertyItem(
            id: "p2",
            title: "Modern City Apartment",
            location: "Santo Domingo",
            priceText: "$1,200/mo",
            priceValue: 1_200,
            listingType: "Rent",
            propertyType: "Apartment",
            bedrooms: 2,
            bathrooms: 2,
            area: "95 m²",
            areaValue: 95,
            summary: "A contemporary apartment in the city center, close to cafes, coworking, and public transport.",
            amenities: ["Elevator", "Security", "Furnished", "A/C"],
            isFurnished: true,
            source: "SuperCasas",
            listedDate: Date().addingTimeInterval(-8 * 86_400),
            galleryIcons: ["building.2.fill", "sofa.fill", "building.columns.fill"],
            agentName: "Luis Perez",
            agentAgency: "Capital Realty",
            iconName: "building.2.fill",
            imageName: "propertyCityApartment"
        ),
        PropertyItem(
            id: "p3",
            title: "Family House with Garden",
            location: "Santiago",
            priceText: "$265,000",
            priceValue: 265_000,
            listingType: "Buy",
            propertyType: "House",
            bedrooms: 3,
            bathrooms: 2,
            area: "180 m²",
            areaValue: 180,
            summary: "A quiet family home with a backyard, covered parking, and easy access to schools and shops.",
            amenities: ["Garden", "Parking", "Power Backup"],
            isFurnished: false,
            source: "SuperCasas",
            listedDate: Date().addingTimeInterval(-18 * 86_400),
            galleryIcons: ["house.fill", "leaf.fill", "car.fill"],
            agentName: "Ana Rodriguez",
            agentAgency: "Northern Estates",
            iconName: "house.fill",
            imageName: "propertyFamilyHouse"
        ),
        PropertyItem(
            id: "p4",
            title: "Beachfront Condo",
            location: "Puerto Plata",
            priceText: "$2,100/mo",
            priceValue: 2_100,
            listingType: "Rent",
            propertyType: "Apartment",
            bedrooms: 3,
            bathrooms: 2,
            area: "140 m²",
            areaValue: 140,
            summary: "Wake up to ocean views in this furnished condo with balcony, gym access, and 24/7 security.",
            amenities: ["Ocean View", "Gym", "Security", "Furnished"],
            isFurnished: true,
            source: "Encuentra24",
            listedDate: Date().addingTimeInterval(-1 * 86_400),
            galleryIcons: ["water.waves", "building.2.fill", "figure.run"],
            agentName: "Diego Alvarez",
            agentAgency: "Coastline Living",
            iconName: "water.waves",
            imageName: "propertyBeachCondo"
        ),
        PropertyItem(
            id: "p5",
            title: "Luxury Cap Cana Villa",
            location: "Cap Cana",
            priceText: "$890,000",
            priceValue: 890_000,
            listingType: "Buy",
            propertyType: "Villa",
            bedrooms: 5,
            bathrooms: 4,
            area: "410 m²",
            areaValue: 410,
            summary: "A premium villa with resort access, smart home features, and a resort-style outdoor living space.",
            amenities: ["Pool", "Smart Home", "Golf Access", "Maid Room"],
            isFurnished: false,
            source: "Cap Cana Listings",
            listedDate: Date().addingTimeInterval(-12 * 86_400),
            galleryIcons: ["sparkles", "flag.fill", "drop.fill"],
            agentName: "Camila Reyes",
            agentAgency: "Cap Cana Residences",
            iconName: "sparkles",
            imageName: "propertyLuxuryVilla"
        ),
        PropertyItem(
            id: "p6",
            title: "Downtown Studio",
            location: "Santo Domingo",
            priceText: "$750/mo",
            priceValue: 750,
            listingType: "Rent",
            propertyType: "Apartment",
            bedrooms: 1,
            bathrooms: 1,
            area: "42 m²",
            areaValue: 42,
            summary: "A compact unfurnished studio near Parque Independencia, ideal for a first apartment in the city.",
            amenities: ["Elevator", "Security", "A/C"],
            isFurnished: false,
            source: "Corotos",
            listedDate: Date().addingTimeInterval(-5 * 86_400),
            galleryIcons: ["building.fill", "lamp.desk.fill", "window.casement"],
            agentName: "Luis Perez",
            agentAgency: "Capital Realty",
            iconName: "building.fill",
            imageName: "propertyDowntownStudio"
        ),
        PropertyItem(
            id: "p7",
            title: "Garden Townhouse",
            location: "Punta Cana",
            priceText: "$1,800/mo",
            priceValue: 1_800,
            listingType: "Rent",
            propertyType: "House",
            bedrooms: 3,
            bathrooms: 2,
            area: "160 m²",
            areaValue: 160,
            summary: "A furnished townhouse with a private garden, two parking spaces, and a short drive to the beach.",
            amenities: ["Garden", "Parking", "Furnished", "A/C", "Pool"],
            isFurnished: true,
            source: "Encuentra24",
            listedDate: Date().addingTimeInterval(-6 * 86_400),
            galleryIcons: ["house.fill", "tree.fill", "car.fill"],
            agentName: "Maria Santos",
            agentAgency: "Caribbean Homes",
            iconName: "house.fill",
            imageName: "propertyGardenTownhouse"
        ),
        PropertyItem(
            id: "p8",
            title: "Golf View Apartment",
            location: "Cap Cana",
            priceText: "$310,000",
            priceValue: 310_000,
            listingType: "Buy",
            propertyType: "Apartment",
            bedrooms: 2,
            bathrooms: 2,
            area: "118 m²",
            areaValue: 118,
            summary: "A bright apartment overlooking the golf course with resort amenities and a furnished living area.",
            amenities: ["Golf Access", "Pool", "Furnished", "Gym", "Security"],
            isFurnished: true,
            source: "Realtor DR",
            listedDate: Date().addingTimeInterval(-2 * 86_400),
            galleryIcons: ["building.2.fill", "flag.fill", "sportscourt.fill"],
            agentName: "Camila Reyes",
            agentAgency: "Cap Cana Residences",
            iconName: "building.2.fill",
            imageName: "propertyGolfApartment"
        ),
        PropertyItem(
            id: "p9",
            title: "Colonial Courtyard Apartment",
            location: "Santo Domingo",
            priceText: "$980/mo",
            priceValue: 980,
            listingType: "Rent",
            propertyType: "Apartment",
            bedrooms: 2,
            bathrooms: 1,
            area: "78 m²",
            areaValue: 78,
            summary: "A renovated apartment in the colonial zone with a shared courtyard, high ceilings, and walkable cafes.",
            amenities: ["A/C", "Security", "Furnished"],
            isFurnished: true,
            source: "Corotos",
            listedDate: Date().addingTimeInterval(-4 * 86_400),
            galleryIcons: ["building.fill", "leaf.fill", "lamp.desk.fill"],
            agentName: "Luis Perez",
            agentAgency: "Capital Realty",
            iconName: "building.fill",
            imageName: "propertyDowntownStudio"
        ),
        PropertyItem(
            id: "p10",
            title: "Palm Grove Villa",
            location: "Punta Cana",
            priceText: "$560,000",
            priceValue: 560_000,
            listingType: "Buy",
            propertyType: "Villa",
            bedrooms: 4,
            bathrooms: 4,
            area: "350 m²",
            areaValue: 350,
            summary: "A gated villa with a private pool, guest suite, and short drive to Bavaro beach.",
            amenities: ["Pool", "Parking", "Garden", "A/C", "Security"],
            isFurnished: false,
            source: "SuperCasas",
            listedDate: Date().addingTimeInterval(-9 * 86_400),
            galleryIcons: ["house.lodge.fill", "drop.fill", "sun.max.fill"],
            agentName: "Maria Santos",
            agentAgency: "Caribbean Homes",
            iconName: "house.lodge.fill",
            imageName: "propertyOceanVilla"
        ),
        PropertyItem(
            id: "p11",
            title: "Harbor View House",
            location: "Puerto Plata",
            priceText: "$198,000",
            priceValue: 198_000,
            listingType: "Buy",
            propertyType: "House",
            bedrooms: 3,
            bathrooms: 2,
            area: "155 m²",
            areaValue: 155,
            summary: "A hillside family house with harbor views, covered parking, and a small garden terrace.",
            amenities: ["Garden", "Parking", "Ocean View"],
            isFurnished: false,
            source: "Realtor DR",
            listedDate: Date().addingTimeInterval(-11 * 86_400),
            galleryIcons: ["house.fill", "water.waves", "car.fill"],
            agentName: "Diego Alvarez",
            agentAgency: "Coastline Living",
            iconName: "house.fill",
            imageName: "propertyFamilyHouse"
        ),
        PropertyItem(
            id: "p12",
            title: "Marina Residences Condo",
            location: "Cap Cana",
            priceText: "$3,200/mo",
            priceValue: 3_200,
            listingType: "Rent",
            propertyType: "Apartment",
            bedrooms: 3,
            bathrooms: 3,
            area: "165 m²",
            areaValue: 165,
            summary: "A furnished marina condo with resort access, two parking spaces, and a private balcony.",
            amenities: ["Pool", "Gym", "Security", "Furnished", "Golf Access"],
            isFurnished: true,
            source: "Encuentra24",
            listedDate: Date().addingTimeInterval(-7 * 86_400),
            galleryIcons: ["building.2.fill", "water.waves", "figure.run"],
            agentName: "Camila Reyes",
            agentAgency: "Cap Cana Residences",
            iconName: "building.2.fill",
            imageName: "propertyBeachCondo"
        ),
        PropertyItem(
            id: "p13",
            title: "Fairway Club Suite",
            location: "Cap Cana",
            priceText: "$245,000",
            priceValue: 245_000,
            listingType: "Buy",
            propertyType: "Apartment",
            bedrooms: 1,
            bathrooms: 1,
            area: "68 m²",
            areaValue: 68,
            summary: "A lock-and-leave suite overlooking the fairway, ideal as a second home or rental investment.",
            amenities: ["Golf Access", "Pool", "Security", "Gym"],
            isFurnished: false,
            source: "Cap Cana Listings",
            listedDate: Date().addingTimeInterval(-15 * 86_400),
            galleryIcons: ["flag.fill", "building.2.fill", "sparkles"],
            agentName: "Camila Reyes",
            agentAgency: "Cap Cana Residences",
            iconName: "sparkles",
            imageName: "propertyLuxuryVilla"
        ),
        PropertyItem(
            id: "p14",
            title: "Garden Family House",
            location: "Santiago",
            priceText: "$1,450/mo",
            priceValue: 1_450,
            listingType: "Rent",
            propertyType: "House",
            bedrooms: 3,
            bathrooms: 2,
            area: "170 m²",
            areaValue: 170,
            summary: "A quiet rental house with a backyard, two parking spaces, and easy access to schools.",
            amenities: ["Garden", "Parking", "Power Backup", "A/C"],
            isFurnished: false,
            source: "Corotos",
            listedDate: Date().addingTimeInterval(-10 * 86_400),
            galleryIcons: ["house.fill", "tree.fill", "car.fill"],
            agentName: "Ana Rodriguez",
            agentAgency: "Northern Estates",
            iconName: "house.fill",
            imageName: "propertyGardenTownhouse"
        )
    ]
}

struct SavedSearch {
    var id: String
    var location: String?
    var listingType: String?
    var minPrice: Int?
    var maxPrice: Int?
    var minBedrooms: Int?
    var amenities: Set<String>
    var alertOn: Bool

    var title: String {
        var parts: [String] = []
        if let listingType { parts.append(listingType.localized) }
        if let location { parts.append(location) }
        return parts.isEmpty ? "Saved Search".localized : parts.joined(separator: " · ")
    }

    var subtitle: String {
        var parts: [String] = []
        if let maxPrice {
            parts.append(maxPrice >= 1_000 ? "Up to $\(maxPrice / 1_000)k" : "Up to $\(maxPrice)")
        } else if let minPrice {
            parts.append("$\(minPrice / 1_000)k+")
        }
        if let minBedrooms { parts.append("%@+ beds".localized("\(minBedrooms)")) }
        if !amenities.isEmpty { parts.append(amenities.sorted().map { $0.localized }.joined(separator: ", ")) }
        return parts.isEmpty ? "Any price · Any bedrooms".localized : parts.joined(separator: "  ·  ")
    }

    func asCriteria() -> PropertySearchCriteria {
        var criteria = PropertySearchCriteria()
        criteria.location = location
        criteria.listingType = listingType
        criteria.minPrice = minPrice
        criteria.maxPrice = maxPrice
        criteria.minBedrooms = minBedrooms
        criteria.amenities = amenities
        return criteria
    }

    static func from(_ criteria: PropertySearchCriteria, alertOn: Bool = true) -> SavedSearch {
        SavedSearch(
            id: UUID().uuidString,
            location: criteria.location,
            listingType: criteria.listingType,
            minPrice: criteria.minPrice,
            maxPrice: criteria.maxPrice,
            minBedrooms: criteria.minBedrooms,
            amenities: criteria.amenities,
            alertOn: alertOn
        )
    }
}

final class PropertyStore {
    static let shared = PropertyStore()

    private(set) var all: [PropertyItem] = []
    private(set) var favoriteIDs: Set<String> = []
    private(set) var favoriteItems: [PropertyItem] = []
    private(set) var compareIDs: [String] = []
    private(set) var recentlyViewed: [PropertyItem] = []
    private(set) var savedSearches: [SavedSearch] = []
    private(set) var pendingCriteria: PropertySearchCriteria?
    private(set) var enquiries: [EnquiryItem] = []

    static let locations = ["Punta Cana", "Santo Domingo", "Santiago", "Puerto Plata", "Cap Cana"]
    static let propertyTypes = ["Apartment", "House", "Villa"]
    static var sources: [String] { shared.portalSources }
    var portalSources: [String] {
        Array(Set(all.map(\.source))).sorted()
    }
    static let amenityOptions = ["Pool", "Parking", "Furnished", "Garden", "A/C", "Elevator", "Security", "Ocean View", "Gym", "Smart Home", "Golf Access", "Power Backup"]

    func listings(inSource source: String?) -> [PropertyItem] {
        guard let source, !source.isEmpty else { return all }
        return all.filter { $0.source.caseInsensitiveCompare(source) == .orderedSame }
    }

    func sourceCount(_ source: String?) -> Int {
        listings(inSource: source).count
    }

    private init() {}

    func isFavorite(_ id: String) -> Bool {
        favoriteIDs.contains(id)
    }

    func setFavorite(_ id: String, isOn: Bool) {
        if isOn {
            favoriteIDs.insert(id)
            if !favoriteItems.contains(where: { $0.id == id }),
               let item = all.first(where: { $0.id == id }) ?? recentlyViewed.first(where: { $0.id == id }) {
                var fav = item
                fav.isFav = true
                favoriteItems.insert(fav, at: 0)
            }
        } else {
            favoriteIDs.remove(id)
            favoriteItems.removeAll { $0.id == id }
            compareIDs.removeAll { $0 == id }
        }
        if let index = all.firstIndex(where: { $0.id == id }) {
            all[index].isFav = isOn
        }
        if let index = recentlyViewed.firstIndex(where: { $0.id == id }) {
            recentlyViewed[index].isFav = isOn
        }
        if let index = favoriteItems.firstIndex(where: { $0.id == id }) {
            favoriteItems[index].isFav = isOn
        }
    }

    func setFavorites(_ items: [PropertyItem]) {
        var seen = Set<String>()
        favoriteItems = items.compactMap { item in
            let key = item.id.trimmingCharacters(in: .whitespacesAndNewlines)
            guard key.isEmpty == false, seen.insert(key).inserted else { return nil }
            var copy = item
            copy.isFav = true
            return copy
        }
        favoriteIDs = Set(favoriteItems.map(\.id))
        compareIDs = compareIDs.filter { favoriteIDs.contains($0) }
        for item in favoriteItems {
            if let index = all.firstIndex(where: { $0.id == item.id }) {
                all[index].isFav = true
            }
        }
    }

    func toggleFavorite(_ id: String) {
        setFavorite(id, isOn: !isFavorite(id))
    }

    func favoriteProperties() -> [PropertyItem] {
        favoriteItems.map { cached in
            var item = all.first { $0.id == cached.id } ?? cached
            item.isFav = true
            return item
        }
    }

    @discardableResult
    func addToCompare(_ id: String) -> String {
        if compareIDs.contains(id) {
            return "Already added to compare.".localized
        }
        guard compareIDs.count < 3 else {
            return "You can compare up to 3 properties.".localized
        }
        compareIDs.append(id)
        return "Added to compare (%d/3).".localized(compareIDs.count)
    }

    func isCompared(_ id: String) -> Bool {
        compareIDs.contains(id)
    }

    @discardableResult
    func toggleCompare(_ id: String) -> String {
        if let index = compareIDs.firstIndex(of: id) {
            compareIDs.remove(at: index)
            return "Removed from compare.".localized
        }
        guard compareIDs.count < 3 else {
            return "You can compare up to 3 properties.".localized
        }
        compareIDs.append(id)
        return "Added to compare (%d/3).".localized(compareIDs.count)
    }

    func comparedProperties() -> [PropertyItem] {
        compareIDs.compactMap { id in
            all.first { $0.id == id } ?? favoriteItems.first { $0.id == id }
        }
    }

    func compareCandidates() -> [PropertyItem] {
        favoriteProperties()
    }

    func saveSearch(from criteria: PropertySearchCriteria, alertOn: Bool = true) {
        savedSearches.insert(SavedSearch.from(criteria, alertOn: alertOn), at: 0)
    }

    func upsertSearch(_ search: SavedSearch) {
        if let index = savedSearches.firstIndex(where: { $0.id == search.id }) {
            savedSearches[index] = search
        } else {
            savedSearches.insert(search, at: 0)
        }
    }

    func deleteSearch(id: String) {
        savedSearches.removeAll { $0.id == id }
    }

    func setAlert(id: String, isOn: Bool) {
        guard let index = savedSearches.firstIndex(where: { $0.id == id }) else { return }
        savedSearches[index].alertOn = isOn
    }

    func applySavedSearch(_ search: SavedSearch) {
        pendingCriteria = search.asCriteria()
    }

    func consumePendingCriteria() -> PropertySearchCriteria? {
        let value = pendingCriteria
        pendingCriteria = nil
        return value
    }

    func addEnquiry(
        property: PropertyItem,
        name: String,
        email: String,
        phone: String,
        message: String,
        kind: AgentLeadKind = .propertyEnquiry,
        requestId: String? = nil
    ) {
        let platform = RealtorDesk.shared.buyerAssignedRealtor()
        let item = EnquiryItem(
            id: UUID().uuidString,
            propertyId: property.id,
            propertyTitle: property.title,
            agentName: platform?.name ?? "SpeddyProp",
            listingAgentName: property.agentName,
            source: property.source,
            message: message,
            contactName: name,
            email: email,
            phone: phone,
            date: Date(),
            kind: kind,
            requestId: requestId ?? RealtorDesk.shared.buyerActiveRequest?.id
        )
        enquiries.insert(item, at: 0)
        AgentStore.shared.recordLead(from: item)
    }

    func comparisonSummary(for properties: [PropertyItem]) -> String {
        guard !properties.isEmpty else {
            return "Select properties to see an AI summary.".localized
        }
        let overall = properties.max(by: { comparisonScore($0) < comparisonScore($1) })
        let cheapest = properties.min(by: { $0.priceValue < $1.priceValue })
        let largest = properties.max(by: { $0.areaValue < $1.areaValue })
        return properties.map { property in
            var tags: [String] = []
            if property.id == overall?.id { tags.append("Best overall match".localized) }
            if property.id == cheapest?.id { tags.append("Best price".localized) }
            if property.id == largest?.id { tags.append("Largest area".localized) }
            if tags.isEmpty { tags.append(property.summary) }
            return "\(property.title):\n\(tags.joined(separator: " · "))"
        }.joined(separator: "\n\n")
    }

    private func comparisonScore(_ property: PropertyItem) -> Int {
        let cost = property.costPerSquareMeter
        return property.amenities.count * 8
            + property.bedrooms * 4
            + (property.isFurnished ? 6 : 0)
            - cost / 40
    }

    func markViewed(_ property: PropertyItem) {
        recentlyViewed.removeAll { $0.id == property.id }
        recentlyViewed.insert(property, at: 0)
        if recentlyViewed.count > 8 {
            recentlyViewed = Array(recentlyViewed.prefix(8))
        }
    }

    func setRecentlyViewed(_ items: [PropertyItem]) {
        recentlyViewed = items
        for item in items where item.isFav {
            favoriteIDs.insert(item.id)
        }
    }

    func recommended(filter: DashboardFilterChip?) -> [PropertyItem] {
        guard let filter else { return all }
        return all.filter { $0.matches(chip: filter) }
    }

    func mergeRemote(_ items: [PropertyItem]?) {
        all = (items ?? []).map { item in
            var copy = item
            if favoriteIDs.contains(item.id) {
                copy.isFav = true
            }
            return copy
        }
    }

    func recommended(filter: String?) -> [PropertyItem] {
        guard let filter, !filter.isEmpty else { return all }
        return all.filter { $0.matches(filter: filter) }
    }

    func search(_ criteria: PropertySearchCriteria) -> [PropertyItem] {
        var results = all.filter { $0.matches(criteria) }
        switch criteria.sort {
        case .recommended:
            if !criteria.keyword.isEmpty {
                results.sort { relevance($0, keyword: criteria.keyword) > relevance($1, keyword: criteria.keyword) }
            }
        case .priceLowToHigh:
            results.sort { $0.priceValue < $1.priceValue }
        case .priceHighToLow:
            results.sort { $0.priceValue > $1.priceValue }
        case .newest:
            results.sort { $0.listedDate > $1.listedDate }
        }
        return results
    }

    func topMatches(for query: String) -> [PropertyItem] {
        let text = query.lowercased()
        var scored = all.map { property -> (PropertyItem, Int) in
            var score = 0
            if text.contains(property.listingType.lowercased()) { score += 3 }
            if text.contains(property.propertyType.lowercased()) { score += 4 }
            if text.contains(property.location.lowercased()) { score += 4 }
            if text.contains("beach") && (property.location.contains("Punta") || property.location.contains("Puerto") || property.location.contains("Cap")) {
                score += 3
            }
            if text.contains("\(property.bedrooms)") { score += 2 }
            if text.contains("furnished") && property.isFurnished { score += 2 }
            if text.contains(property.source.lowercased()) { score += 3 }
            return (property, score)
        }
        scored.sort { $0.1 > $1.1 }
        return Array(scored.prefix(3).map(\.0))
    }

    private func relevance(_ property: PropertyItem, keyword: String) -> Int {
        let text = keyword.lowercased()
        var score = 0
        if property.location.lowercased().contains(text) { score += 5 }
        if property.title.lowercased().contains(text) { score += 4 }
        if property.propertyType.lowercased().contains(text) { score += 3 }
        if property.listingType.lowercased().contains(text) { score += 2 }
        return score
    }
}

private enum PropertyDetailsRouter {
    private static var lastID: String?
    private static var lastAt: TimeInterval = 0

    static func shouldOpen(_ id: String) -> Bool {
        let now = CACurrentMediaTime()
        if lastID == id, now - lastAt < 0.5 { return false }
        lastID = id
        lastAt = now
        return true
    }
}

extension UIViewController {

    var isAgentFlow: Bool {
        var current: UIViewController? = self
        while let controller = current {
            if controller is AgentTabBarController { return true }
            current = controller.parent ?? controller.presentingViewController
        }
        return tabBarController is AgentTabBarController
    }

    func openPropertyDetails(_ property: PropertyItem) {
        guard PropertyDetailsRouter.shouldOpen(property.id) else { return }
        PropertyStore.shared.markViewed(property)
        let details: TenantPropertyDetailsVC = TenantStoryboard.load("TenantPropertyDetailsVC")
        details.property = property
        details.hidesBottomBarWhenPushed = true
        let nav = navigationController
            ?? tabBarController?.selectedViewController as? UINavigationController
        nav?.pushViewController(details, animated: true)
    }

    func toggleFavoriteRemote(
        propertyId: String,
        completion: ((Bool) -> Void)? = nil
    ) {
        Task {
            do {
                let isFav = try await TenantViewModels.toggleFavoriteAPI(propertyId: propertyId)
                await MainActor.run {
                    PropertyStore.shared.setFavorite(propertyId, isOn: isFav)
                    completion?(isFav)
                }
            } catch {
                await MainActor.run {
                    completion?(PropertyStore.shared.isFavorite(propertyId))
                }
            }
        }
    }

    func deleteRecentlyViewedRemote(_ property: PropertyItem, completion: ((Bool) -> Void)? = nil) {
        let viewedId = property.recentlyViewedId.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = viewedId.isEmpty ? property.id.trimmingCharacters(in: .whitespacesAndNewlines) : viewedId
        guard id.isEmpty == false else {
            completion?(false)
            return
        }
        Task {
            do {
                try await TenantViewModels.deleteRecentlyViewedAPI(id: id)
                await MainActor.run { completion?(true) }
            } catch {
                await MainActor.run { completion?(false) }
            }
        }
    }

    func openAISearch(prefilled query: String? = nil, chatId: String? = nil, approveLeadIfNeeded: Bool = false) {
        let aiVC: TenantAISearchVC = TenantStoryboard.load("TenantAISearchVC")
        aiVC.initialQuery = query
        let trimmedChatId = chatId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        aiVC.chatId = trimmedChatId.isEmpty ? nil : trimmedChatId
        aiVC.approveLeadIfNeeded = approveLeadIfNeeded
        aiVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(aiVC, animated: true)
    }

    func openCompare(_ properties: [PropertyItem]) {
        let compareVC: TenantCompareVC = TenantStoryboard.load("TenantCompareVC")
        compareVC.properties = properties
        compareVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(compareVC, animated: true)
    }

    func openSavedSearch(_ search: SavedSearch?) {
        let editor: TenantSavedSearchVC = TenantStoryboard.load("TenantSavedSearchVC")
        editor.search = search ?? SavedSearch(
            id: UUID().uuidString,
            location: nil,
            listingType: nil,
            minPrice: nil,
            maxPrice: nil,
            minBedrooms: nil,
            amenities: [],
            alertOn: true
        )
        editor.isNew = search == nil
        editor.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(editor, animated: true)
    }

    func openContactAgent(property: PropertyItem? = nil) {
        let listVC: TenantAgentListVC = TenantStoryboard.load("TenantAgentListVC")
        listVC.property = property
        listVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(listVC, animated: true)
    }

    func openBuyerLeads() {
        let vc: TenantLeadsVC = TenantStoryboard.load("TenantLeadsVC")
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    func openBuyerLead(id: String) {
        let vc: TenantLeadDetailVC = TenantStoryboard.load("TenantLeadDetailVC")
        vc.leadId = id
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    func openRealtorHelp(requirement: ClientRequirement? = nil, query: String? = nil) {
        let help: TenantRealtorHelpVC = TenantStoryboard.load("TenantRealtorHelpVC")
        if let requirement {
            help.requirement = requirement
        } else if let query, !query.isEmpty {
            help.requirement = .from(query: query)
        }
        help.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(help, animated: true)
    }

    func openBuyerRecommendations() {
        let vc: TenantRealtorRecommendationsVC = TenantStoryboard.load("TenantRealtorRecommendationsVC")
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}
