//
//  AgentModels.swift
//  AIPoweredRealEstate
//

import UIKit

enum AgentLeadStatus: String, CaseIterable {
    case new = "New"
    case contacted = "Contacted"
    case viewing = "Viewing"
    case closed = "Closed"
}

enum AgentMarketingChannel: String, CaseIterable {
    case listing = "Listing"
    case instagram = "Instagram"
    case whatsapp = "WhatsApp"
    case email = "Email"
}

enum AgentWorkingSetResult {
    case saved(count: Int, max: Int)
    case removed(count: Int, max: Int)
    case limitReached(max: Int)
}

struct AgentSavedListing: Codable {
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
    let source: String
    let imageName: String
    let listedDate: TimeInterval
    let listingAgentName: String
    let listingAgency: String

    init(_ property: PropertyItem) {
        id = property.id
        title = property.title
        location = property.location
        priceText = property.priceText
        priceValue = property.priceValue
        listingType = property.listingType
        propertyType = property.propertyType
        bedrooms = property.bedrooms
        bathrooms = property.bathrooms
        area = property.area
        areaValue = property.areaValue
        summary = property.summary
        source = property.source
        imageName = property.imageName
        listedDate = property.listedDate.timeIntervalSince1970
        listingAgentName = property.agentName
        listingAgency = property.agentAgency
    }

    func asPropertyItem() -> PropertyItem {
        PropertyStore.shared.all.first { $0.id == id } ?? PropertyItem(
            id: id,
            title: title,
            location: location,
            priceText: priceText,
            priceValue: priceValue,
            listingType: listingType,
            propertyType: propertyType,
            bedrooms: bedrooms,
            bathrooms: bathrooms,
            area: area,
            areaValue: areaValue,
            summary: summary,
            amenities: [],
            isFurnished: false,
            source: source,
            listedDate: Date(timeIntervalSince1970: listedDate),
            galleryIcons: ["house.fill"],
            agentName: listingAgentName,
            agentAgency: listingAgency,
            iconName: "house.fill",
            imageName: imageName
        )
    }
}

struct AgentClientSearch {
    let id: String
    var client: String
    var query: String
    let date: Date
}

struct AgentLead {
    let id: String
    let propertyId: String
    let propertyTitle: String
    let clientName: String
    let email: String
    let phone: String
    let message: String
    let date: Date
    var status: AgentLeadStatus
    var kind: AgentLeadKind = .propertyEnquiry
    var requestId: String? = nil
    var listingAgentName: String? = nil
    var apiStatus: String = ""
}

struct AgentNotificationItem {
    let id: String
    let title: String
    let body: String
    let icon: String
    let date: Date
    var isRead: Bool
    var requestId: String? = nil
}

