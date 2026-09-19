//
//  AgentViewModels.swift
//  AIPoweredRealEstate
//
//  Created by Shireen on 18/08/26.
//

import Foundation

class AgentViewModels {

    class func registerAPI(param: [String: Any]) async throws -> AgentRegistrationResponse {
        /*
         name:Fatima
         email:f@gmail.com
         password:123456
         phone:1234567890
         agencyName:ABC
         licenseNumber:23123
         */
        try await AuthViewModel.registerAgentAPI(param: param)
    }

    class func loginAPI(param: [String: Any]) async throws -> LoginResponse {
        try await AuthViewModel.loginAPI(param: param)
    }

    class func profileAPI() async throws -> User {
        try await TenantViewModels.profileAPI()
    }

    class func filterOptionsAPI() async throws -> FilterOptionsData {
        try await TenantViewModels.filterOptionsAPI()
    }

    class func searchPropertiesAPI(_ request: PropertyFilterRequest) async throws -> [PropertyItem] {
        try await TenantViewModels.searchPropertiesAPI(request)
    }

    class func searchPropertiesPageAPI(_ request: PropertyFilterRequest) async throws -> PropertySearchPage {
        try await TenantViewModels.searchPropertiesPageAPI(request)
    }

    class func comparePropertiesAPI(ids: [String]) async throws -> [PropertyItem] {
        try await TenantViewModels.comparePropertiesAPI(ids: ids)
    }

    class func propertyDetailsAPI(id: String) async throws -> PropertyItem {
        try await TenantViewModels.propertyDetailsAPI(id: id)
    }

    class func favoritesAPI() async throws -> [PropertyItem] {
        try await TenantViewModels.favoritesAPI()
    }

    class func toggleFavoriteAPI(propertyId: String) async throws -> Bool {
        try await TenantViewModels.toggleFavoriteAPI(propertyId: propertyId)
    }

    class func myLeadsAPI(syncBuyerStore: Bool = false) async throws -> [PlatformLead] {
        try await TenantViewModels.myLeadsAPI(syncBuyerStore: syncBuyerStore)
    }

    class func notificationsAPI(page: Int = 1, limit: Int = 10) async throws -> GetNotificationsResponseModel {
        print("NOTIFICATIONS GET: \(Constant.notificationsURL) page=\(page) limit=\(limit)")
        return try await AuthViewModel.notificationsAPI(page: page, limit: limit)
    }

    class func newNotificationsAPI() async throws -> NewNotificationsResponseModel {
        try await AuthViewModel.notificationCountAPI()
    }

    class func deleteNotificationAPI(id: String) async throws -> DeleteNotificationResponseModel {
        try await AuthViewModel.deleteNotificationAPI(id: id)
    }

    class func updateLeadStatusAPI(id: String, status: String) async throws {
        let param = ["status": apiLeadStatus(status)]
        let url = Constant.agentLeadStatusURL(id: id)
        print("AGENT LEAD STATUS PUT: \(url) param=\(param)")
        let _: APIStatusResponse = try await ServiceHandler.genericAPI(
            url: url,
            method: .put,
            isMutable: false,
            param: param
        )
    }

    private class func apiLeadStatus(_ status: String) -> String {
        switch status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "contacted": return "approved"
        case "qualified": return "completed"
        default: return status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
    }

    class func agentLeadsAPI(status: String? = nil, page: Int = 1, limit: Int = 10) async throws -> [PlatformLead] {
        var param: [String: Any] = [
            "page": page,
            "limit": limit
        ]
        if let status, status.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            param["status"] = status
        }
        print("AGENT LEADS GET: \(Constant.agentLeadsURL) param=\(param)")
        let response: MyLeadsResponse = try await ServiceHandler.genericAPI(
            url: Constant.agentLeadsURL,
            method: .get,
            isMutable: false,
            param: param
        )
        return response.leads.map { $0.asPlatformLead(useLocalAccount: false) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    class func marketingContentAPI(propertyId: String, contentType: String) async throws -> MarketingContentResponse {
        let param: [String: Any] = [
            "contentType": contentType
        ]
        print("MARKETING CONTENT POST: \(Constant.marketingContentURL(id: propertyId)) param=\(param)")
        var response: MarketingContentResponse = try await ServiceHandler.genericAPI(
            url: Constant.marketingContentURL(id: propertyId),
            method: .post,
            isMutable: false,
            param: param
        )
        response.requestedContentType = contentType
        return response
    }

    class func recentlyAISearchAPI() async throws -> [AISearchHistoryItem] {
        print("RECENTLY AI SEARCH GET: \(Constant.recentlyAISearchURL)")
        let response: RecentlyAISearchResponse = try await ServiceHandler.genericAPI(
            url: Constant.recentlyAISearchURL,
            method: .get,
            isMutable: false,
            param: [:]
        )
        return response.history.compactMap { record in
            guard record.id.isEmpty == false, record.query.isEmpty == false else { return nil }
            return AISearchHistoryItem(historyId: record.id, query: record.query)
        }
    }

    class func deleteAISearchHistoryAPI(id: String) async throws {
        print("AI SEARCH HISTORY DELETE: \(Constant.aiSearchHistoryURL(id: id))")
        let _: APIStatusResponse = try await ServiceHandler.genericAPI(
            url: Constant.aiSearchHistoryURL(id: id),
            method: .delete,
            isMutable: false,
            param: [:]
        )
    }

    class func deleteAllAISearchHistoryAPI() async throws {
        print("AI SEARCH HISTORY DELETE ALL: \(Constant.aiSearchHistoryURL)")
        let _: APIStatusResponse = try await ServiceHandler.genericAPI(
            url: Constant.aiSearchHistoryURL,
            method: .delete,
            isMutable: false,
            param: [:]
        )
    }
}
