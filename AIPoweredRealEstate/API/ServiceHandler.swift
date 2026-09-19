//
//  ServiceHandler.swift
//  AIPoweredRealEstate
//
//  Created by Shireen on 18/08/26.
//

import Foundation
import UIKit

enum APIMethods:String{
   case get = "GET"
   case post = "POST"
   case put = "PUT"
   case delete = "DELETE"
}

enum APIError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let text):
            return text
        }
    }
}

struct UploadFile {
    let data: Data
    let fileName: String
    let mimeType: String
}

class ServiceHandler{
    
    class func genericAPI<T: Decodable>(url:String,method:APIMethods = .get,isMutable:Bool = false,param:[String:Any] = [:], requiresAuth: Bool = true) async throws -> T{
        let param = normalizedParams(param, url: url)
        let requestURL = method == .get ? urlWithQuery(url, param: param) : url
        guard let url = URL(string: requestURL) else{throw URLError(.badURL) }
        
        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(LanguageManager.shared.currentLanguage == "es" ? "es" : "en", forHTTPHeaderField: "Accept-Language")
        
        if requiresAuth {
            let token = KeyChainManager.normalizedAuthToken(KeyChainManager.shared.getValue(key: "token"))
            if token.isEmpty == false {
                req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        
        if param.isEmpty == false, method != .get {
            switch isMutable{
            case false:
                req.addValue("application/json", forHTTPHeaderField: "Content-Type")
                let body = try JSONSerialization.data(withJSONObject: param)
                req.httpBody = body
            case true:
                let boundary = "Boundary-\(UUID().uuidString)"
                req.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                let body = getMutableBody(param: param, boundary: boundary)
                req.httpBody = body
                logLine("MULTIPART Content-Type: multipart/form-data; bodyBytes=\(body.count)")
            }
        }

        logRequest(method: method.rawValue, url: requestURL, param: sanitizedLogParam(param))

        let data: Data
        let urlResponse: URLResponse
        do {
            (data, urlResponse) = try await URLSession.shared.data(for: req)
        } catch {
            logLine("API NETWORK ERROR: \(error.localizedDescription)")
            throw error
        }
        
        guard let response = urlResponse as? HTTPURLResponse else{
            logResponse(url: requestURL, status: nil, data: data, error: "Invalid response")
            throw URLError(.badServerResponse)
        }

        logResponse(url: requestURL, status: response.statusCode, data: data, error: nil)

        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let success = object["success"] as? Bool,
           success == false {
            throw APIError.message(errorMessage(from: data, status: response.statusCode))
        }
        
        guard (200...299).contains(response.statusCode) else {
            throw APIError.message(errorMessage(from: data, status: response.statusCode))
        }

        do {
            let payload = data.isEmpty ? Data("{}".utf8) : data
            return try JSONDecoder().decode(T.self, from: payload)
        } catch {
            logLine("API DECODE ERROR: \(error)")
            throw error
        }
        
    }

    private static let languageParamKeys: Set<String> = [
        "lang", "language", "langInput", "preferredLanguage"
    ]

    private class func normalizedParams(_ param: [String: Any], url: String) -> [String: Any] {
        let lower = url.lowercased()
        let keepLanguage = lower.contains("/login")
            || lower.hasSuffix("login")
            || lower.contains("register-user")
            || lower.contains("register-agent")
            || lower.hasSuffix("/register")
            || lower.contains("/register?")
            || lower.contains("change-language")
            || lower.contains("resend-verification")
            || lower.contains("forgot-password/send-otp")
            || lower.contains("forgot-password/verify-otp")
            || lower.contains("forgot-password/reset")
        if keepLanguage {
            return param
        }
        return stripLanguageKeys(param, keepPreferredLanguage: false)
    }

    private class func stripLanguageKeys(_ param: [String: Any], keepPreferredLanguage: Bool) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in param {
            if Self.languageParamKeys.contains(key) {
                if keepPreferredLanguage && key == "preferredLanguage" {
                    result[key] = value
                }
                continue
            }
            if let nested = value as? [String: Any] {
                result[key] = stripLanguageKeys(nested, keepPreferredLanguage: false)
            } else {
                result[key] = value
            }
        }
        return result
    }

    private class func sanitizedLogParam(_ param: [String: Any]) -> [String: Any] {
        var logged: [String: Any] = [:]
        for (key, value) in param {
            if let file = value as? UploadFile {
                logged[key] = "<file \(file.fileName) \(file.data.count) bytes>"
            } else if let image = value as? UIImage, let data = jpegData(from: image) {
                let name = key == "document" ? "document.jpg" : (key == "profileImage" ? "profileImage.jpg" : "image.jpg")
                logged[key] = "<image \(name) \(data.count) bytes>"
            } else if value is UIImage {
                logged[key] = "<image encode-failed>"
            } else {
                logged[key] = value
            }
        }
        return logged
    }

    private class func logRequest(method: String, url: String, param: [String: Any]) {
        logLine("""
        ========== API REQUEST ==========
        METHOD: \(method)
        URL: \(url)
        AUTH: \(authLogValue())
        PARAMETERS: \(prettyJSON(param))
        =================================
        """)
    }