enum AgentMarketingCopy {
    static func text(for property: PropertyItem, channel: AgentMarketingChannel) -> String {
        let amenities = property.amenities.prefix(4).joined(separator: ", ")
        let furnished = property.isFurnished ? "Furnished" : "Unfurnished"
        let cityTag = property.location.replacingOccurrences(of: " ", with: "")
        switch channel {
        case .listing:
            return """
            MARKETING DESCRIPTION
            \(property.title) | \(property.location) | \(property.source)

            Price: \(property.priceText)  ·  \(property.listingType)
            \(property.detailSpecsText)
            \(furnished)  ·  \(amenities)
            \(property.costPerSquareMeterText)

            \(property.summary)

            Ideal for clients looking for a \(property.propertyType.lowercased()) in \(property.location). Ready for portal upload (SuperCasas, Corotos, Encuentra24).

            Shared by \(AgentAccount.shared.name), \(AgentAccount.shared.agency)
            Listing source: \(property.source) · \(property.agentName)
            \(AgentAccount.shared.phone)
            """
            
        case .instagram:
            return """
            ✨ Just listed in \(property.location)

            \(property.title)
            \(property.priceText)
            \(property.bedrooms) BR · \(property.bathrooms) BA · \(property.area)
            \(furnished) · \(amenities)
            \(property.summary)

            Private tours this week — DM to book.
            —
            \(AgentAccount.shared.name) | \(AgentAccount.shared.agency)

            #\(cityTag) #DominicanRepublic #RealEstate #\(property.propertyType) #JustListed #CaribbeanHomes
            """
            
        case .whatsapp:
           
            return """
            
            Hi, I found a listing that may match what you asked for:

            *\(property.title)*
            \(property.location)
            \(property.priceText) · \(property.listingType)
            \(property.bedrooms) beds · \(property.bathrooms) baths · \(property.area)
            \(furnished)
            Source: \(property.source)
            \(property.summary)

            I can arrange a viewing this week. Shall I send a short client report as well?

            \(AgentAccount.shared.name)
            \(AgentAccount.shared.agency)
            \(AgentAccount.shared.phone)
            """
            
        case .email:
            return """
            Hello,

            Sharing a listing from our cross-inventory search that may fit your brief.

            Property: \(property.title)
            Location: \(property.location)
            Price: \(property.priceText) (\(property.listingType))
            Details: \(property.detailSpecsText)
            Condition: \(furnished)
            Amenities: \(property.amenities.joined(separator: ", "))
            Portal: \(property.source)

            \(property.summary)

            I can follow up with a client-facing comparison report or schedule a showing at your convenience.

            Kind regards,
            \(AgentAccount.shared.name)
            \(AgentAccount.shared.agency)
            \(AgentAccount.shared.email)
            \(AgentAccount.shared.phone)
            """
        }
    }

    static func clientReport(for properties: [PropertyItem], client: String) -> String {
        let agent = AgentAccount.shared
        let rows = properties.enumerated().map { index, property in
            """
            \(index + 1). \(property.title)
               \(property.location) · \(property.source)
               \(property.priceText) · \(property.costPerSquareMeterText)
               \(property.detailSpecsText)
               \(property.summary)
            """
        }.joined(separator: "\n\n")
        let summary = PropertyStore.shared.comparisonSummary(for: properties)
        return """
        Client property report
        Prepared for: \(client)
        By: \(agent.name), \(agent.agency)

        \(rows)

        Recommendation
        \(summary)

        Contact: \(agent.email) · \(agent.phone)
        """
    }

    static func comparisonReport(for properties: [PropertyItem], client: String) -> String {
        let agent = AgentAccount.shared
        let columns = properties.map(\.title).joined(separator: "  |  ")
        func line(_ title: String, _ values: [String]) -> String {
            "\(title): " + values.joined(separator: "  |  ")
        }
        let table = [
            line("Price", properties.map(\.priceText)),
            line("Location", properties.map(\.location)),
            line("Bedrooms", properties.map { "\($0.bedrooms)" }),
            line("Bathrooms", properties.map { "\($0.bathrooms)" }),
            line("Area", properties.map(\.area)),
            line("Cost / m²", properties.map(\.costPerSquareMeterText)),
            line("Furnished", properties.map { $0.isFurnished ? "Yes" : "No" }),
            line("Amenities", properties.map { $0.amenities.joined(separator: ", ") })
        ].joined(separator: "\n")
        let listings = properties.enumerated().map { index, property in
            """
            \(index + 1). \(property.title)
               \(property.priceText) · \(property.location)
               \(property.detailSpecsText)
               \(property.amenities.joined(separator: ", "))
            """
        }.joined(separator: "\n\n")
        return """
        \(client)'s Property Comparison

        \(columns)

        \(table)

        \(listings)

        AI Summary
        \(PropertyStore.shared.comparisonSummary(for: properties))

        Shared by \(agent.name), \(agent.agency)
        \(agent.phone) · \(agent.email)
        """
    }
}

final class AgentAccount {
   
    static let shared = AgentAccount()

