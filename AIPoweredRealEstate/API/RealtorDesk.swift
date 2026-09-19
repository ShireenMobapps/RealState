//
//  RealtorDesk.swift
//  AIPoweredRealEstate
//
//  Buyer ↔ platform realtor loop. Save/shortlist is never ownership.
//  Source listing agent is never the assigned SpeddyProp realtor.
//  Contact Agent auto-assigns; Get Help From a Realtor uses buyer choice.
//

import Foundation
import UIKit

extension Notification.Name {
    static let realtorDeskDidChange = Notification.Name("realtorDeskDidChange")
}

struct PlatformRealtor: Codable, Equatable {
    let id: String
    let name: String
    let agency: String
    let email: String
    let phone: String
    var whatsapp: String
    let serviceAreas: [String]
    var specialization: [String]
    var locationExpertise: [String]
    var languages: [String]
    var rating: Double
    var totalDeals: Int
    var responseTimeHours: Int
    var availabilityStatus: String
    var profileImageURL: String?
    let isVerified: Bool
    let isAvailable: Bool
    var openRequestCount: Int
    var totalLeadsAssigned: Int
    var totalLeadsConverted: Int
    var typicalBudgetMin: Double?
    var typicalBudgetMax: Double?
    var licenseNumber: String
    var documentURL: String?
    var status: String
    var isActive: Bool

    var displayStatus: String {
        let raw = status.trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty {
            return raw.prefix(1).uppercased() + raw.dropFirst()
        }
        if isVerified { return "Verified".localized }
        return ""
    }

    init(
        id: String,
        name: String,
        agency: String,
        email: String,
        phone: String,
        whatsapp: String? = nil,
        serviceAreas: [String],
        specialization: [String] = [],
        locationExpertise: [String] = [],
        languages: [String] = ["Spanish", "English"],
        rating: Double = 4.6,
        totalDeals: Int = 20,
        responseTimeHours: Int = 4,
        availabilityStatus: String = "active",
        profileImageURL: String? = nil,
        isVerified: Bool,
        isAvailable: Bool,
        openRequestCount: Int,
        totalLeadsAssigned: Int = 0,
        totalLeadsConverted: Int = 0,
        typicalBudgetMin: Double? = nil,
        typicalBudgetMax: Double? = nil,
        licenseNumber: String = "",
        documentURL: String? = nil,
        status: String = "",
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.agency = agency
        self.email = email
        self.phone = phone
        self.whatsapp = whatsapp ?? phone
        self.serviceAreas = serviceAreas
        self.specialization = specialization
        self.locationExpertise = locationExpertise.isEmpty ? serviceAreas : locationExpertise
        self.languages = languages
        self.rating = rating
        self.totalDeals = totalDeals
        self.responseTimeHours = responseTimeHours
        self.availabilityStatus = availabilityStatus
        self.profileImageURL = profileImageURL
        self.isVerified = isVerified
        self.isAvailable = isAvailable
        self.openRequestCount = openRequestCount
        self.totalLeadsAssigned = totalLeadsAssigned
        self.totalLeadsConverted = totalLeadsConverted
        self.typicalBudgetMin = typicalBudgetMin
        self.typicalBudgetMax = typicalBudgetMax
        self.licenseNumber = licenseNumber
        self.documentURL = documentURL
        self.status = status
        self.isActive = isActive
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        agency = try c.decode(String.self, forKey: .agency)
        email = try c.decode(String.self, forKey: .email)
        phone = try c.decode(String.self, forKey: .phone)
        whatsapp = try c.decodeIfPresent(String.self, forKey: .whatsapp) ?? phone
        serviceAreas = try c.decodeIfPresent([String].self, forKey: .serviceAreas) ?? []
        specialization = try c.decodeIfPresent([String].self, forKey: .specialization) ?? []
        locationExpertise = try c.decodeIfPresent([String].self, forKey: .locationExpertise) ?? serviceAreas
        languages = try c.decodeIfPresent([String].self, forKey: .languages) ?? ["Spanish", "English"]
        rating = try c.decodeIfPresent(Double.self, forKey: .rating) ?? 4.6
        totalDeals = try c.decodeIfPresent(Int.self, forKey: .totalDeals) ?? 20
        responseTimeHours = try c.decodeIfPresent(Int.self, forKey: .responseTimeHours) ?? 4
        availabilityStatus = try c.decodeIfPresent(String.self, forKey: .availabilityStatus) ?? "active"
        profileImageURL = try c.decodeIfPresent(String.self, forKey: .profileImageURL)
        isVerified = try c.decodeIfPresent(Bool.self, forKey: .isVerified) ?? true
        isAvailable = try c.decodeIfPresent(Bool.self, forKey: .isAvailable) ?? true
        openRequestCount = try c.decodeIfPresent(Int.self, forKey: .openRequestCount) ?? 0
        totalLeadsAssigned = try c.decodeIfPresent(Int.self, forKey: .totalLeadsAssigned) ?? 0
        totalLeadsConverted = try c.decodeIfPresent(Int.self, forKey: .totalLeadsConverted) ?? 0
        typicalBudgetMin = try c.decodeIfPresent(Double.self, forKey: .typicalBudgetMin)
        typicalBudgetMax = try c.decodeIfPresent(Double.self, forKey: .typicalBudgetMax)
        licenseNumber = try c.decodeIfPresent(String.self, forKey: .licenseNumber) ?? ""
        documentURL = try c.decodeIfPresent(String.self, forKey: .documentURL)
        status = try c.decodeIfPresent(String.self, forKey: .status) ?? ""
        isActive = try c.decodeIfPresent(Bool.self, forKey: .isActive) ?? isAvailable
    }
}