    private class func logResponse(url: String, status: Int?, data: Data, error: String?) {
        var lines = """
        ========== API RESPONSE ==========
        URL: \(url)
        """
        if let status {
            lines += "\nSTATUS: \(status)"
        }
        if let error {
            lines += "\nERROR: \(error)"
        }
        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            lines += "\nRESPONSE: \(prettyJSONString(text))"
        } else {
            lines += "\nRESPONSE: <empty>"
        }
        lines += "\n=================================="
        logLine(lines)
    }

    private class func logLine(_ message: String) {
        print(message)
        NSLog("%@", message)
    }

    private class func authLogValue() -> String {
        let token = KeyChainManager.normalizedAuthToken(KeyChainManager.shared.getValue(key: "token"))
        if token.isEmpty { return "missing" }
        let parts = token.split(separator: ".").count
        return "Bearer present (\(token.count) chars, jwtParts=\(parts))"
    }

    private class func prettyJSON(_ object: Any) -> String {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let text = String(data: data, encoding: .utf8) else {
            return "\(object)"
        }
        return text
    }

    private class func prettyJSONString(_ text: String) -> String {
        guard let data = text.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let output = String(data: pretty, encoding: .utf8) else {
            return text
        }
        return output
    }

    class func containsUpload(_ param: [String: Any]) -> Bool {
        param.values.contains {
            $0 is UIImage || $0 is [UIImage] || $0 is UploadFile
        }
    }

    private class func errorMessage(from data: Data, status: Int) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let message = object["message"] as? String {
                let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty == false { return trimmed }
            }
            if let messages = object["message"] as? [String] {
                let joined = messages.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                if joined.isEmpty == false { return joined }
            }
            if let error = object["error"] as? String {
                let trimmed = error.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty == false { return trimmed }
            }
        }
        return "Request failed (\(status))."
    }

    class func urlWithQuery(_ url: String, param: [String: Any]) -> String {
        guard !param.isEmpty else { return url }
        var items: [String] = []
        for (key, value) in param {
            if let values = value as? [Any] {
                for item in values {
                    items.append("\(encodeQuery(key))=\(encodeQuery("\(item)"))")
                }
            } else if !(value is NSNull) {
                items.append("\(encodeQuery(key))=\(encodeQuery("\(value)"))")
            }
        }
        guard !items.isEmpty else { return url }
        let separator = url.contains("?") ? "&" : "?"
        return url + separator + items.joined(separator: "&")
    }

    private class func encodeQuery(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
    }
    
    class func getMutableBody(param:[String:Any],boundary:String) -> Data{
        
        let body = NSMutableData()
        
        for (key,value) in param{
            if let image = value as? UIImage{
                if let img = jpegData(from: image) {
                    let fileName = key == "document" ? "document.jpg" : (key == "profileImage" ? "profileImage.jpg" : "image.jpg")
                    body.appendstr(str: "--\(boundary)\r\n")
                    body.appendstr(str: "Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(fileName)\"\r\n")
                    body.appendstr(str: "Content-Type: image/jpeg\r\n\r\n")
                    body.append(img)
                    body.appendstr(str: "\r\n")
                    logLine("MULTIPART PART: \(key)=file \(fileName) \(img.count) bytes")
                } else {
                    logLine("MULTIPART PART: \(key)=image encode failed")
                }
            }
            else if let imageArray = value as? [UIImage]{
                for image in imageArray{
                    if let img = jpegData(from: image) {
                        body.appendstr(str: "--\(boundary)\r\n")
                        body.appendstr(str: "Content-Disposition: form-data; name=\"\(key)\"; filename=\"image.jpg\"\r\n")
                        body.appendstr(str: "Content-Type: image/jpeg\r\n\r\n")
                        body.append(img)
                        body.appendstr(str: "\r\n")
                    }
                }
            }
            else if let file = value as? UploadFile {
                let fileName = file.fileName
                    .replacingOccurrences(of: "\"", with: "")
                    .replacingOccurrences(of: "\r", with: "")
                    .replacingOccurrences(of: "\n", with: "")
                body.appendstr(str: "--\(boundary)\r\n")
                body.appendstr(str: "Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(fileName)\"\r\n")
                body.appendstr(str: "Content-Type: \(file.mimeType)\r\n\r\n")
                body.append(file.data)
                body.appendstr(str: "\r\n")
            }
            else{
                body.appendstr(str: "--\(boundary)\r\n")
                body.appendstr(str: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendstr(str: "\(value)\r\n")
            }
        }
        
        body.appendstr(str: "--\(boundary)--\r\n")
        
        return body as Data
    }

    private class func jpegData(from image: UIImage) -> Data? {
        if let data = image.jpegData(compressionQuality: 0.7), !data.isEmpty {
            return data
        }
        if let data = image.pngData(), !data.isEmpty {
            return data
        }
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale == 0 ? 1 : image.scale
        let rendered = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return rendered.jpegData(compressionQuality: 0.7)
    }
     
}

extension NSMutableData{
    func appendstr(str:String){
        if let data = str.data(using: .utf8){
            append(data)
        }
    }
}