    var name = ""
    var agency = ""
    var agencyId = ""
    var email = ""
    var phone = ""
    var licenseNumber = ""
    var profileImagePath: String? {
        didSet { UserDefaults.standard.set(profileImagePath, forKey: "agentProfileImagePath") }
    }

    var profileSubtitle: String {
        let agency = agency.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if !agency.isEmpty, !email.isEmpty { return "\(agency)  ·  \(email)" }
        if !email.isEmpty { return email }
        return agency
    }

    var profileImage: UIImage {
        if let data = try? Data(contentsOf: Self.profileImageURL), let image = UIImage(data: data) {
            return image
        }
        return UIImage(named: "profile") ?? UIImage(named: "tenantProfile") ?? UIImage()
    }

    func saveProfileImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        try? data.write(to: Self.profileImageURL, options: .atomic)
    }

    func apply(user: User) {
        name = user.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        email = user.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        phone = user.phone?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        agency = user.agencyName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        agencyId = user.agencyId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        licenseNumber = user.licenseNumber?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let img = user.profileImage?.trimmingCharacters(in: .whitespacesAndNewlines), img.isEmpty == false {
            profileImagePath = img
        } else {
            profileImagePath = nil
        }
    }

    func clear() {
        name = ""
        agency = ""
        agencyId = ""
        email = ""
        phone = ""
        licenseNumber = ""
        profileImagePath = nil
        UserDefaults.standard.removeObject(forKey: "agentProfileImagePath")
        ["agentName", "agentAgency", "agentEmail", "agentPhone"].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
        try? FileManager.default.removeItem(at: Self.profileImageURL)
    }

    private static var profileImageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("agentProfile.jpg")
    }

    private init() {
        profileImagePath = UserDefaults.standard.string(forKey: "agentProfileImagePath")
    }
}

final class AgentStore {
    
    static let shared = AgentStore()
    static let maxWorkingSet = 12
    static var pendingSavedSection: Int?

    private let defaults = UserDefaults.standard

    private(set) var favoriteIDs: Set<String>
    private(set) var workingSet: [AgentSavedListing]
    private var favoriteItems: [PropertyItem]
    private(set) var compareIDs: [String]
    private(set) var recentSearches: [String]
    private(set) var clientSearches: [AgentClientSearch]
    private(set) var leads: [AgentLead]
    private(set) var notifications: [AgentNotificationItem]

    var unreadCount: Int { notifications.filter { !$0.isRead }.count }
    var openLeadCount: Int { leads.filter { $0.status != .closed }.count }
    var savedCount: Int { workingSet.count }
    var remainingSlots: Int { max(0, Self.maxWorkingSet - workingSet.count) }

    private init() {
        favoriteIDs = []
        workingSet = []
        favoriteItems = []
        compareIDs = []
        recentSearches = []
        clientSearches = []
        leads = []
        notifications = []
        ["agentWorkingSetSnapshots", "agentFavoriteIDs", "agentCompareIDs", "agentRecentSearches"].forEach {
            defaults.removeObject(forKey: $0)
        }
    }

    func isFavorite(_ id: String) -> Bool { favoriteIDs.contains(id) }

    @discardableResult
   
    func toggleFavorite(_ id: String) -> AgentWorkingSetResult {
        if let live = PropertyStore.shared.all.first(where: { $0.id == id }) {
            return toggleWorkingSet(live)
        }
        if let snapshot = workingSet.first(where: { $0.id == id }) {
            return toggleWorkingSet(snapshot.asPropertyItem())
        }
        return .removed(count: savedCount, max: Self.maxWorkingSet)
    }