struct ClientRequirement: Codable, Equatable {
    var query: String
    var location: String?
    var propertyType: String?
    var purpose: String?
    var bedrooms: Int?
    var bathrooms: Int?
    var furnished: Bool?
    var budgetMax: Int?
    var amenities: [String]

    var summaryText: String {
        var lines: [String] = []
        if let location { lines.append("Location: \(location)") }
        if let propertyType { lines.append("Type: \(propertyType)") }
        if let purpose { lines.append("Purpose: \(purpose)") }
        if let bedrooms { lines.append("Bedrooms: \(bedrooms)") }
        if let bathrooms { lines.append("Bathrooms: \(bathrooms)") }
        if let furnished { lines.append("Furnished: \(furnished ? "Yes" : "No")") }
        if let budgetMax { lines.append("Budget: $\(budgetMax.formatted())") }
        if !amenities.isEmpty { lines.append("Amenities: \(amenities.joined(separator: ", "))") }
        if lines.isEmpty { return query.isEmpty ? "Open brief" : query }
        if !query.isEmpty { lines.insert(query, at: 0) }
        return lines.joined(separator: "\n")
    }

    var oneLine: String {
        [purpose, bedrooms.map { "\($0) Bedroom" }, propertyType, location, furnished == true ? "Furnished" : nil, budgetMax.map { "Maximum $\($0.formatted())" }]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    static func from(criteria: PropertySearchCriteria, query: String? = nil) -> ClientRequirement {
        ClientRequirement(
            query: (query ?? criteria.keyword).trimmingCharacters(in: .whitespacesAndNewlines),
            location: RealtorDesk.normalizedLocation(criteria.location ?? criteria.keyword),
            propertyType: criteria.propertyType,
            purpose: criteria.listingType,
            bedrooms: criteria.minBedrooms,
            bathrooms: criteria.minBathrooms,
            furnished: criteria.furnished,
            budgetMax: criteria.maxPrice,
            amenities: Array(criteria.amenities)
        )
    }

    static func from(query: String) -> ClientRequirement {
        let text = query.lowercased()
        var location: String?
        ["naco", "piantini", "punta cana", "santo domingo", "santiago", "puerto plata", "cap cana"].forEach { city in
            if text.contains(city) { location = RealtorDesk.normalizedLocation(city) }
        }
        var type: String?
        if text.contains("villa") { type = "Villa" }
        else if text.contains("house") { type = "House" }
        else if text.contains("apartment") || text.contains("condo") { type = "Apartment" }
        var purpose: String?
        if text.contains("rent") { purpose = "Rent" }
        else if text.contains("buy") || text.contains("purchase") { purpose = "Buy" }
        let beds = [1, 2, 3, 4, 5].first { text.contains("\($0)") && (text.contains("bed") || text.contains("br")) }
            ?? [1, 2, 3, 4, 5].first { text.contains("\($0)-bed") }
        var budget: Int?
        if let match = text.range(of: #"\$?\s*([0-9]{3,7})"#, options: .regularExpression) {
            let digits = text[match].filter(\.isNumber)
            budget = Int(digits)
        }
        var amenities: [String] = []
        if text.contains("parking") { amenities.append("Parking") }
        if text.contains("pool") { amenities.append("Pool") }
        if text.contains("gym") { amenities.append("Gym") }
        let furnished: Bool? = text.contains("unfurnished") ? false : (text.contains("furnished") ? true : nil)
        return ClientRequirement(
            query: query,
            location: location,
            propertyType: type,
            purpose: purpose,
            bedrooms: beds,
            bathrooms: nil,
            furnished: furnished,
            budgetMax: budget,
            amenities: amenities
        )
    }
}

enum AssistanceStatus: String, Codable {
    case submitted = "Submitted"
    case assigned = "Assigned"
    case searching = "Searching"
    case shared = "Recommendations shared"
    case closed = "Closed"
}

enum AgentLeadKind: String, Codable {
    case propertyEnquiry = "Property enquiry"
    case assistanceRequest = "Realtor assistance"
    case moreInformation = "More information"
}

struct RealtorAssistanceRequest: Codable {
    let id: String
    let buyerName: String
    let buyerEmail: String
    let buyerPhone: String
    var requirement: ClientRequirement
    var status: AssistanceStatus
    var assignedRealtorId: String?
    let createdAt: Date
}

struct PropertyMatch: Codable {
    let propertyId: String
    let rank: Int
    let score: Int
    let why: String
    var approved: Bool
}

struct ClientFacingReport: Codable {
    let id: String
    let requestId: String
    let realtorId: String
    let clientName: String
    var matches: [PropertyMatch]
    var comparisonSummary: String
    var isApproved: Bool
    var isSharedWithBuyer: Bool
    let createdAt: Date
}

struct BuyerMessage: Codable {
    let id: String
    let requestId: String
    let fromBuyer: Bool
    let text: String
    let date: Date
}

final class RealtorDesk {
    static let shared = RealtorDesk()
    static let didChange = Notification.Name.realtorDeskDidChange

