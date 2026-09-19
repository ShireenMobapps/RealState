//
//  NotificationService.swift
//  AIPoweredRealEstate
//
//  Buyer + realtor notifications for Contact Agent leads.
//  Push/email are delivered locally in this app build (in-app + share/mail).
//

import Foundation
import UIKit

final class NotificationService {
    static let shared = NotificationService()

    func generateBuyerNotification(lead: PlatformLead, assignedRealtor: PlatformRealtor) -> RoleNotifications {
        let first = assignedRealtor.name.split(separator: " ").first.map(String.init) ?? assignedRealtor.name
        let hours = assignedRealtor.responseTimeHours
        let pushTitle = "✅ Your request sent to \(first)!"
        let pushBody = "\(assignedRealtor.name) will contact you within \(hours) hours."
        let inAppBody = """
        \(assignedRealtor.name) was assigned because they match this search.

        Expertise: \(assignedRealtor.locationExpertise.joined(separator: ", "))
        Focus: \(assignedRealtor.specialization.joined(separator: ", "))
        Rating: \(String(format: "%.1f", assignedRealtor.rating)) · \(assignedRealtor.totalDeals) deals
        Typical reply: \(hours) hours

        \(assignedRealtor.phone)
        \(assignedRealtor.whatsapp)
        \(assignedRealtor.email)

        Lead ID: \(lead.leadCode)
        """
        let emailBody = """
        Hello \(lead.buyerName),

        Your SpeddyProp inquiry was assigned to \(assignedRealtor.name) (\(assignedRealtor.agency)).
        Rating \(String(format: "%.1f", assignedRealtor.rating))/5 · \(assignedRealtor.totalDeals) deals.
        They typically reply within \(hours) hours via \(lead.preferredContactMethod.displayName).

        Your requirement:
        \(lead.requirements)

        Contact: \(assignedRealtor.phone) · \(assignedRealtor.email)

        Next steps: wait for contact, or message them from the app. Keep this Lead ID for support: \(lead.leadCode).

        SpeddyProp Support · support@speddyprop.com
        """
        return RoleNotifications(
            push: ChannelNotification(title: clipped(pushTitle, 60), body: clipped(pushBody, 120), extras: ["lead_id": lead.leadCode]),
            inApp: ChannelNotification(
                title: "Great Choice! 🎉",
                body: clipped(inAppBody, 1200),
                callToAction: "View \(first)'s Profile",
                extras: ["subtitle": "Your property inquiry has been assigned to a top realtor"]
            ),
            email: ChannelNotification(
                title: "Your Property Inquiry - Assigned to \(assignedRealtor.name)",
                body: clipped(emailBody, 1800),
                subject: "Your Property Inquiry - Assigned to \(assignedRealtor.name)",
                extras: [:]
            )
        )
    }

