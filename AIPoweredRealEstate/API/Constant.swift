//
//  Constant.swift
//  AIPoweredRealEstate
//
//  Created by Shireen on 18/08/26.
//

import Foundation

enum Constant {
    /// Set to `true` when the backend is available. While `false`, login/register/profile stay local.
    static let useRemoteAPI = false

   // static let baseURL = "http://192.168.1.98:5002/api/users/"
    static let baseURL = "https://sisccltd.com/kleverProp/api/users/"
    static let mediaBaseURL = "https://sisccltd.com/kleverProp"
    static let buyerRegisterURL = baseURL+"register-user"
    static let agentRegisterURL = baseURL+"register-agent"
    static let agenciesURL = baseURL+"agencies"
    static let loginURL = baseURL+"login"
    static let forgotPasswordSendOTPURL = baseURL+"forgot-password/send-otp"
    static let forgotPasswordVerifyOTPURL = baseURL+"forgot-password/verify-otp"
    static let forgotPasswordResetURL = baseURL+"forgot-password/reset"
    static let resendVerificationURL = baseURL+"resend-verification"
    static let profileURL = baseURL+"profile"  //get,put
    static let changePasswordURL = baseURL+"change-password"  //put
    static let changeLanguageURL = baseURL+"change-language"  //put
    static let notificationsURL = baseURL + "notifications"  //get
    static let newNotificationsURL = baseURL + "notifications/new"  //get
    static let filterOptionsURL = baseURL + "properties/filter-options"
    static let propertySearchURL = baseURL + "properties/filter"
    static let propertyCompareURL = baseURL + "properties/compare"
    static let recentlyViewedURL = baseURL + "recently-viewed"

    static func recentlyViewedURL(id: String) -> String {
        baseURL + "recently-viewed/\(id)"
    }
    static let recentlyAISearchURL = baseURL + "recently-ai-search"
    static let aiSearchHistoryURL = baseURL + "ai-search-history"

    static func aiSearchHistoryURL(id: String) -> String {
        baseURL + "ai-search-history/\(id)"
    }
    static let favoritesURL = baseURL + "favorites"
    static let favoritesToggleURL = baseURL + "favorites/toggle"
    static let agentsURL = baseURL + "agents"
    static let sendLeadURL = baseURL + "send-lead"
    static let myLeadsURL = baseURL + "my-leads"
    static let agentLeadsURL = baseURL + "agent/leads"

    static func agentLeadStatusURL(id: String) -> String {
        baseURL + "agent/leads/\(id)/status"
    }
   
    static let chatURL = baseURL + "chat"
   
    static let savedSearchURL = baseURL + "saved-search"

    static func propertyDetailsURL(id: String) -> String {
        baseURL + "properties/\(id)"
    }

    static func marketingContentURL(id: String) -> String {
        baseURL + "properties/\(id)/marketing-content"
    }

    static func deleteNotificationURL(id: String) -> String {
        baseURL + "notifications/\(id)"
    }

    static func mediaURL(_ path: String) -> String {
        let trimmed = path
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\", with: "/")
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        guard trimmed.isEmpty == false else { return trimmed }

        let mediaRoot = mediaBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let mediaHost = URL(string: mediaBaseURL)?.host?.lowercased()
        let apiHost = URL(string: baseURL)?.host?.lowercased()

        func joined(_ relative: String) -> String {
            var rel = relative.trimmingCharacters(in: .whitespacesAndNewlines)
            if rel.hasPrefix("./") { rel = String(rel.dropFirst(2)) }
            if rel.hasPrefix("/") { return mediaRoot + rel }
            return mediaRoot + "/" + rel
        }

        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? trimmed
        if let url = URL(string: trimmed) ?? URL(string: encoded),
           let scheme = url.scheme?.lowercased(),
           scheme == "http" || scheme == "https" {
            let host = url.host?.lowercased() ?? ""
            let rewriteToMedia = host.isEmpty
                || host == mediaHost
                || host == apiHost
                || host == "localhost"
                || host == "127.0.0.1"
            if rewriteToMedia {
                var relative = url.path
                if let query = url.query, query.isEmpty == false {
                    relative += "?" + query
                }
                return joined(relative)
            }
            return url.absoluteString
        }

        return joined(trimmed)
    }

    static func mediaImageURL(_ path: String?) -> URL? {
        guard let path else { return nil }
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        let string = mediaURL(trimmed)
        if let url = URL(string: string) { return url }
        let encoded = string.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        return encoded.flatMap(URL.init(string:))
    }
   
    // Replace with your Maps SDK for iOS key from Google Cloud Console.
    static let googleMapsAPIKey = "AIzaSyAaAOACcSdZsf0MJnQ3O6vQtMGxvP8kMCY"
    
}