    private let defaults = UserDefaults.standard
    private let persistKey = "realtorDeskState.v3"

    private(set) var roster: [PlatformRealtor]
    private(set) var requests: [RealtorAssistanceRequest] = []
    private(set) var reports: [ClientFacingReport] = []
    private(set) var messages: [BuyerMessage] = []
    private(set) var leads: [PlatformLead] = []
    private(set) var leadNotifications: [LeadNotificationRecord] = []
    var activeRequestId: String?
    var activeLeadId: String?

    var activeRequest: RealtorAssistanceRequest? {
        guard let activeRequestId else { return nil }
        return requests.first { $0.id == activeRequestId }
    }

    var buyerActiveRequest: RealtorAssistanceRequest? {
        let email = TenantAccount.shared.email.trimmingCharacters(in: .whitespacesAndNewlines)
        return requests
            .sorted { $0.createdAt > $1.createdAt }
            .first { request in
                guard request.status != .closed else { return false }
                if email.isEmpty { return true }
                return request.buyerEmail.caseInsensitiveCompare(email) == .orderedSame
            }
    }

    private init() {
        roster = Self.defaultRoster()
        if let data = defaults.data(forKey: persistKey),
           let state = try? JSONDecoder().decode(Persisted.self, from: data) {
            requests = state.requests
            reports = state.reports
            messages = state.messages
            roster = state.roster.count >= 3 ? mergeRoster(state.roster) : Self.defaultRoster()
            activeRequestId = state.activeRequestId
            leads = state.leads
            leadNotifications = state.leadNotifications
            migrateAssignedLeads()
        }
    }

    // MARK: - Leads (Contact Agent)