    func generateRealtorNotification(lead: PlatformLead, buyerInfo: [String: String], realtor: PlatformRealtor) -> RoleNotifications {
        let beds = buyerInfo["bedrooms"] ?? ""
        let type = buyerInfo["property_type"] ?? "property"
        let location = buyerInfo["location"] ?? ""
        let headline = [beds, type, location].filter { !$0.isEmpty }.joined(separator: " ")
        let pushTitle = "🔔 New Lead: \(lead.buyerName) — \(clipped(headline, 28))"
        let budget = budgetText(lead)
        let pushBody = "\(headline.isEmpty ? lead.requirements : headline), \(budget). Contact within \(realtor.responseTimeHours) hours."
        let reason = lead.assignmentMetadata?.assignmentReason ?? "Highest match for this requirement"
        let inAppBody = """
        Lead \(lead.leadCode) · \(lead.createdAt.formatted(date: .abbreviated, time: .shortened))
        Priority: \(priority(for: lead))

        Buyer: \(lead.buyerName)
        \(lead.buyerPhone) · \(lead.buyerEmail)
        Preferred contact: \(lead.preferredContactMethod.displayName)

        \(lead.requirements)
        \(budget)
        Source: \(lead.source.rawValue.replacingOccurrences(of: "_", with: " "))

        Why you: \(reason)
        """
        let emailBody = """
        Hello \(realtor.name),

        A new \(priority(for: lead))-priority lead was assigned to you.

        Lead: \(lead.leadCode)
        Buyer: \(lead.buyerName) · \(lead.buyerPhone) · \(lead.buyerEmail)
        Contact via \(lead.preferredContactMethod.displayName) within \(realtor.responseTimeHours) hours.

        Requirement:
        \(lead.requirements)
        \(budget)

        Workflow:
        1. Review requirements
        2. Contact the buyer
        3. Search inventory with AI
        4. Save 3–5 matches
        5. Compare 2–3 with AI
        6. Generate and send the client report
        7. Update lead status

        SpeddyProp
        """
        return RoleNotifications(
            push: ChannelNotification(title: clipped(pushTitle, 60), body: clipped(pushBody, 120), extras: ["lead_id": lead.leadCode]),
            inApp: ChannelNotification(
                title: "🎯 New Lead Assigned to You",
                body: clipped(inAppBody, 1200),
                extras: [
                    "lead_priority": priority(for: lead),
                    "action_items": realtorActionItems().joined(separator: "\n"),
                    "ai_tools": realtorTools().joined(separator: "\n")
                ]
            ),
            email: ChannelNotification(
                title: "🎯 New High-Priority Lead: \(lead.buyerName)",
                body: clipped(emailBody, 2200),
                subject: "🎯 New High-Priority Lead: \(lead.buyerName) — \(clipped(headline, 40))",
                extras: [:]
            )
        )
    }

    func realtorActionItems() -> [String] {
        [
            "Review buyer requirements and contact information",
            "Contact buyer via WhatsApp within 2 hours",
            "Search properties using AI conversational search",
            "Save 3–5 matching properties to favorites",
            "Compare 2–3 properties using AI comparator",
            "Generate property comparison report with AI",
            "Send report to buyer and schedule viewings",
            "Update lead status after contact"
        ]
    }

    func realtorTools() -> [String] {
        [
            "AI Conversational Property Search",
            "Property Comparator — Compare 2–3 properties",
            "AI Marketing Content Generator — WhatsApp/Email",
            "Cross-inventory Property Search"
        ]
    }

    @discardableResult
    func sendPushNotification(userId: String, title: String, body: String, data: [String: String]) -> Bool {
        NSLog("[SpeddyProp] push to %@: %@ — %@ %@", userId, title, body, data)
        return true
    }

    @discardableResult
    func sendEmail(to: String, subject: String, body: String, html: Bool = true) -> Bool {
        NSLog("[SpeddyProp] email to %@: %@", to, subject)
        _ = html
        return !to.isEmpty
    }

    @discardableResult
    func saveInAppNotification(
        userId: String,
        leadId: String,
        userType: String,
        notificationType: String,
        title: String,
        body: String,
        metadata: [String: String]? = nil
    ) -> LeadNotificationRecord {
        let record = LeadNotificationRecord(
            id: UUID().uuidString,
            leadId: leadId,
            userId: userId,
            userType: userType,
            notificationType: notificationType,
            title: title,
            body: body,
            isRead: false,
            sentAt: Date(),
            metadata: metadata
        )
        RealtorDesk.shared.saveNotification(record)
        return record
    }