    @discardableResult
    func toggleWorkingSet(_ property: PropertyItem) -> AgentWorkingSetResult {
        if let index = workingSet.firstIndex(where: { $0.id == property.id }) {
            workingSet.remove(at: index)
            favoriteItems.removeAll { $0.id == property.id }
            favoriteIDs.remove(property.id)
            compareIDs.removeAll { $0 == property.id }
            persistWorkingSet()
            persistCompare()
            return .removed(count: savedCount, max: Self.maxWorkingSet)
        }
        guard workingSet.count < Self.maxWorkingSet else {
            return .limitReached(max: Self.maxWorkingSet)
        }
        var copy = property
        copy.isFav = true
        workingSet.insert(AgentSavedListing(copy), at: 0)
        favoriteItems.insert(copy, at: 0)
        favoriteIDs.insert(property.id)
        persistWorkingSet()
        return .saved(count: savedCount, max: Self.maxWorkingSet)
    }

    func applyRemoteFavorite(_ property: PropertyItem, isOn: Bool) {
        var copy = property
        copy.isFav = isOn
        if isOn {
            if let index = workingSet.firstIndex(where: { $0.id == property.id }) {
                workingSet[index] = AgentSavedListing(copy)
            } else {
                workingSet.insert(AgentSavedListing(copy), at: 0)
            }
            if let index = favoriteItems.firstIndex(where: { $0.id == property.id }) {
                favoriteItems[index] = copy
            } else {
                favoriteItems.insert(copy, at: 0)
            }
            favoriteIDs.insert(property.id)
        } else {
            workingSet.removeAll { $0.id == property.id }
            favoriteItems.removeAll { $0.id == property.id }
            favoriteIDs.remove(property.id)
            compareIDs.removeAll { $0 == property.id }
        }
        persistWorkingSet()
        persistCompare()
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
        workingSet = favoriteItems.map { AgentSavedListing($0) }
        favoriteIDs = Set(favoriteItems.map(\.id))
        compareIDs = compareIDs.filter { favoriteIDs.contains($0) }
        persistWorkingSet()
        persistCompare()
    }

    func favoriteProperties() -> [PropertyItem] {
        if favoriteItems.isEmpty == false {
            return favoriteItems
        }
        return workingSet.map { snapshot in
            var item = snapshot.asPropertyItem()
            item.isFav = true
            return item
        }
    }

    func workingSetOrInventory() -> [PropertyItem] {
        let saved = favoriteProperties()
        return saved.isEmpty ? PropertyStore.shared.all : saved
    }

    func isCompared(_ id: String) -> Bool { compareIDs.contains(id) }

    func pruneCompareIDs(keeping ids: [String]) {
        let allowed = Set(ids)
        let next = compareIDs.filter { allowed.contains($0) }
        guard next != compareIDs else { return }
        compareIDs = next
        persistCompare()
    }

    func selectedCompareCount(in ids: [String]) -> Int {
        let allowed = Set(ids)
        return compareIDs.filter { allowed.contains($0) }.count
    }

    @discardableResult
    func toggleCompare(_ id: String) -> String {
        if let index = compareIDs.firstIndex(of: id) {
            compareIDs.remove(at: index)
            persistCompare()
            return "Removed from compare."
        }
        guard compareIDs.count < 3 else {
            return "You can compare up to 3 properties."
        }
        compareIDs.append(id)
        persistCompare()
        return "Added to compare (\(compareIDs.count)/3)."
    }

    func comparedProperties() -> [PropertyItem] {
        compareIDs.compactMap { id in resolvedProperty(id: id) }
    }

    func compareCandidates() -> [PropertyItem] {
        let saved = favoriteProperties()
        return saved.isEmpty ? PropertyStore.shared.all : saved
    }

    func resolvedProperty(id: String) -> PropertyItem? {
        PropertyStore.shared.all.first { $0.id == id }
            ?? workingSet.first { $0.id == id }?.asPropertyItem()
    }

