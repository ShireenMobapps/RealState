//
//  LeadWorkflowService.swift
//  AIPoweredRealEstate
//
//  Contact Agent: create lead → assign realtor → notify both sides.
//

import Foundation

final class LeadWorkflowService {
    static let shared = LeadWorkflowService()

    func processContactAgentFlow(
        _ request: LeadCreateRequest,
        assignmentMode: AssignmentMode = .autoAssign,
        selectedRealtorId: String? = nil
    ) -> ContactAgentWorkflowResult {
        var lead = RealtorDesk.shared.createLead(from: request)
        var errors: [String] = []
        let requirements = LeadRequirements.from(
            property: request.propertyId.flatMap { id in PropertyStore.shared.all.first { $0.id == id } },
            text: request.requirements,
            budgetMax: request.budgetMax,
            language: request.preferredLanguage
        )

        let assignment: AssignmentResult
        if let selectedRealtorId, let chosen = RealtorDesk.shared.realtor(id: selectedRealtorId) {
            let score = RealtorMatchingService.shared.calculateMatchScore(realtor: chosen, leadRequirements: requirements)
            assignment = AssignmentResult(
                assignedRealtor: chosen,
                realtorRecommendations: [RealtorRecommendation(realtor: chosen, score: score)],
                metadata: AssignmentMetadata(
                    totalRealtorsEvaluated: RealtorDesk.shared.availableRealtors().count,
                    realtorsAboveThreshold: score.isQualified ? 1 : 0,
                    thresholdScore: RealtorMatchingService.thresholdScore,
                    matchingCriteriaUsed: ["buyer_choice"],
                    recommendationConfidence: score.totalScore >= 90 ? "high" : (score.totalScore >= 80 ? "medium" : "low"),
                    assignmentTimestamp: Date(),
                    assignmentMode: AssignmentMode.buyerChoice.rawValue,
                    matchScore: score.totalScore,
                    assignmentReason: RealtorRecommendation(realtor: chosen, score: score).assignmentReason
                )
            )
        } else {
            assignment = RealtorMatchingService.shared.findBestRealtors(
                leadRequirements: requirements,
                availableRealtors: RealtorDesk.shared.roster,
                assignmentMode: assignmentMode
            )
        }

        var assigned = assignment.assignedRealtor
        if assigned == nil, assignmentMode == .autoAssign {
            assigned = assignment.realtorRecommendations.first?.realtor
            if assigned == nil { errors.append("No realtor met the assignment threshold.") }
        }

        if let assigned {
            RealtorDesk.shared.assign(leadId: lead.id, realtorId: assigned.id, metadata: assignment.metadata)
            let assistance = RealtorDesk.shared.submitAssistanceRequest(
                requirement: ClientRequirement.from(query: request.requirements),
                realtorId: assigned.id
            )
            RealtorDesk.shared.linkLead(lead.id, assistanceRequestId: assistance.id)
        }

        lead = RealtorDesk.shared.lead(id: lead.id) ?? lead
        assigned = assigned.flatMap { RealtorDesk.shared.realtor(id: $0.id) } ?? assigned

        var buyerNotes: RoleNotifications?
        var realtorNotes: RoleNotifications?
        if let assigned {
            let property = request.propertyId.flatMap { id in PropertyStore.shared.all.first { $0.id == id } }
            buyerNotes = NotificationService.shared.generateBuyerNotification(lead: lead, assignedRealtor: assigned)
            realtorNotes = NotificationService.shared.generateRealtorNotification(
                lead: lead,
                buyerInfo: [
                    "name": lead.buyerName,
                    "location": requirements.location ?? property?.location ?? "",
                    "property_type": requirements.propertyType ?? property?.propertyType ?? "",
                    "bedrooms": property.map { "\($0.bedrooms)BR" } ?? ""
                ],
                realtor: assigned
            )
            NotificationService.shared.deliver(buyer: buyerNotes!, realtor: realtorNotes!, lead: lead, assigned: assigned)
            if let property {
                PropertyStore.shared.addEnquiry(
                    property: property,
                    name: lead.buyerName,
                    email: lead.buyerEmail,
                    phone: lead.buyerPhone,
                    message: lead.requirements,
                    kind: .propertyEnquiry,
                    requestId: lead.assistanceRequestId
                )
            }
        }

        let status: String
        if assigned != nil && errors.isEmpty { status = "success" }
        else if assigned != nil { status = "partial" }
        else { status = "failed" }

        return ContactAgentWorkflowResult(
            lead: lead,
            assignedRealtor: assigned,
            buyerNotifications: buyerNotes,
            realtorNotifications: realtorNotes,
            workflowStatus: status,
            errors: errors,
            recommendations: assignment.realtorRecommendations
        )
    }

    func recommendations(for requirement: ClientRequirement) -> [RealtorRecommendation] {
        RealtorMatchingService.shared.findBestRealtors(
            leadRequirements: .from(requirement: requirement, language: TenantAccount.shared.language),
            availableRealtors: RealtorDesk.shared.roster,
            assignmentMode: .buyerChoice
        ).realtorRecommendations
    }
}