    func deliver(buyer: RoleNotifications, realtor: RoleNotifications, lead: PlatformLead, assigned: PlatformRealtor) {
        sendPushNotification(userId: lead.buyerId, title: buyer.push.title, body: buyer.push.body, data: ["lead_id": lead.leadCode, "notification_type": "buyer_assignment"])
        sendPushNotification(userId: assigned.id, title: realtor.push.title, body: realtor.push.body, data: ["lead_id": lead.leadCode, "notification_type": "realtor_lead"])
        sendEmail(to: lead.buyerEmail, subject: buyer.email.subject ?? buyer.email.title, body: buyer.email.body)
        sendEmail(to: assigned.email, subject: realtor.email.subject ?? realtor.email.title, body: realtor.email.body)
        saveInAppNotification(userId: lead.buyerId, leadId: lead.id, userType: "buyer", notificationType: "in_app", title: buyer.inApp.title, body: buyer.inApp.body, metadata: buyer.inApp.extras)
        saveInAppNotification(userId: assigned.id, leadId: lead.id, userType: "realtor", notificationType: "in_app", title: realtor.inApp.title, body: realtor.inApp.body, metadata: realtor.inApp.extras)
        saveInAppNotification(userId: lead.buyerId, leadId: lead.id, userType: "buyer", notificationType: "push", title: buyer.push.title, body: buyer.push.body, metadata: buyer.push.extras)
        saveInAppNotification(userId: assigned.id, leadId: lead.id, userType: "realtor", notificationType: "push", title: realtor.push.title, body: realtor.push.body, metadata: realtor.push.extras)
    }

    func notifyLeadStatusChange(lead: PlatformLead, previous: LeadStatus) {
        guard lead.status != previous else { return }
        let realtor = RealtorDesk.shared.realtor(id: lead.assignedRealtorId)
        let realtorName = realtor?.name ?? "Your realtor".localized
        let payload: (title: String, body: String, type: String)?
        switch lead.status {
        case .assigned:
            payload = (
                "Lead assigned".localized,
                "%@ was assigned to lead %@.".localized(realtorName, lead.leadCode),
                "lead_assigned"
            )
        case .contacted:
            payload = (
                "Realtor contacted you".localized,
                "%@ contacted you about %@.".localized(realtorName, lead.leadCode),
                "realtor_contacted"
            )
        case .viewing:
            payload = (
                "Viewing scheduled".localized,
                "A property viewing was scheduled for %@.".localized(lead.leadCode),
                "viewing_scheduled"
            )
        case .closed:
            payload = (
                "Lead closed".localized,
                "%@ was marked closed.".localized(lead.leadCode),
                "lead_closed"
            )
        case .lost:
            payload = (
                "Lead lost".localized,
                "%@ was marked lost.".localized(lead.leadCode),
                "lead_lost"
            )
        case .new:
            payload = nil
        }
        guard let payload else { return }
        sendPushNotification(
            userId: lead.buyerId,
            title: payload.title,
            body: payload.body,
            data: ["lead_id": lead.leadCode, "notification_type": payload.type]
        )
        saveInAppNotification(
            userId: lead.buyerId,
            leadId: lead.id,
            userType: "buyer",
            notificationType: payload.type,
            title: payload.title,
            body: payload.body,
            metadata: ["lead_code": lead.leadCode, "status": lead.status.rawValue]
        )
        if let realtor, lead.status == .contacted || lead.status == .viewing || lead.status == .closed || lead.status == .lost {
            saveInAppNotification(
                userId: realtor.id,
                leadId: lead.id,
                userType: "realtor",
                notificationType: payload.type,
                title: payload.title,
                body: payload.body,
                metadata: ["lead_code": lead.leadCode, "status": lead.status.rawValue]
            )
        }
    }

    private func priority(for lead: PlatformLead) -> String {
        let score = lead.assignmentMetadata?.matchScore ?? 0
        if score >= 90 { return "high" }
        if score >= 80 { return "medium" }
        return "low"
    }

    private func budgetText(_ lead: PlatformLead) -> String {
        if let min = lead.budgetMin, let max = lead.budgetMax {
            return "Budget $\(Int(min))–$\(Int(max))"
        }
        if let max = lead.budgetMax { return "Budget up to $\(Int(max))" }
        return "Budget not specified"
    }

    private func clipped(_ text: String, _ max: Int) -> String {
        guard text.count > max else { return text }
        return String(text.prefix(max - 1)) + "…"
    }
}
