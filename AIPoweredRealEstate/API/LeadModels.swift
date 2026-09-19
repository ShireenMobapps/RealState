//
//  LeadModels.swift
//  AIPoweredRealEstate
//
//  Contact Agent lead, assignment, and notification models.
//

import Foundation

enum LeadStatus: String, Codable, CaseIterable {
    case new
    case assigned
    case contacted
    case viewing
    case closed
    case lost

    var displayName: String {
        switch self {
        case .new: return "New".localized
        case .assigned: return "Assigned".localized
        case .contacted: return "Contacted".localized
        case .viewing: return "Viewing".localized
        case .closed: return "Closed".localized
        case .lost: return "Lost".localized
        }
    }

    var buyerExplanation: String {
        switch self {
        case .new: return "Lead created, waiting for realtor assignment".localized
        case .assigned: return "Realtor assigned to this lead".localized
        case .contacted: return "Realtor has contacted buyer".localized
        case .viewing: return "Property viewing scheduled".localized
        case .closed: return "Deal closed successfully".localized
        case .lost: return "Lead lost".localized
        }
    }

    var showsAssignedRealtor: Bool {
        self != .new
    }
}

enum PreferredContactMethod: String, Codable, CaseIterable {
    case whatsapp
    case phone
    case email
    case inApp = "in_app"

    var displayName: String {
        switch self {
        case .whatsapp: return "WhatsApp".localized
        case .phone: return "Call".localized
        case .email: return "Email".localized
        case .inApp: return "In-app".localized
        }
    }
}

enum LeadSource: String, Codable {
    case propertyListing = "property_listing"
    case aiSearch = "ai_search"
    case manualSearch = "manual_search"
}

enum AssignmentMode: String, Codable {
    case autoAssign = "auto_assign"
    case buyerChoice = "buyer_choice"
    case roundRobin = "round_robin"
}

struct LeadRequirements: Equatable {
    var location: String?
    var zones: [String]
    var propertyType: String?
    var budgetMin: Double?
    var budgetMax: Double?
    var preferredLanguage: String?
    var rawText: String

    init(
        location: String? = nil,
        zones: [String] = [],
        propertyType: String? = nil,
        budgetMin: Double? = nil,
        budgetMax: Double? = nil,
        preferredLanguage: String? = nil,
        rawText: String = ""
    ) {
        self.location = location
        self.zones = zones
        self.propertyType = propertyType
        self.budgetMin = budgetMin
        self.budgetMax = budgetMax
        self.preferredLanguage = preferredLanguage
        self.rawText = rawText
    }

    static func from(property: PropertyItem?, text: String, budgetMax: Double?, language: String?) -> LeadRequirements {
        let combined = [text, property.map { "\($0.bedrooms) bedroom \($0.propertyType) in \($0.location)" } ?? ""]
            .joined(separator: " ")
        let parsed = ClientRequirement.from(query: combined)
        var zones = RealtorMatchingService.zones(in: combined)
        if let location = property?.location, !zones.contains(where: { $0.caseInsensitiveCompare(location) == .orderedSame }) {
            zones.insert(location, at: 0)
        }
        return LeadRequirements(
            location: zones.first ?? parsed.location ?? property?.location,
            zones: zones,
            propertyType: parsed.propertyType ?? property?.propertyType,
            budgetMin: nil,
            budgetMax: budgetMax ?? parsed.budgetMax.map(Double.init) ?? property.map { Double($0.priceValue) },
            preferredLanguage: language,
            rawText: text
        )
    }

    static func from(requirement: ClientRequirement, language: String? = nil) -> LeadRequirements {
        let text = requirement.summaryText
        var zones = RealtorMatchingService.zones(in: text)
        if let location = requirement.location, !zones.contains(where: { $0.caseInsensitiveCompare(location) == .orderedSame }) {
            zones.append(location)
        }
        return LeadRequirements(
            location: zones.first ?? requirement.location,
            zones: zones,
            propertyType: requirement.propertyType,
            budgetMin: nil,
            budgetMax: requirement.budgetMax.map(Double.init),
            preferredLanguage: language,
            rawText: requirement.query.isEmpty ? text : requirement.query
        )
    }
}

struct ContactHistoryEntry: Codable, Equatable {
    let id: String
    let method: String
    let message: String
    let notes: String
    let date: Date
    let fromBuyer: Bool

    var methodDisplayName: String {
        PreferredContactMethod(rawValue: method)?.displayName ?? method.capitalized.localized
    }

    var performedBy: String {
        fromBuyer ? "Buyer".localized : "Realtor".localized
    }
}

struct AssignmentMetadata: Codable, Equatable {
    var totalRealtorsEvaluated: Int
    var realtorsAboveThreshold: Int
    var thresholdScore: Int
    var matchingCriteriaUsed: [String]
    var recommendationConfidence: String
    var assignmentTimestamp: Date
    var assignmentMode: String
    var matchScore: Double?
    var assignmentReason: String?
}