    func createLead(from request: LeadCreateRequest) -> PlatformLead {
        let lead = PlatformLead(
            id: UUID().uuidString,
            leadCode: nextLeadCode(),
            buyerId: request.buyerId,
            assignedRealtorId: nil,
            assignedAgentName: nil,
            propertyId: request.propertyId,
            requirements: request.requirements,
            budgetMin: request.budgetMin,
            budgetMax: request.budgetMax,
            preferredLanguage: request.preferredLanguage,
            preferredContactMethod: request.preferredContactMethod,
            status: .new,
            source: request.source,
            assignmentMetadata: nil,
            contactHistory: [],
            createdAt: Date(),
            updatedAt: Date(),
            buyerName: request.buyerName,
            buyerEmail: request.buyerEmail,
            buyerPhone: request.buyerPhone,
            assistanceRequestId: nil
        )
        leads.insert(lead, at: 0)
        persist()
        notifyChange()
        return lead
    }

    func lead(id: String) -> PlatformLead? {
        leads.first { $0.id == id || $0.leadCode == id }
    }

    func latestBuyerLead() -> PlatformLead? {
        buyerLeads().first
    }

    func buyerLeads() -> [PlatformLead] {
        let email = TenantAccount.shared.email.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = TenantAccount.shared.phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = TenantAccount.shared.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = leads.filter { lead in
            if !email.isEmpty {
                if lead.buyerId.caseInsensitiveCompare(email) == .orderedSame
                    || lead.buyerEmail.caseInsensitiveCompare(email) == .orderedSame {
                    return true
                }
            }
            if !phone.isEmpty,
               lead.buyerPhone.filter(\.isNumber) == phone.filter(\.isNumber),
               !lead.buyerPhone.filter(\.isNumber).isEmpty {
                return true
            }
            if email.isEmpty, phone.isEmpty, !name.isEmpty {
                return lead.buyerName.caseInsensitiveCompare(name) == .orderedSame
            }
            return false
        }
        let source = filtered.isEmpty ? leads : filtered
        return source.sorted { $0.createdAt > $1.createdAt }
    }

    private func migrateAssignedLeads() {
        var changed = false
        for index in leads.indices where leads[index].assignedRealtorId != nil && leads[index].status == .new {
            leads[index].status = .assigned
            changed = true
        }
        if changed { persist() }
    }

    func assign(leadId: String, realtorId: String, metadata: AssignmentMetadata) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        leads[index].assignedRealtorId = realtorId
        leads[index].assignmentMetadata = metadata
        leads[index].status = .assigned
        leads[index].updatedAt = Date()
        if let realtorIndex = roster.firstIndex(where: { $0.id == realtorId }) {
            roster[realtorIndex].totalLeadsAssigned += 1
        }
        persist()
        notifyChange()
    }