    func rememberSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recentSearches.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        recentSearches.insert(trimmed, at: 0)
        if recentSearches.count > 8 { recentSearches = Array(recentSearches.prefix(8)) }
    }

    func addClientSearch(client: String, query: String) {
        clientSearches.insert(
            AgentClientSearch(id: UUID().uuidString, client: client, query: query, date: Date()),
            at: 0
        )
        rememberSearch(query)
    }

    func deleteClientSearch(id: String) {
        clientSearches.removeAll { $0.id == id }
    }

    func recordLead(from enquiry: EnquiryItem) {
        if leads.contains(where: { $0.id == enquiry.id }) { return }
        if let requestId = enquiry.requestId, leads.contains(where: { $0.requestId == requestId }) { return }
        let lead = AgentLead(
            id: enquiry.id,
            propertyId: enquiry.propertyId,
            propertyTitle: enquiry.propertyTitle,
            clientName: enquiry.contactName,
            email: enquiry.email,
            phone: enquiry.phone,
            message: enquiry.message,
            date: enquiry.date,
            status: .new,
            kind: enquiry.kind,
            requestId: enquiry.requestId,
            listingAgentName: enquiry.listingAgentName
        )
        leads.insert(lead, at: 0)
        notifications.insert(
            AgentNotificationItem(
                id: UUID().uuidString,
                title: "New lead",
                body: "\(enquiry.contactName) enquired about \(enquiry.propertyTitle).",
                icon: "person.badge.plus",
                date: Date(),
                isRead: false,
                requestId: enquiry.requestId
            ),
            at: 0
        )
    }

    func recordAssistanceRequest(_ request: RealtorAssistanceRequest, realtor: PlatformRealtor) {
        let isAssignedHere = realtor.email.caseInsensitiveCompare(AgentAccount.shared.email) == .orderedSame
            || realtor.name.caseInsensitiveCompare(AgentAccount.shared.name) == .orderedSame
        guard isAssignedHere else { return }
        if !leads.contains(where: { $0.id == request.id }) {
            leads.insert(
                AgentLead(
                    id: request.id,
                    propertyId: "",
                    propertyTitle: request.requirement.oneLine,
                    clientName: request.buyerName,
                    email: request.buyerEmail,
                    phone: request.buyerPhone,
                    message: request.requirement.summaryText,
                    date: request.createdAt,
                    status: .new,
                    kind: .assistanceRequest,
                    requestId: request.id
                ),
                at: 0
            )
        }
        notifications.insert(
            AgentNotificationItem(
                id: UUID().uuidString,
                title: "New Client Request",
                body: "Client: \(request.buyerName)\n\nLooking for:\n\(request.requirement.summaryText)",
                icon: "person.crop.circle.badge.plus",
                date: Date(),
                isRead: false,
                requestId: request.id
            ),
            at: 0
        )
    }

    func recordBuyerMessage(request: RealtorAssistanceRequest, text: String) {
        notifications.insert(
            AgentNotificationItem(
                id: UUID().uuidString,
                title: "Client message",
                body: "\(request.buyerName): \(text)",
                icon: "envelope.fill",
                date: Date(),
                isRead: false,
                requestId: request.id
            ),
            at: 0
        )
    }

    func markLeadApiStatus(id: String, status: String) {
        guard let index = leads.firstIndex(where: { $0.id == id }) else { return }
        leads[index].apiStatus = status
    }

    func setLeadStatus(id: String, status: AgentLeadStatus) {
        guard let index = leads.firstIndex(where: { $0.id == id }) else { return }
        leads[index].status = status
        if let platform = RealtorDesk.shared.leads.first(where: { $0.id == id || $0.assistanceRequestId == leads[index].requestId }) {
            let mapped: LeadStatus
            switch status {
            case .new:
                mapped = platform.assignedRealtorId == nil ? .new : .assigned
            case .contacted:
                mapped = .contacted
            case .viewing:
                mapped = .viewing
            case .closed:
                mapped = .closed
            }
            RealtorDesk.shared.updateLeadStatus(id: platform.id, status: mapped)
        }
    }

    func replaceLeads(from platformLeads: [PlatformLead]) {
        leads = platformLeads.map { lead in
            let status: AgentLeadStatus
            switch lead.status {
            case .contacted: status = .contacted
            case .viewing: status = .viewing
            case .closed, .lost: status = .closed
            default: status = .new
            }
            return AgentLead(
                id: lead.id,
                propertyId: lead.propertyId ?? "",
                propertyTitle: lead.property?.title ?? lead.leadCode,
                clientName: lead.buyerName.isEmpty ? "Buyer".localized : lead.buyerName,
                email: lead.buyerEmail,
                phone: lead.buyerPhone,
                message: lead.requirementsSummary,
                date: lead.createdAt,
                status: status,
                kind: .propertyEnquiry,
                requestId: lead.assistanceRequestId,
                listingAgentName: lead.displayAgentName,
                apiStatus: lead.apiStatus
            )
        }
    }

    func markAllRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
    }

    private func persistCompare() {}

    private func persistWorkingSet() {}
}