struct MatchScoreBreakdown: Equatable {
    var totalScore: Double
    var locationScore: Double
    var propertyTypeScore: Double
    var budgetScore: Double
    var languageScore: Double
    var performanceScore: Double
    var responseTimeScore: Double
    var breakdown: [String: String]

    var isQualified: Bool { totalScore >= 70 }
}

struct RealtorRecommendation: Equatable {
    let realtor: PlatformRealtor
    let score: MatchScoreBreakdown
    var assignmentReason: String {
        let parts = [
            score.breakdown["location"],
            score.breakdown["property_type"],
            score.breakdown["budget"]
        ].compactMap { $0 }
        let summary = parts.isEmpty ? "Qualified SpeddyProp realtor" : parts.joined(separator: " · ")
        return "Match \(Int(score.totalScore)) — \(summary)"
    }
}

struct AssignmentResult {
    var assignedRealtor: PlatformRealtor?
    var realtorRecommendations: [RealtorRecommendation]
    var metadata: AssignmentMetadata
}

struct LeadCreateRequest {
    var buyerId: String
    var buyerName: String
    var buyerEmail: String
    var buyerPhone: String
    var propertyId: String?
    var requirements: String
    var budgetMin: Double?
    var budgetMax: Double?
    var preferredLanguage: String?
    var preferredContactMethod: PreferredContactMethod
    var source: LeadSource
}

struct PlatformLead: Codable, Equatable {
    let id: String
    var leadCode: String
    let buyerId: String
    var assignedRealtorId: String?
    var assignedAgentName: String?
    var propertyId: String?
    var requirements: String
    var budgetMin: Double?
    var budgetMax: Double?
    var preferredLanguage: String?
    var preferredContactMethod: PreferredContactMethod
    var status: LeadStatus
    var source: LeadSource
    var assignmentMetadata: AssignmentMetadata?
    var contactHistory: [ContactHistoryEntry]
    let createdAt: Date
    var updatedAt: Date
    var buyerName: String
    var buyerEmail: String
    var buyerPhone: String
    var assistanceRequestId: String?
    var apiStatus: String = ""

    enum CodingKeys: String, CodingKey {
        case id, leadCode, buyerId, assignedRealtorId, assignedAgentName, propertyId
        case requirements, budgetMin, budgetMax, preferredLanguage, preferredContactMethod
        case status, source, assignmentMetadata, contactHistory, createdAt, updatedAt
        case buyerName, buyerEmail, buyerPhone, assistanceRequestId
    }

    var property: PropertyItem? {
        guard let propertyId else { return nil }
        return PropertyStore.shared.all.first { $0.id == propertyId }
    }

    var assignedRealtor: PlatformRealtor? {
        RealtorDesk.shared.realtor(id: assignedRealtorId)
    }

    var displayAgentName: String? {
        if let name = assignedAgentName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }
        return assignedRealtor?.name
    }

    var displayLeadCode: String {
        let code = leadCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty, code != id else { return "" }
        if code.range(of: "^[a-fA-F0-9]{24}$", options: .regularExpression) != nil {
            return ""
        }
        return code
    }

    var requirementsSummary: String {
        let text = requirements.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return "No requirements yet.".localized }
        return text
    }

    func matchesLeadSearch(_ raw: String) -> Bool {
        let query = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return true }
        let haystack = [
            buyerName,
            buyerEmail,
            buyerPhone,
            requirements,
            displayLeadCode,
            property?.title ?? "",
            property?.location ?? ""
        ]
        .map { $0.lowercased() }
        .joined(separator: " ")
        let tokens = query.split {
            $0.isWhitespace || $0 == "," || $0 == "·" || $0 == "/"
        }.map(String.init).filter { !$0.isEmpty }
        return tokens.allSatisfy { haystack.contains($0) }
    }
}

struct LeadNotificationRecord: Codable, Equatable {
    let id: String
    let leadId: String
    let userId: String
    let userType: String
    let notificationType: String
    let title: String
    let body: String
    var isRead: Bool
    let sentAt: Date
    var metadata: [String: String]?
}

struct ChannelNotification {
    var title: String
    var body: String
    var subject: String?
    var callToAction: String?
    var extras: [String: String]
}

struct RoleNotifications {
    var push: ChannelNotification
    var inApp: ChannelNotification
    var email: ChannelNotification
}

struct ContactAgentWorkflowResult {
    var lead: PlatformLead
    var assignedRealtor: PlatformRealtor?
    var buyerNotifications: RoleNotifications?
    var realtorNotifications: RoleNotifications?
    var workflowStatus: String
    var errors: [String]
    var recommendations: [RealtorRecommendation]
}
