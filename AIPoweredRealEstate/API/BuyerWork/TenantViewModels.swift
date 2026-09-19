//
//  TenantViewModels.swift
//  AIPoweredRealEstate
//
//  Created by Shireen on 18/08/26.
//

import Foundation
import UIKit

class TenantViewModels{
    
    class func registerAPI(
         param: [String: Any]
    )
    
    async throws -> RegisterResponseModel {
      
        let response: RegisterResponseModel = try await ServiceHandler.genericAPI(
            url: Constant.buyerRegisterURL,
            method: .post,
            isMutable: false,
            param: param
        )
        return response
        
    }
    
    class func loginAPI(
        param: [String: Any]
    )
   
    async throws -> LoginResponse {
        print("LOGIN API CALL: \(Constant.loginURL)")
        NSLog("LOGIN API CALL: %@", Constant.loginURL)
        let response: LoginResponse = try await ServiceHandler.genericAPI(
            url: Constant.loginURL,
            method: .post,
            isMutable: false,
            param: param
        )
        return response
     }
    
    class func profileAPI() async throws -> User {
        if Constant.useRemoteAPI == false {
            let role = KeyChainManager.shared.getValue(key: "UserRole") ?? "buyer"
            return localUser(from: ["role": role])
        }
        let response: User = try await ServiceHandler.genericAPI(
            url: Constant.profileURL,
            method: .get,
            isMutable: false
        )
       return response
    }