extension UIViewController {
    func toggleAgentWorkingSet(_ property: PropertyItem, reload: (() -> Void)? = nil) {
        Task {
            do {
                let isFav = try await AgentViewModels.toggleFavoriteAPI(propertyId: property.id)
                await MainActor.run {
                    PropertyStore.shared.setFavorite(property.id, isOn: isFav)
                    AgentStore.shared.applyRemoteFavorite(property, isOn: isFav)
                    reload?()
                }
            } catch {
                await MainActor.run {
                    reload?()
                }
            }
        }
    }
}


//===============API Response
struct AgentRegistrationResponse: Codable {
    let success: Bool?
    let message: String?
    let data: User?
}

//struct AgentData: Codable {
//    let id: String?
//    let name: String?
//    let email: String?
//    let phone: String?
//    let role: String?
//    let status: String?
//    let agencyName: String?
//    let licenseNumber: String?
//    let document: String?
//    let profileImage: String?
//    let createdAt: String?
//}


////Login Response
//struct AgentLoginResponse: Codable {
//    let success: Bool?
//    let message: String?
//    let data: LoginData?
//}
//
//struct LoginData: Codable {
//    let accessToken: String?
//    let refreshToken: String?
//    let user: AgentData?
//}

//struct AgentUser: Codable {
//    let id: String?
//    let name: String?
//    let email: String?
//    let phone: String?
//    let role: String?
//    let status: String?
//    let agencyName: String?
//    let licenseNumber: String?
//    let liceneseNumber: String?
//    let document: String?
//    let profileImage: String?
//    let createdAt: String?
//}

struct MarketingContentResponse: Decodable {
    let success: Bool?
    let message: String?
    var requestedContentType: String = ""
    private let root: JSONValue

    var resolvedReport: String {
        MarketingContentFormatter.displayText(
            root: root,
            fallbackMessage: message,
            contentType: requestedContentType
        )
    }

    init(from decoder: Decoder) throws {
        root = try JSONValue(from: decoder)
        let object = root.objectValue
        success = object?["success"]?.boolValue
        message = object?["message"]?.stringValue
    }
}

private enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .number(Double(value))
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .null
        }
    }

    var stringValue: String? {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            return value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(value)
        case .bool(let value):
            return value ? "true" : "false"
        default:
            return nil
        }
    }

    var boolValue: Bool? {
        switch self {
        case .bool(let value): return value
        case .number(let value): return value != 0
        case .string(let value):
            switch value.lowercased() {
            case "true", "1", "yes": return true
            case "false", "0", "no": return false
            default: return nil
            }
        default:
            return nil
        }
    }

    var objectValue: [String: JSONValue]? {
        if case .object(let value) = self { return value }
        return nil
    }

    var arrayValue: [JSONValue]? {
        if case .array(let value) = self { return value }
        return nil
    }
}

