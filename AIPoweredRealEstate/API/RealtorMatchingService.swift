//
//  RealtorMatchingService.swift
//  AIPoweredRealEstate
//
//  Weighted realtor assignment: location 40, type 25, budget 15,
//  language 10, performance 5, response time 5.
//

import Foundation

final class RealtorMatchingService {
    static let shared = RealtorMatchingService()
    static let thresholdScore = 70

    private static let nearbyZones: [String: [String]] = [
        "Naco": ["Piantini", "Bella Vista", "Santo Domingo"],
        "Piantini": ["Naco", "Bella Vista", "Santo Domingo"],
        "Bella Vista": ["Naco", "Piantini", "Santo Domingo"],
        "Santo Domingo": ["Naco", "Piantini", "Bella Vista"],
        "Punta Cana": ["Cap Cana"],
        "Cap Cana": ["Punta Cana"],
        "Puerto Plata": ["Santiago"],
        "Santiago": ["Puerto Plata", "Santo Domingo"]
    ]

    private static let relatedTypes: [String: [String]] = [
        "Apartment": ["Condo"],
        "Condo": ["Apartment"],
        "House": ["Villa"],
        "Villa": ["House"]
    ]

    private static let knownZones = [
        "Naco", "Piantini", "Bella Vista", "Punta Cana", "Santo Domingo",
        "Santiago", "Puerto Plata", "Cap Cana"
    ]

    func calculateMatchScore(realtor: PlatformRealtor, leadRequirements: LeadRequirements) -> MatchScoreBreakdown {
        var breakdown: [String: String] = [:]

        let locationScore = locationPoints(realtor: realtor, requirements: leadRequirements, breakdown: &breakdown)
        let propertyTypeScore = propertyTypePoints(realtor: realtor, requirements: leadRequirements, breakdown: &breakdown)
        let budgetScore = budgetPoints(realtor: realtor, requirements: leadRequirements, breakdown: &breakdown)
        let languageScore = languagePoints(realtor: realtor, requirements: leadRequirements, breakdown: &breakdown)
        let performanceScore = min(5, max(0, (realtor.rating / 5.0) * 5.0))
        breakdown["performance"] = String(format: "Rating %.1f/5", realtor.rating)
        let hours = max(1, realtor.responseTimeHours)
        let responseTimeScore = min(5.0, (24.0 / Double(hours)) * 5.0)
        breakdown["response_time"] = "Responds in \(realtor.responseTimeHours)h"

        let total = locationScore + propertyTypeScore + budgetScore + languageScore + performanceScore + responseTimeScore
        return MatchScoreBreakdown(
            totalScore: min(100, (total * 10).rounded() / 10),
            locationScore: locationScore,
            propertyTypeScore: propertyTypeScore,
            budgetScore: budgetScore,
            languageScore: languageScore,
            performanceScore: (performanceScore * 10).rounded() / 10,
            responseTimeScore: (responseTimeScore * 10).rounded() / 10,
            breakdown: breakdown
        )
    }

    func findBestRealtors(
        leadRequirements: LeadRequirements,
        availableRealtors: [PlatformRealtor],
        assignmentMode: AssignmentMode
    ) -> AssignmentResult {
        let active = availableRealtors.filter { $0.isVerified && $0.isAvailable && $0.availabilityStatus == "active" }
        let scored = active
            .map { RealtorRecommendation(realtor: $0, score: calculateMatchScore(realtor: $0, leadRequirements: leadRequirements)) }
            .sorted { lhs, rhs in
                if lhs.score.totalScore != rhs.score.totalScore {
                    return lhs.score.totalScore > rhs.score.totalScore
                }
                return lhs.realtor.totalLeadsAssigned < rhs.realtor.totalLeadsAssigned
            }
        let qualified = scored.filter(\.score.isQualified)
        let pool = qualified.isEmpty ? Array(scored.prefix(3)) : qualified

        var assigned: PlatformRealtor?
        var recommendations: [RealtorRecommendation] = []
        switch assignmentMode {
        case .autoAssign:
            assigned = pool.first?.realtor
            recommendations = Array(pool.prefix(1))
        case .buyerChoice:
            recommendations = Array(pool.prefix(3))
        case .roundRobin:
            recommendations = pool
            assigned = pool.min { lhs, rhs in
                if lhs.realtor.totalLeadsAssigned != rhs.realtor.totalLeadsAssigned {
                    return lhs.realtor.totalLeadsAssigned < rhs.realtor.totalLeadsAssigned
                }
                return lhs.realtor.openRequestCount < rhs.realtor.openRequestCount
            }?.realtor
        }

        let top = assigned.flatMap { realtor in scored.first { $0.realtor.id == realtor.id } } ?? recommendations.first
        let confidence: String
        let topScore = top?.score.totalScore ?? 0
        if topScore >= 90 { confidence = "high" }
        else if topScore >= 80 { confidence = "medium" }
        else { confidence = "low" }

        var criteria: [String] = []
        if leadRequirements.location != nil || !leadRequirements.zones.isEmpty { criteria.append("location") }
        if leadRequirements.propertyType != nil { criteria.append("property_type") }
        if leadRequirements.budgetMax != nil || leadRequirements.budgetMin != nil { criteria.append("budget") }
        if leadRequirements.preferredLanguage != nil { criteria.append("language") }
        criteria.append(contentsOf: ["performance", "response_time"])

        return AssignmentResult(
            assignedRealtor: assigned,
            realtorRecommendations: recommendations,
            metadata: AssignmentMetadata(
                totalRealtorsEvaluated: active.count,
                realtorsAboveThreshold: qualified.count,
                thresholdScore: Self.thresholdScore,
                matchingCriteriaUsed: criteria,
                recommendationConfidence: confidence,
                assignmentTimestamp: Date(),
                assignmentMode: assignmentMode.rawValue,
                matchScore: top?.score.totalScore,
                assignmentReason: top?.assignmentReason
            )
        )
    }