    private class func localUser(from param: [String: Any]) -> User {
        let role = (param["role"] as? String)
            ?? KeyChainManager.shared.getValue(key: "UserRole")
            ?? "buyer"
        if role == "agent" {
            return User(
                id: "local-agent",
                name: (param["name"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? AgentAccount.shared.name,
                email: (param["email"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? AgentAccount.shared.email,
                phone: (param["phone"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? AgentAccount.shared.phone,
                role: "agent",
                status: param["status"] as? String,
                agencyName: param["agencyName"] as? String,
                licenseNumber: param["licenseNumber"] as? String,
                document: param["document"] as? String,
                profileImage: nil,
                createdAt: nil
            )
        }
        return User(
            id: "local-buyer",
            name: (param["name"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? TenantAccount.shared.name,
            email: (param["email"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? TenantAccount.shared.email,
            phone: (param["phone"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? TenantAccount.shared.phone,
            role: "buyer",
            status: param["status"] as? String,
            agencyName: param["agencyName"] as? String,
            licenseNumber: param["licenseNumber"] as? String,
            document: param["document"] as? String,
            profileImage: nil,
            createdAt: nil
        )
    }

    class func filterOptionsAPI() async throws -> FilterOptionsData {
        print("FILTER OPTIONS GET: \(Constant.filterOptionsURL)")
        let response: FilterOptionsModel = try await ServiceHandler.genericAPI(
            url: Constant.filterOptionsURL,
            method: .get,
            isMutable: false,
            param: [:]
        )
        return response.data ?? FilterOptionsData(
            language: nil,
            listingTypes: [],
            propertyTypes: [],
            furnishedStatuses: [],
            amenities: []
        )
    }

    class func searchPropertiesAPI(_ request: PropertyFilterRequest) async throws -> [PropertyItem] {
        try await searchPropertiesPageAPI(request).items
    }

    class func searchPropertiesPageAPI(_ request: PropertyFilterRequest) async throws -> PropertySearchPage {
        let param = request.asParameters()
        print("PROPERTY FILTER POST: \(Constant.propertySearchURL) param=\(param)")
        let response: PropertySearchResponse = try await ServiceHandler.genericAPI(
            url: Constant.propertySearchURL,
            method: .post,
            isMutable: false,
            param: param
        )
        
        print(response)
        return mappedPropertyPage(response, request: request)
    }

    private class func mappedProperties(_ response: PropertySearchResponse) -> [PropertyItem] {
        response.data?.properties?.map { $0.asPropertyItem() } ?? []
    }

    private class func mappedPropertyPage(
        _ response: PropertySearchResponse,
        request: PropertyFilterRequest
    ) -> PropertySearchPage {
        let items = mappedProperties(response)
        let page = response.data?.page ?? request.page ?? 1
        let limit = response.data?.limit ?? request.limit ?? max(items.count, 1)
        let total = response.data?.total ?? response.data?.count
        let hasMore: Bool
        if let flag = response.data?.hasMore {
            hasMore = flag
        } else if let totalPages = response.data?.totalPages {
            hasMore = page < totalPages
        } else if let total {
            hasMore = page * limit < total
        } else {
            hasMore = request.limit.map { items.count >= $0 } ?? false
        }
        return PropertySearchPage(items: items, page: page, limit: limit, total: total, hasMore: hasMore)
    }

    class func comparePropertiesAPI(ids: [String]) async throws -> [PropertyItem] {
        let propertyIds = ids.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        // Backend reads `propertyIds`; docs sometimes use typo `properyIds` — send both.
        let param: [String: Any] = [
            "propertyIds": propertyIds,
            "properyIds": propertyIds
        ]
        print("PROPERTY COMPARE POST: \(Constant.propertyCompareURL) param=\(param)")
        let response: PropertyCompareResponse = try await ServiceHandler.genericAPI(
            url: Constant.propertyCompareURL,
            method: .post,
            isMutable: false,
            param: param
        )
        let mapped = response.properties.map { $0.asPropertyItem() }
        let byID = Dictionary(mapped.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let ordered = propertyIds.compactMap { byID[$0] }
        return ordered.isEmpty ? mapped : ordered
    }

    class func propertyDetailsAPI(id: String) async throws -> PropertyItem {
        let url = Constant.propertyDetailsURL(id: id)
        print("PROPERTY DETAILS GET: \(url)")
        let response: PropertyDetailsResponse = try await ServiceHandler.genericAPI(
            url: url,
            method: .get,
            isMutable: false,
            param: [:]
        )
        guard let property = response.data?.property else {
            throw URLError(.badServerResponse)
        }
        return property.asPropertyItem()
    }

    class func recentlyViewedAPI() async throws -> [PropertyItem] {
        print("RECENTLY VIEWED GET: \(Constant.recentlyViewedURL)")
        let response: RecentlyViewedResponse = try await ServiceHandler.genericAPI(
            url: Constant.recentlyViewedURL,
            method: .get,
            isMutable: false,
            param: [:]
        )
        return response.viewedItems
    }

    class func deleteRecentlyViewedAPI(id: String) async throws {
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            print("RECENTLY VIEWED DELETE: \(Constant.recentlyViewedURL(id: trimmed))")
            let _: APIStatusResponse = try await ServiceHandler.genericAPI(
                url: Constant.recentlyViewedURL(id: trimmed),
                method: .delete,
                isMutable: false,
                param: [:]
            )
        } catch {
            let message = ((error as? APIError)?.errorDescription ?? error.localizedDescription)
            let missingRoute = message.contains("Cannot DELETE") || message.contains("Request failed (404)")
            guard missingRoute else { throw error }
            try await removeRecentlyViewedByRebuild(id: trimmed)
        }
    }

    private class func removeRecentlyViewedByRebuild(id: String) async throws {
        let items = try await recentlyViewedAPI()
        let remaining = items.filter { item in
            item.id != id && item.recentlyViewedId != id
        }
        try await clearRecentlyViewedAPI()
        for item in remaining.reversed() {
            _ = try? await propertyDetailsAPI(id: item.id)
        }
    }

    class func clearRecentlyViewedAPI() async throws {
        print("RECENTLY VIEWED DELETE: \(Constant.recentlyViewedURL)")
        let _: APIStatusResponse = try await ServiceHandler.genericAPI(
            url: Constant.recentlyViewedURL,
            method: .delete,
            isMutable: false,
            param: [:]
        )
    }

    class func favoritesAPI() async throws -> [PropertyItem] {
        print("FAVORITES GET: \(Constant.favoritesURL)")
        let response: RecentlyViewedResponse = try await ServiceHandler.genericAPI(
            url: Constant.favoritesURL,
            method: .get,
            isMutable: false,
            param: [:]
        )
        return response.properties.map { item in
            var property = item.asPropertyItem()
            property.isFav = true
            return property
        }
    }

    class func toggleFavoriteAPI(propertyId: String) async throws -> Bool {
        print("FAVORITE TOGGLE POST: \(Constant.favoritesToggleURL) propertyId=\(propertyId)")
        let response: FavoriteToggleResponse = try await ServiceHandler.genericAPI(
            url: Constant.favoritesToggleURL,
            method: .post,
            isMutable: false,
            param: ["propertyId": propertyId]
        )
        if let isFav = response.isFav {
            return isFav
        }
        // Fallback: if API omits flag, invert local state.
        return !PropertyStore.shared.isFavorite(propertyId)
    }

    class func agentsAPI() async throws -> [PlatformRealtor] {
        print("AGENTS GET: \(Constant.agentsURL)")
        let response: AgentsListResponse = try await ServiceHandler.genericAPI(
            url: Constant.agentsURL,
            method: .get,
            isMutable: false,
            param: [:]
        )
        let agents = response.agents
            .filter { !$0.id.isEmpty || !$0.name.isEmpty }
            .map { $0.asPlatformRealtor() }
        RealtorDesk.shared.replaceRoster(with: agents)
        return agents
    }

    class func sendLeadAPI(
        agentId: String,
        name: String,
        email: String,
        phone: String,
        description: String
    ) async throws -> APIStatusResponse {
        let param: [String: Any] = [
            "agent": agentId,
            "name": name,
            "email": email,
            "phone": phone,
            "description": description
        ]
        print("SEND LEAD POST: \(Constant.sendLeadURL) param=\(param)")
        return try await ServiceHandler.genericAPI(
            url: Constant.sendLeadURL,
            method: .post,
            isMutable: false,
            param: param
        )
    }

    class func chatAPI(
        message: String,
        filters: AIExtractedFilters? = nil,
        savedSearchId: String? = nil,
        chatId: String? = nil
    ) async throws -> AIChatData {
        var param: [String: Any] = [
            "message": message
        ]
        if let savedSearchId, savedSearchId.isEmpty == false {
            param["savedSearchId"] = savedSearchId
        }
        if let chatId, chatId.isEmpty == false {
            param["chatId"] = chatId
        }
        if let extracted = filters?.asRequestBody(), extracted.isEmpty == false {
            param["extractedFilters"] = extracted
        }
        print("AI CHAT POST: \(Constant.chatURL) param=\(param)")
        let response: AIChatResponseModel = try await ServiceHandler.genericAPI(
            url: Constant.chatURL,
            method: .post,
            isMutable: false,
            param: param
        )
        return AIChatData.merged(from: response, userMessage: message)
    }

    class func savedSearchAPI(message: String, chatId: String? = nil) async throws {
        var param: [String: Any] = ["message": message]
        if let chatId, chatId.isEmpty == false {
            param["chatId"] = chatId
        }
        print("========== SAVED SEARCH REQUEST ==========")
        print("URL: \(Constant.savedSearchURL)")
        print("METHOD: POST")
        print("PARAMETERS: \(param)")
        print("==========================================")
        NSLog("SAVED SEARCH URL: %@", Constant.savedSearchURL)
        NSLog("SAVED SEARCH PARAM: %@", String(describing: param))
        do {
            let response: APIStatusResponse = try await ServiceHandler.genericAPI(
                url: Constant.savedSearchURL,
                method: .post,
                isMutable: false,
                param: param
            )
            print("========== SAVED SEARCH RESPONSE ==========")
            print("success: \(response.success as Any)")
            print("message: \(response.message as Any)")
            print("===========================================")
            NSLog("SAVED SEARCH RESPONSE success=%@ message=%@", String(describing: response.success), response.message ?? "")
        } catch {
            print("========== SAVED SEARCH ERROR ==========")
            print(error)
            print("========================================")
            NSLog("SAVED SEARCH ERROR: %@", error.localizedDescription)
            throw error
        }
    }

    class func myLeadsAPI(syncBuyerStore: Bool = true) async throws -> [PlatformLead] {
        print("MY LEADS GET: \(Constant.myLeadsURL)")
        let response: MyLeadsResponse = try await ServiceHandler.genericAPI(
            url: Constant.myLeadsURL,
            method: .get,
            isMutable: false,
            param: [:]
        )
        let leads = response.leads.map { $0.asPlatformLead() }
            .sorted { $0.createdAt > $1.createdAt }
        if syncBuyerStore {
            RealtorDesk.shared.replaceBuyerLeads(with: leads)
        }
        return leads
    }

    class func localDashboardFilters() -> FilterOptionsData {
        localFilterOptions(language: LanguageManager.shared.currentLanguage)
    }

    private class func localFilterOptions(language: String) -> FilterOptionsData {
        FilterOptionsData(
            language: language,
            listingTypes: [
                FilterOption(value: "BUY", label: "Buy"),
                FilterOption(value: "RENT", label: "Rent")
            ],
            propertyTypes: [
                FilterOption(value: "APARTMENT", label: "Apartment"),
                FilterOption(value: "FLAT", label: "Flat"),
                FilterOption(value: "HOUSE", label: "House"),
                FilterOption(value: "VILLA", label: "Villa"),
                FilterOption(value: "CONDO", label: "Condo")
            ],
            furnishedStatuses: [
                FilterOption(value: "FURNISHED", label: "Furnished"),
                FilterOption(value: "SEMI_FURNISHED", label: "Semi Furnished"),
                FilterOption(value: "UNFURNISHED", label: "Unfurnished")
            ],
            amenities: [
                Amenity(id: "pool", name: "Pool"),
                Amenity(id: "parking", name: "Parking"),
                Amenity(id: "gym", name: "Gym"),
                Amenity(id: "garden", name: "Garden"),
                Amenity(id: "ac", name: "A/C"),
                Amenity(id: "elevator", name: "Elevator"),
                Amenity(id: "security", name: "Security"),
                Amenity(id: "ocean-view", name: "Ocean View")
            ]
        )
    }
    
}

class BuyerViewMode{
    
}
