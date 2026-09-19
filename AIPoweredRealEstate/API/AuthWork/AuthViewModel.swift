//
//  AuthViewModel.swift
//  AIPoweredRealEstate
//
//  Created by Shireen on 03/09/26.
//

import Foundation

class AuthViewModel {

    class func loginAPI(param: [String: Any]) async throws -> LoginResponse {
        print("LOGIN API CALL: \(Constant.loginURL)")
        NSLog("LOGIN API CALL: %@", Constant.loginURL)
        return try await ServiceHandler.genericAPI(
            url: Constant.loginURL,
            method: .post,
            isMutable: false,
            param: param
        )
    }

    class func forgotPasswordSendOTPAPI(param: [String: Any]) async throws -> APIStatusResponse {
        print("FORGOT PASSWORD SEND OTP POST: \(Constant.forgotPasswordSendOTPURL) param=\(param)")
        return try await ServiceHandler.genericAPI(
            url: Constant.forgotPasswordSendOTPURL,
            method: .post,
            isMutable: false,
            param: param,
            requiresAuth: true
        )
    }

    class func forgotPasswordVerifyOTPAPI(param: [String: Any]) async throws -> APIStatusResponse {
        print("FORGOT PASSWORD VERIFY OTP POST: \(Constant.forgotPasswordVerifyOTPURL) param=\(param)")
        return try await ServiceHandler.genericAPI(
            url: Constant.forgotPasswordVerifyOTPURL,
            method: .post,
            isMutable: false,
            param: param,
            requiresAuth: true
        )
    }

    class func forgotPasswordResetAPI(param: [String: Any]) async throws -> APIStatusResponse {
        print("FORGOT PASSWORD RESET POST: \(Constant.forgotPasswordResetURL) param=\(param)")
        return try await ServiceHandler.genericAPI(
            url: Constant.forgotPasswordResetURL,
            method: .post,
            isMutable: false,
            param: param,
            requiresAuth: true
        )
    }

    class func resendVerificationAPI(param: [String: Any]) async throws -> VerifyEmailResponse {
        try await ServiceHandler.genericAPI(
            url: Constant.resendVerificationURL,
            method: .post,
            isMutable: false,
            param: param,
            requiresAuth: false
        )
    }

    class func registerTenantAPI(param: [String: Any]) async throws -> RegisterResponseModel {
        try await ServiceHandler.genericAPI(
            url: Constant.buyerRegisterURL,
            method: .post,
            isMutable: false,
            param: param
        )
    }

    class func registerAgentAPI(param: [String: Any]) async throws -> AgentRegistrationResponse {
        try await ServiceHandler.genericAPI(
            url: Constant.agentRegisterURL,
            method: .post,
            isMutable: true,
            param: param
        )
    }

    class func agenciesAPI() async throws -> [AgencyItem] {
        print("AGENCIES GET: \(Constant.agenciesURL)")
        let response: AgenciesResponse = try await ServiceHandler.genericAPI(
            url: Constant.agenciesURL,
            method: .get,
            isMutable: false,
            param: [:],
            requiresAuth: true
        )
        return response.items
    }

    class func profileAPI() async throws -> GetProfileResponseModel {
        try await ServiceHandler.genericAPI(
            url: Constant.profileURL,
            method: .get,
            isMutable: false
        )
    }
   
    class func updateProfileAPI(param: [String: Any]) async throws -> UpdateProfileResponseModel {
        try await ServiceHandler.genericAPI(
            url: Constant.profileURL,
            method: .put,
            isMutable: ServiceHandler.containsUpload(param),
            param: param
        )
    }

    class func changeLanguageAPI(param: [String: Any]) async throws -> APIStatusResponse {
        try await ServiceHandler.genericAPI(
            url: Constant.changeLanguageURL,
            method: .put,
            isMutable: false,
            param: param
        )
    }

    class func changePasswordAPI(param: [String: Any]) async throws -> ChangePasswordResponseModel {
        print("CHANGE PASSWORD PUT: \(Constant.changePasswordURL) param=\(param)")
        return try await ServiceHandler.genericAPI(
            url: Constant.changePasswordURL,
            method: .put,
            isMutable: false,
            param: param
        )
     }

    class func notificationsAPI(page: Int = 1, limit: Int = 10) async throws -> GetNotificationsResponseModel {
        print("NOTIFICATIONS GET: \(Constant.notificationsURL) page=\(page) limit=\(limit)")
        return try await ServiceHandler.genericAPI(
            url: Constant.notificationsURL,
            method: .get,
            isMutable: false,
            param: [
                "page": page,
                "limit": limit
            ]
        )
    }

    class func notificationCountAPI() async throws -> NewNotificationsResponseModel {
        print("NEW NOTIFICATIONS GET: \(Constant.newNotificationsURL)")
        return try await ServiceHandler.genericAPI(
            url: Constant.newNotificationsURL,
            method: .get,
            isMutable: false
        )
    }

    class func deleteNotificationAPI(id: String) async throws -> DeleteNotificationResponseModel {
        try await ServiceHandler.genericAPI(
            url: Constant.deleteNotificationURL(id: id),
            method: .delete,
            isMutable: false
        )
    }
}