    func generateAIAssignmentPrompt(leadData: [String: String], realtors: [[String: String]]) -> String {
        """
        You are the SpeddyProp assignment engine for the Dominican Republic real estate market.
        The platform aggregates listings from SuperCasas, Corotos, and other portals.
        A lead is created when a buyer taps Contact Agent. Assign the best verified realtor.

        Lead:
        \(leadData.map { "\($0.key): \($0.value)" }.sorted().joined(separator: "\n"))

        Realtors:
        \(realtors.enumerated().map { index, realtor in
            "\(index + 1). " + realtor.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: ", ")
        }.joined(separator: "\n"))

        Weighted criteria (100 points):
        - Location/Zone expertise: 40
        - Property type specialization: 25
        - Budget range: 15
        - Language: 10
        - Performance (rating): 5
        - Response time: 5

        Rules:
        - Only recommend realtors with score >= 70.
        - Sort by match_score descending.
        - Include a specific assignment reason and lead_id in notifications.

        Return JSON with:
        {
          "lead_assignment": { "assigned_realtor_id", "match_score", "reason" },
          "notifications": { "buyer": { "title", "body" }, "realtor": { "title", "body" } },
          "next_steps": { "buyer": [], "realtor": [] },
          "analytics": { "total_evaluated", "above_threshold", "confidence" }
        }
        """
    }

    func processAIAssignment(leadData: LeadRequirements, realtors: [PlatformRealtor], mode: AssignmentMode) -> AssignmentResult {
        findBestRealtors(leadRequirements: leadData, availableRealtors: realtors, assignmentMode: mode)
    }

    static func zones(in text: String) -> [String] {
        let lower = text.lowercased()
        return knownZones.filter { zone in
            lower.contains(zone.lowercased())
        }
    }

    private func locationPoints(realtor: PlatformRealtor, requirements: LeadRequirements, breakdown: inout [String: String]) -> Double {
        let expertise = realtor.locationExpertise.isEmpty ? realtor.serviceAreas : realtor.locationExpertise
        let targets = requirements.zones.isEmpty ? [requirements.location].compactMap { $0 } : requirements.zones
        guard !targets.isEmpty else {
            breakdown["location"] = "No location on the lead"
            return 0
        }
        if targets.contains(where: { target in expertise.contains { $0.caseInsensitiveCompare(target) == .orderedSame } }) {
            breakdown["location"] = "Expert in \(targets.joined(separator: ", "))"
            return 40
        }
        let nearbyHit = targets.contains { target in
            let nearby = Self.nearbyZones.first { $0.key.caseInsensitiveCompare(target) == .orderedSame }?.value ?? []
            return expertise.contains { area in nearby.contains { $0.caseInsensitiveCompare(area) == .orderedSame } }
        }
        if nearbyHit {
            breakdown["location"] = "Nearby area expertise"
            return 20
        }
        breakdown["location"] = "Outside primary zones"
        return 0
    }

    private func propertyTypePoints(realtor: PlatformRealtor, requirements: LeadRequirements, breakdown: inout [String: String]) -> Double {
        guard let type = requirements.propertyType, !type.isEmpty else {
            breakdown["property_type"] = "No property type on the lead"
            return 0
        }
        if realtor.specialization.contains(where: { $0.caseInsensitiveCompare(type) == .orderedSame }) {
            breakdown["property_type"] = "Specialist in \(type)"
            return 25
        }
        let related = Self.relatedTypes.first { $0.key.caseInsensitiveCompare(type) == .orderedSame }?.value ?? []
        if realtor.specialization.contains(where: { spec in related.contains { $0.caseInsensitiveCompare(spec) == .orderedSame } }) {
            breakdown["property_type"] = "Related type experience"
            return 15
        }
        breakdown["property_type"] = "Different property focus"
        return 0
    }

    private func budgetPoints(realtor: PlatformRealtor, requirements: LeadRequirements, breakdown: inout [String: String]) -> Double {
        guard let budget = requirements.budgetMax ?? requirements.budgetMin else {
            breakdown["budget"] = "No budget on the lead"
            return 0
        }
        let min = realtor.typicalBudgetMin ?? 0
        let max = realtor.typicalBudgetMax ?? budget * 4
        if budget >= min && budget <= max {
            breakdown["budget"] = "Within typical deal range"
            return 15
        }
        let paddedMin = min * 0.8
        let paddedMax = max * 1.2
        if budget >= paddedMin && budget <= paddedMax {
            breakdown["budget"] = "Close to typical deal range"
            return 10
        }
        breakdown["budget"] = "Outside typical deal range"
        return 0
    }

    private func languagePoints(realtor: PlatformRealtor, requirements: LeadRequirements, breakdown: inout [String: String]) -> Double {
        let preferred = normalizedLanguage(requirements.preferredLanguage)
        if let preferred, realtor.languages.contains(where: { normalizedLanguage($0) == preferred }) {
            breakdown["language"] = "Speaks \(preferred)"
            return 10
        }
        if realtor.languages.count >= 2 {
            breakdown["language"] = "Multilingual"
            return 5
        }
        breakdown["language"] = "Language not listed"
        return 0
    }

    private func normalizedLanguage(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        let lower = value.lowercased()
        if lower.contains("span") || lower == "es" || lower == "español" { return "Spanish" }
        if lower.contains("eng") || lower == "en" { return "English" }
        return value
    }
}