    func linkLead(_ leadId: String, assistanceRequestId: String) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        leads[index].assistanceRequestId = assistanceRequestId
        persist()
    }

    func addContact(leadId: String, method: PreferredContactMethod, message: String, notes: String, fromBuyer: Bool) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        leads[index].contactHistory.insert(
            ContactHistoryEntry(
                id: UUID().uuidString,
                method: method.rawValue,
                message: message,
                notes: notes,
                date: Date(),
                fromBuyer: fromBuyer
            ),
            at: 0
        )
        leads[index].updatedAt = Date()
        let shouldMarkContacted = !fromBuyer && (leads[index].status == .new || leads[index].status == .assigned)
        persist()
        notifyChange()
        if shouldMarkContacted {
            updateLeadStatus(id: leadId, status: .contacted)
        }
    }

    func updateLeadStatus(id: String, status: LeadStatus) {
        guard let index = leads.firstIndex(where: { $0.id == id }) else { return }
        let previous = leads[index].status
        guard previous != status else { return }
        leads[index].status = status
        leads[index].updatedAt = Date()
        persist()
        notifyChange()
        NotificationService.shared.notifyLeadStatusChange(lead: leads[index], previous: previous)
    }

    func saveNotification(_ record: LeadNotificationRecord) {
        leadNotifications.insert(record, at: 0)
        persist()
        notifyChange()
    }

    func notifications(forLead leadId: String, userType: String? = nil, isRead: Bool? = nil) -> [LeadNotificationRecord] {
        leadNotifications.filter { item in
            guard item.leadId == leadId else { return false }
            if let userType, item.userType != userType { return false }
            if let isRead, item.isRead != isRead { return false }
            return true
        }
    }

    func buyerNotifications() -> [LeadNotificationRecord] {
        let email = TenantAccount.shared.email
        let leadIds = Set(buyerLeads().map(\.id))
        return leadNotifications.filter { item in
            guard item.userType == "buyer" else { return false }
            if leadIds.contains(item.leadId) { return true }
            return item.userId.caseInsensitiveCompare(email) == .orderedSame
        }
    }

    func unreadBuyerNotificationCount() -> Int {
        buyerNotifications().filter { !$0.isRead }.count
    }

    func markNotificationRead(_ id: String) {
        guard let index = leadNotifications.firstIndex(where: { $0.id == id }) else { return }
        leadNotifications[index].isRead = true
        persist()
    }

    private func nextLeadCode() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let day = formatter.string(from: Date())
        let prefix = "LEAD_\(day)_"
        let todayCount = leads.filter { $0.leadCode.hasPrefix(prefix) }.count + 1
        return prefix + String(format: "%03d", todayCount)
    }

    private func mergeRoster(_ stored: [PlatformRealtor]) -> [PlatformRealtor] {
        let fresh = Self.defaultRoster()
        return fresh.map { template in
            guard let existing = stored.first(where: { $0.id == template.id }) else { return template }
            var next = template
            next.openRequestCount = existing.openRequestCount
            next.totalLeadsAssigned = max(existing.totalLeadsAssigned, template.totalLeadsAssigned)
            next.totalLeadsConverted = existing.totalLeadsConverted
            return next
        }
    }

    func availableRealtors() -> [PlatformRealtor] {
        roster
            .filter { $0.isVerified && $0.isAvailable && $0.availabilityStatus == "active" }
            .sorted { lhs, rhs in
                if lhs.openRequestCount != rhs.openRequestCount {
                    return lhs.openRequestCount < rhs.openRequestCount
                }
                return lhs.name < rhs.name
            }
    }

    func replaceRoster(with agents: [PlatformRealtor]) {
        roster = agents
        persist()
        notifyChange()
    }

    func replaceBuyerLeads(with remote: [PlatformLead]) {
        leads = remote
        persist()
        notifyChange()
    }

    @discardableResult
    func submitAssistanceRequest(requirement: ClientRequirement, realtorId: String) -> RealtorAssistanceRequest {
        let buyer = TenantAccount.shared
        var request = RealtorAssistanceRequest(
            id: UUID().uuidString,
            buyerName: buyer.name,
            buyerEmail: buyer.email,
            buyerPhone: buyer.phone,
            requirement: requirement,
            status: .submitted,
            assignedRealtorId: nil,
            createdAt: Date()
        )
        let realtor = availableRealtors().first { $0.id == realtorId }
            ?? self.realtor(id: realtorId)
            ?? availableRealtors().first
            ?? roster.first { $0.isVerified }
            ?? roster[0]
        request.assignedRealtorId = realtor.id
        request.status = .assigned
        incrementWorkload(realtorId: realtor.id)
        requests.insert(request, at: 0)
        persist()

        AgentStore.shared.recordAssistanceRequest(request, realtor: realtor)
        notifyChange()
        return request
    }

    func realtor(id: String?) -> PlatformRealtor? {
        guard let id else { return nil }
        return roster.first { $0.id == id }
    }

    func assignedRealtor(for request: RealtorAssistanceRequest) -> PlatformRealtor? {
        realtor(id: request.assignedRealtorId)
    }

    func buyerAssignedRealtor() -> PlatformRealtor? {
        guard let request = buyerActiveRequest else { return nil }
        return assignedRealtor(for: request)
    }

    func inboundRequests(for agent: AgentAccount = .shared) -> [RealtorAssistanceRequest] {
        requests.filter { request in
            guard let realtor = assignedRealtor(for: request) else { return false }
            return realtor.email.caseInsensitiveCompare(agent.email) == .orderedSame
                || realtor.name.caseInsensitiveCompare(agent.name) == .orderedSame
        }
    }

    func setActiveRequest(_ id: String?) {
        activeRequestId = id
        if let id, let index = requests.firstIndex(where: { $0.id == id }), requests[index].status == .assigned {
            requests[index].status = .searching
        }
        persist()
        notifyChange()
    }

    func setActiveLead(_ id: String?) {
        let trimmed = id?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        activeLeadId = trimmed.isEmpty ? nil : trimmed
        if let leadId = activeLeadId {
            if let platform = leads.first(where: { $0.id == leadId }) {
                setActiveRequest(platform.assistanceRequestId)
                return
            }
            if let agentLead = AgentStore.shared.leads.first(where: { $0.id == leadId }),
               let requestId = agentLead.requestId {
                setActiveRequest(requestId)
                return
            }
        }
        notifyChange()
    }

    func markSearching(_ id: String) {
        guard let index = requests.firstIndex(where: { $0.id == id }) else { return }
        if requests[index].status == .assigned || requests[index].status == .submitted {
            requests[index].status = .searching
            persist()
            notifyChange()
        }
    }

    // MARK: - Ranking (not ownership)

    func rankedMatches(for requirement: ClientRequirement, from properties: [PropertyItem]? = nil, limit: Int = 3) -> [PropertyMatch] {
        let pool = properties ?? PropertyStore.shared.all
        let scored = pool.map { property -> (PropertyItem, Int, String) in
            let result = score(property, requirement: requirement)
            return (property, result.0, result.1)
        }
        .sorted { $0.1 > $1.1 }
        return Array(scored.prefix(limit)).enumerated().map { index, item in
            PropertyMatch(propertyId: item.0.id, rank: index + 1, score: item.1, why: item.2, approved: true)
        }
    }

    func draftReport(request: RealtorAssistanceRequest, properties: [PropertyItem]) -> ClientFacingReport {
        let requirement = request.requirement
        let matches: [PropertyMatch]
        if properties.isEmpty {
            matches = rankedMatches(for: requirement)
        } else {
            matches = rankedMatches(for: requirement, from: properties, limit: min(3, properties.count))
        }
        let items = matches.compactMap { match in PropertyStore.shared.all.first { $0.id == match.propertyId } }
        return ClientFacingReport(
            id: UUID().uuidString,
            requestId: request.id,
            realtorId: request.assignedRealtorId ?? "",
            clientName: request.buyerName,
            matches: matches,
            comparisonSummary: PropertyStore.shared.comparisonSummary(for: items),
            isApproved: false,
            isSharedWithBuyer: false,
            createdAt: Date()
        )
    }

    @discardableResult
    func shareReport(_ report: ClientFacingReport) -> ClientFacingReport {
        var next = report
        next.isApproved = true
        next.isSharedWithBuyer = true
        if let index = reports.firstIndex(where: { $0.id == next.id }) {
            reports[index] = next
        } else {
            reports.insert(next, at: 0)
        }
        if let requestIndex = requests.firstIndex(where: { $0.id == next.requestId }) {
            requests[requestIndex].status = .shared
        }
        persist()
        notifyChange()
        return next
    }

    @discardableResult
    func shareCompare(properties: [PropertyItem], clientName: String) -> ClientFacingReport {
        if let request = activeRequest ?? inboundRequests().first {
            var report = draftReport(request: request, properties: properties)
            report.matches = report.matches.map { match in
                var next = match
                next.approved = true
                return next
            }
            report.comparisonSummary = PropertyStore.shared.comparisonSummary(for: properties)
            return shareReport(report)
        }
        let matches = Array(properties.prefix(3)).enumerated().map { index, property in
            PropertyMatch(
                propertyId: property.id,
                rank: index + 1,
                score: 0,
                why: PropertyStore.shared.comparisonSummary(for: [property]),
                approved: true
            )
        }
        let report = ClientFacingReport(
            id: UUID().uuidString,
            requestId: "",
            realtorId: AgentAccount.shared.email,
            clientName: clientName,
            matches: matches,
            comparisonSummary: PropertyStore.shared.comparisonSummary(for: properties),
            isApproved: true,
            isSharedWithBuyer: true,
            createdAt: Date()
        )
        reports.insert(report, at: 0)
        persist()
        notifyChange()
        return report
    }

    func reportsForBuyer() -> [ClientFacingReport] {
        reports.filter(\.isSharedWithBuyer)
    }

    func latestSharedReport() -> ClientFacingReport? {
        reportsForBuyer().sorted { $0.createdAt > $1.createdAt }.first
    }

    func addMessage(requestId: String, fromBuyer: Bool, text: String) {
        messages.insert(
            BuyerMessage(id: UUID().uuidString, requestId: requestId, fromBuyer: fromBuyer, text: text, date: Date()),
            at: 0
        )
        persist()
        notifyChange()
    }

    func messages(for requestId: String) -> [BuyerMessage] {
        messages.filter { $0.requestId == requestId }.sorted { $0.date > $1.date }
    }

    static func normalizedLocation(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let text = raw.lowercased()
        if text.contains("naco") || text.contains("piantini") { return "Santo Domingo" }
        return PropertyStore.locations.first { text.contains($0.lowercased()) } ?? (raw.isEmpty ? nil : raw)
    }

    private func score(_ property: PropertyItem, requirement: ClientRequirement) -> (Int, String) {
        var score = 10
        var reasons: [String] = []
        if let location = requirement.location, property.location.localizedCaseInsensitiveContains(location) {
            score += 24
            reasons.append("In \(property.location)")
        }
        if let purpose = requirement.purpose, property.listingType.caseInsensitiveCompare(purpose) == .orderedSame {
            score += 18
            reasons.append(purpose)
        }
        if let type = requirement.propertyType, property.propertyType.caseInsensitiveCompare(type) == .orderedSame {
            score += 14
            reasons.append(type)
        }
        if let beds = requirement.bedrooms, property.bedrooms >= beds {
            score += 12
            reasons.append("\(property.bedrooms) bedrooms")
        }
        if let furnished = requirement.furnished, property.isFurnished == furnished {
            score += 10
            reasons.append(furnished ? "Furnished" : "Unfurnished")
        }
        if let budget = requirement.budgetMax, property.priceValue <= budget {
            score += 16
            reasons.append("Within budget at \(property.priceText)")
        } else if requirement.budgetMax != nil {
            score -= 8
        }
        for amenity in requirement.amenities where property.hasAmenity(amenity) {
            score += 6
            reasons.append(amenity)
        }
        if reasons.isEmpty {
            reasons.append("Available in the centralized inventory")
        }
        return (score, reasons.joined(separator: " · "))
    }

    private func incrementWorkload(realtorId: String) {
        guard let index = roster.firstIndex(where: { $0.id == realtorId }) else { return }
        roster[index].openRequestCount += 1
    }

    private func persist() {
        let state = Persisted(
            roster: roster,
            requests: requests,
            reports: reports,
            messages: messages,
            activeRequestId: activeRequestId,
            leads: leads,
            leadNotifications: leadNotifications
        )
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: persistKey)
        }
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: .realtorDeskDidChange, object: nil)
    }

    private static func defaultRoster() -> [PlatformRealtor] {
        [
            PlatformRealtor(
                id: "pr-maria",
                name: "Maria Santos",
                agency: "Caribbean Homes",
                email: "maria.santos@caribbeanhomes.com",
                phone: "+1 809 555 0188",
                whatsapp: "+1 809 555 0188",
                serviceAreas: ["Piantini", "Naco", "Bella Vista", "Santo Domingo", "Punta Cana"],
                specialization: ["Apartment", "Condo"],
                locationExpertise: ["Piantini", "Naco", "Bella Vista", "Santo Domingo"],
                languages: ["Spanish", "English"],
                rating: 4.9,
                totalDeals: 86,
                responseTimeHours: 2,
                isVerified: true,
                isAvailable: true,
                openRequestCount: 0,
                typicalBudgetMin: 800,
                typicalBudgetMax: 2_500
            ),
            PlatformRealtor(
                id: "pr-rahul",
                name: "Rahul Mehta",
                agency: "SpeddyProp Santo Domingo",
                email: "rahul.mehta@speddyprop.com",
                phone: "+1 809 555 0211",
                whatsapp: "+1 809 555 0211",
                serviceAreas: ["Santo Domingo", "Santiago"],
                specialization: ["Apartment", "House"],
                locationExpertise: ["Santo Domingo", "Santiago"],
                languages: ["English", "Spanish"],
                rating: 4.6,
                totalDeals: 41,
                responseTimeHours: 4,
                isVerified: true,
                isAvailable: true,
                openRequestCount: 1,
                typicalBudgetMin: 700,
                typicalBudgetMax: 3_000
            ),
            PlatformRealtor(
                id: "pr-sofia",
                name: "Sofia Chen",
                agency: "East Coast Realty",
                email: "sofia.chen@eastcoast.do",
                phone: "+1 809 555 0330",
                whatsapp: "+1 809 555 0330",
                serviceAreas: ["Punta Cana", "Cap Cana", "Puerto Plata"],
                specialization: ["Villa", "House"],
                locationExpertise: ["Punta Cana", "Cap Cana"],
                languages: ["English", "Spanish"],
                rating: 4.8,
                totalDeals: 62,
                responseTimeHours: 3,
                isVerified: true,
                isAvailable: true,
                openRequestCount: 2,
                typicalBudgetMin: 180_000,
                typicalBudgetMax: 2_000_000
            ),
            PlatformRealtor(
                id: "pr-carlos",
                name: "Carlos Peña",
                agency: "Capital DR Brokers",
                email: "carlos.pena@capitaldr.com",
                phone: "+1 809 555 0440",
                whatsapp: "+1 809 555 0440",
                serviceAreas: ["Santo Domingo", "Santiago"],
                specialization: ["House", "Villa"],
                locationExpertise: ["Santo Domingo", "Bella Vista"],
                languages: ["Spanish"],
                rating: 4.4,
                totalDeals: 33,
                responseTimeHours: 6,
                isVerified: true,
                isAvailable: true,
                openRequestCount: 1,
                typicalBudgetMin: 120_000,
                typicalBudgetMax: 900_000
            ),
            PlatformRealtor(
                id: "pr-ana",
                name: "Ana López",
                agency: "North Coast Homes",
                email: "ana.lopez@northcoast.do",
                phone: "+1 809 555 0550",
                whatsapp: "+1 809 555 0550",
                serviceAreas: ["Puerto Plata", "Santiago", "Cap Cana"],
                specialization: ["Apartment", "Condo"],
                locationExpertise: ["Puerto Plata", "Santiago"],
                languages: ["Spanish", "English"],
                rating: 4.7,
                totalDeals: 54,
                responseTimeHours: 3,
                isVerified: true,
                isAvailable: true,
                openRequestCount: 0,
                typicalBudgetMin: 600,
                typicalBudgetMax: 2_200
            )
        ]
    }

    private struct Persisted: Codable {
        var roster: [PlatformRealtor]
        var requests: [RealtorAssistanceRequest]
        var reports: [ClientFacingReport]
        var messages: [BuyerMessage]
        var activeRequestId: String?
        var leads: [PlatformLead]
        var leadNotifications: [LeadNotificationRecord]

        init(
            roster: [PlatformRealtor],
            requests: [RealtorAssistanceRequest],
            reports: [ClientFacingReport],
            messages: [BuyerMessage],
            activeRequestId: String?,
            leads: [PlatformLead],
            leadNotifications: [LeadNotificationRecord]
        ) {
            self.roster = roster
            self.requests = requests
            self.reports = reports
            self.messages = messages
            self.activeRequestId = activeRequestId
            self.leads = leads
            self.leadNotifications = leadNotifications
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            roster = try c.decodeIfPresent([PlatformRealtor].self, forKey: .roster) ?? []
            requests = try c.decodeIfPresent([RealtorAssistanceRequest].self, forKey: .requests) ?? []
            reports = try c.decodeIfPresent([ClientFacingReport].self, forKey: .reports) ?? []
            messages = try c.decodeIfPresent([BuyerMessage].self, forKey: .messages) ?? []
            activeRequestId = try c.decodeIfPresent(String.self, forKey: .activeRequestId)
            leads = try c.decodeIfPresent([PlatformLead].self, forKey: .leads) ?? []
            leadNotifications = try c.decodeIfPresent([LeadNotificationRecord].self, forKey: .leadNotifications) ?? []
        }
    }
}

extension Int {
    fileprivate func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