private enum MarketingContentFormatter {
    private static let metaKeys: Set<String> = [
        "success", "_id", "id", "propertyId", "property_id", "createdAt", "created_at",
        "updatedAt", "updated_at", "__v", "contentType", "content_type", "language",
        "lang", "langInput", "user", "agent"
    ]

    static func displayText(root: JSONValue, fallbackMessage: String?, contentType: String = "") -> String {
        let payload = root.objectValue?["data"] ?? root
        let type = [
            contentType.isEmpty ? nil : contentType,
            payload.objectValue?["contentType"]?.stringValue,
            payload.objectValue?["content_type"]?.stringValue,
            root.objectValue?["contentType"]?.stringValue,
            root.objectValue?["content_type"]?.stringValue
        ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { $0.isEmpty == false }?
            .lowercased() ?? ""

        if let nested = payload.objectValue?[type] {
            let text = format(nested, type: type)
            if text.isEmpty == false { return text }
        }

        let text = format(payload, type: type)
        if text.isEmpty == false { return text }

        return fallbackMessage?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static func format(_ value: JSONValue, type: String) -> String {
        if let text = cleaned(value.stringValue) { return text }

        if let items = value.arrayValue {
            return items
                .map { format($0, type: type) }
                .filter { $0.isEmpty == false }
                .joined(separator: "\n\n")
        }

        guard let object = value.objectValue else { return "" }

        switch type {
        case "instagram":
            let text = formatInstagram(object)
            if text.isEmpty == false { return text }
        case "whatsapp":
            let text = formatWhatsApp(object)
            if text.isEmpty == false { return text }
        case "email":
            let text = formatEmail(object)
            if text.isEmpty == false { return text }
        default:
            break
        }

        if object["caption"] != nil || object["hashtags"] != nil || object["hashTags"] != nil {
            let text = formatInstagram(object)
            if text.isEmpty == false { return text }
        }
        if object["subject"] != nil || object["emailBody"] != nil || object["email_body"] != nil {
            let text = formatEmail(object)
            if text.isEmpty == false { return text }
        }

        for key in ["report", "content", "result", "data"] {
            if let nested = object[key] {
                let text = format(nested, type: type)
                if text.isEmpty == false { return text }
            }
        }

        if object["message"] != nil || object["text"] != nil || object["body"] != nil {
            let text = formatWhatsApp(object)
            if text.isEmpty == false { return text }
        }

        return flatten(object)
    }

    private static func formatInstagram(_ object: [String: JSONValue]) -> String {
        var parts: [String] = []
        if let caption = firstString(object, keys: ["caption", "text", "post", "content", "description", "copy"]) {
            parts.append(caption)
        }
        if let hashtags = hashtagLine(object["hashtags"] ?? object["hashTags"] ?? object["tags"]) {
            parts.append(hashtags)
        }
        if let cta = firstString(object, keys: ["cta", "callToAction", "call_to_action"]) {
            parts.append(cta)
        }
        return parts.joined(separator: "\n\n")
    }

    private static func formatWhatsApp(_ object: [String: JSONValue]) -> String {
        firstString(object, keys: [
            "message", "text", "content", "body", "whatsappMessage", "whatsapp_message", "copy"
        ]) ?? ""
    }

    private static func formatEmail(_ object: [String: JSONValue]) -> String {
        let subject = firstString(object, keys: ["subject", "emailSubject", "email_subject", "title"])
        let body = firstString(object, keys: ["body", "emailBody", "email_body", "content", "message", "text", "copy"])
        var parts: [String] = []
        if let subject {
            parts.append("Subject: \(subject)")
        }
        if let greeting = firstString(object, keys: ["greeting"]) {
            parts.append(greeting)
        }
        if let body {
            parts.append(body)
        }
        if let signature = firstString(object, keys: ["signature"]) {
            parts.append(signature)
        }
        return parts.joined(separator: "\n\n")
    }

    private static func flatten(_ object: [String: JSONValue]) -> String {
        let preferred = [
            "report", "content", "caption", "subject", "body", "message", "text",
            "hashtags", "hashTags", "tags", "cta", "callToAction", "greeting", "signature"
        ]
        var parts: [String] = []
        var seen = Set<String>()
        for key in preferred {
            guard let value = object[key] else { continue }
            seen.insert(key)
            let text = displayLine(key: key, value: value)
            if text.isEmpty == false { parts.append(text) }
        }
        for key in object.keys.sorted() where metaKeys.contains(key) == false && seen.contains(key) == false {
            let text = displayLine(key: key, value: object[key] ?? .null)
            if text.isEmpty == false { parts.append(text) }
        }
        return parts.joined(separator: "\n\n")
    }

    private static func displayLine(key: String, value: JSONValue) -> String {
        if let text = cleaned(value.stringValue) {
            if ["caption", "content", "report", "message", "text", "body", "copy"].contains(key) {
                return text
            }
            if key == "subject" { return "Subject: \(text)" }
            return "\(prettyKey(key)): \(text)"
        }
        if key == "hashtags" || key == "hashTags" || key == "tags" {
            return hashtagLine(value) ?? ""
        }
        let nested = format(value, type: "")
        if nested.isEmpty { return "" }
        if ["report", "content", "data", "result"].contains(key) { return nested }
        return "\(prettyKey(key)):\n\(nested)"
    }

    private static func hashtagLine(_ value: JSONValue?) -> String? {
        guard let value else { return nil }
        let tags: [String]
        if let items = value.arrayValue {
            tags = items.compactMap { cleaned($0.stringValue) }
        } else if let text = cleaned(value.stringValue) {
            tags = text
                .split(whereSeparator: { $0 == " " || $0 == "," || $0 == "\n" })
                .map(String.init)
                .filter { $0.isEmpty == false }
        } else {
            return nil
        }
        let formatted = tags.map { tag -> String in
            let trimmed = tag.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            return trimmed.isEmpty ? "" : "#\(trimmed)"
        }.filter { $0.isEmpty == false }
        return formatted.isEmpty ? nil : formatted.joined(separator: " ")
    }

    private static func firstString(_ object: [String: JSONValue], keys: [String]) -> String? {
        for key in keys {
            if let text = cleaned(object[key]?.stringValue) { return text }
        }
        return nil
    }

    private static func cleaned(_ value: String?) -> String? {
        let text = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? nil : text
    }

    private static func prettyKey(_ key: String) -> String {
        let spaced = key
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
        return spaced.prefix(1).uppercased() + spaced.dropFirst()
    }
}

struct AISearchHistoryItem {
    let historyId: String
    let query: String

    static func showsRemoveAll(count: Int) -> Bool {
        count > 1
    }
}

struct RecentlyAISearchResponse: Decodable {
    let success: Bool?
    let message: String?
    let history: [AISearchHistoryRecord]

    enum CodingKeys: String, CodingKey {
        case success, message, data, history
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        success = try c.decodeIfPresent(Bool.self, forKey: .success)
        message = try c.decodeIfPresent(String.self, forKey: .message)
        if let items = try c.decodeIfPresent([AISearchHistoryRecord].self, forKey: .history) {
            history = items
            return
        }
        if let nested = try? c.nestedContainer(keyedBy: CodingKeys.self, forKey: .data),
           let items = try nested.decodeIfPresent([AISearchHistoryRecord].self, forKey: .history) {
            history = items
            return
        }
        if let items = try? c.decode([AISearchHistoryRecord].self, forKey: .data) {
            history = items
            return
        }
        history = []
    }
}

struct AISearchHistoryRecord: Decodable {
    let id: String
    let query: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case altId = "id"
        case query
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try c.decodeIfPresent(String.self, forKey: .id)
            ?? c.decodeIfPresent(String.self, forKey: .altId)
            ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        query = (try c.decodeIfPresent(String.self, forKey: .query) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
