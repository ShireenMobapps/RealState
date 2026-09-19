//
//  AuthModel.swift
//  AIPoweredRealEstate
//
//  Created by Shireen on 03/09/26.
//

import Foundation

// Login Model for Both
struct LoginResponse: Decodable {
    let success: Bool?
    let message: String?
    let data: LoginNewData?
    let token: String?

    var resolvedToken: String? {
        let candidates = [
            data?.accessToken,
            token
        ]
        for candidate in candidates {
            let value = KeyChainManager.normalizedAuthToken(candidate)
            if value.isEmpty == false { return value }
        }
        return nil
    }

    enum CodingKeys: String, CodingKey {
        case success, message, data, token, accessToken, access_token
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        success = try? c.decodeIfPresent(Bool.self, forKey: .success)
        message = try? c.decodeIfPresent(String.self, forKey: .message)
        data = try? c.decodeIfPresent(LoginNewData.self, forKey: .data)
        token = (try? c.decodeIfPresent(String.self, forKey: .token))
            ?? (try? c.decodeIfPresent(String.self, forKey: .accessToken))
            ?? (try? c.decodeIfPresent(String.self, forKey: .access_token))
    }
}

struct VerifyEmailResponse: Decodable {
    let success: Bool?
    let message: String?
    let token: String?
    let data: LoginNewData?
    let user: User?
    let status: String?

    var resolvedUser: User? { data?.user ?? user }
    var resolvedStatus: String {
        (resolvedUser?.status ?? status ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    enum CodingKeys: String, CodingKey {
        case success, message, token, data, user, status
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        success = try? c.decodeIfPresent(Bool.self, forKey: .success)
        message = try? c.decodeIfPresent(String.self, forKey: .message)
        token = try? c.decodeIfPresent(String.self, forKey: .token)
        let decodedUser = try? c.decodeIfPresent(User.self, forKey: .user)
        let nestedLogin = try? c.decodeIfPresent(LoginNewData.self, forKey: .data)
        let nestedUser = try? c.decodeIfPresent(User.self, forKey: .data)
        data = nestedLogin
        user = decodedUser ?? nestedUser ?? nestedLogin?.user
        status = (try? c.decodeIfPresent(String.self, forKey: .status))
            ?? nestedUser?.status
            ?? nestedLogin?.user?.status
            ?? decodedUser?.status
    }
}

struct LoginNewData: Codable {
    let accessToken: String?
    let refreshToken: String?
    let user: User?

    enum CodingKeys: String, CodingKey {
        case accessToken, access_token
        case refreshToken, refresh_token
        case user, token
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = (try? c.decodeIfPresent(String.self, forKey: .accessToken))
            ?? (try? c.decodeIfPresent(String.self, forKey: .access_token))
            ?? (try? c.decodeIfPresent(String.self, forKey: .token))
            ?? Self.decodeNestedToken(c)
        refreshToken = (try? c.decodeIfPresent(String.self, forKey: .refreshToken))
            ?? (try? c.decodeIfPresent(String.self, forKey: .refresh_token))
        user = try? c.decodeIfPresent(User.self, forKey: .user)
    }

    private static func decodeNestedToken(_ c: KeyedDecodingContainer<CodingKeys>) -> String? {
        guard let nested = try? c.nestedContainer(keyedBy: CodingKeys.self, forKey: .token) else {
            return nil
        }
        return (try? nested.decodeIfPresent(String.self, forKey: .accessToken))
            ?? (try? nested.decodeIfPresent(String.self, forKey: .access_token))
            ?? (try? nested.decodeIfPresent(String.self, forKey: .token))
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(accessToken, forKey: .accessToken)
        try c.encodeIfPresent(refreshToken, forKey: .refreshToken)
        try c.encodeIfPresent(user, forKey: .user)
    }
}

struct ProfileAgency: Codable {
    let id: String?
    let name: String?
    let logo: String?

    enum CodingKeys: String, CodingKey {
        case id, _id, name, logo, image
        case agencyId, agency_id, agencyName, agency_name
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.string(c, keys: [.id, ._id, .agencyId, .agency_id])
        name = Self.string(c, keys: [.name, .agencyName, .agency_name])
        logo = Self.string(c, keys: [.logo, .image])
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(logo, forKey: .logo)
    }

    private static func string(
        _ c: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]
    ) -> String? {
        for key in keys {
            if let value = try? c.decodeIfPresent(String.self, forKey: key) {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty == false { return trimmed }
            }
            if let value = try? c.decodeIfPresent(Int64.self, forKey: key) {
                return String(value)
            }
        }
        return nil
    }
}

struct User: Codable {
    let id: String?
    let name: String?
    let email: String?
    let phone: String?
    let role: String?
    let status: String?
    let agencyId: String?
    let agencyName: String?
    let agencyLogo: String?
    let licenseNumber: String?
    let document: String?
    let profileImage: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, _id, name, email, phone, role, status, document
        case agency, agencyId, agency_id, agencyName, agency_name
        case licenseNumber, license_number, liceneseNumber
        case profileImage, profile_image, avatar, image, photo
        case profileImageUrl, profileImageURL, profile_image_url, profile_pic, profilePic, profilePhoto, profile
        case createdAt, created_at
    }

    init(
        id: String? = nil,
        name: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        role: String? = nil,
        status: String? = nil,
        agencyId: String? = nil,
        agencyName: String? = nil,
        agencyLogo: String? = nil,
        licenseNumber: String? = nil,
        document: String? = nil,
        profileImage: String? = nil,
        createdAt: String? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.role = role
        self.status = status
        self.agencyId = agencyId
        self.agencyName = agencyName
        self.agencyLogo = agencyLogo
        self.licenseNumber = licenseNumber
        self.document = document
        self.profileImage = profileImage
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.decodeFlexibleString(c, keys: [.id, ._id])
        name = Self.decodeFlexibleString(c, keys: [.name])
        email = Self.decodeFlexibleString(c, keys: [.email])
        phone = Self.decodeFlexibleString(c, keys: [.phone])
        role = Self.decodeFlexibleString(c, keys: [.role])
        status = Self.decodeFlexibleString(c, keys: [.status])
        let nestedAgency = try? c.decodeIfPresent(ProfileAgency.self, forKey: .agency)
        agencyId = nestedAgency?.id
            ?? Self.decodeFlexibleString(c, keys: [.agencyId, .agency_id])
        agencyName = nestedAgency?.name
            ?? Self.decodeFlexibleString(c, keys: [.agencyName, .agency_name, .agency])
        agencyLogo = nestedAgency?.logo
        licenseNumber = Self.decodeFlexibleString(c, keys: [.licenseNumber, .license_number, .liceneseNumber])
        document = Self.decodeFlexibleString(c, keys: [.document])
        profileImage = Self.decodeFlexibleMedia(c, keys: [
            .profileImage, .profile_image, .profileImageUrl, .profileImageURL, .profile_image_url,
            .profile_pic, .profilePic, .profilePhoto, .avatar, .photo, .image, .profile
        ])
        createdAt = Self.decodeFlexibleString(c, keys: [.createdAt, .created_at])
    }

    private struct MediaPathBlob: Decodable {
        let url: String?
        let path: String?
        let filename: String?
        let fileName: String?
        let src: String?
        let location: String?

        var resolved: String? {
            [url, path, filename, fileName, src, location]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { $0.isEmpty == false }
        }
    }

    private static func decodeFlexibleMedia(
        _ c: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]
    ) -> String? {
        if let value = decodeFlexibleString(c, keys: keys) { return value }
        for key in keys {
            if let blob = try? c.decodeIfPresent(MediaPathBlob.self, forKey: key),
               let value = blob.resolved {
                return value
            }
            if let list = try? c.decodeIfPresent([String].self, forKey: key),
               let value = list
                    .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                    .first(where: { $0.isEmpty == false }) {
                return value
            }
        }
        return nil
    }

    private static func decodeFlexibleString(
        _ c: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]
    ) -> String? {
        for key in keys {
            if let value = try? c.decodeIfPresent(String.self, forKey: key) {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty == false { return trimmed }
            }
            if let value = try? c.decodeIfPresent(Int64.self, forKey: key) {
                return String(value)
            }
            if let value = try? c.decodeIfPresent(Double.self, forKey: key) {
                return String(Int64(value))
            }
        }
        return nil
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(email, forKey: .email)
        try c.encodeIfPresent(phone, forKey: .phone)
        try c.encodeIfPresent(role, forKey: .role)
        try c.encodeIfPresent(status, forKey: .status)
        try c.encodeIfPresent(agencyId, forKey: .agencyId)
        try c.encodeIfPresent(agencyName, forKey: .agencyName)
        try c.encodeIfPresent(licenseNumber, forKey: .licenseNumber)
        try c.encodeIfPresent(document, forKey: .document)
        try c.encodeIfPresent(profileImage, forKey: .profileImage)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}
//Profile Model

struct GetProfileResponseModel: Codable {
    let success: Bool?
    let message: String?
    let data: User?
    let user: User?

    var resolvedUser: User? { data ?? user }

    enum CodingKeys: String, CodingKey {
        case success, message, data, user
    }

    init(success: Bool?, message: String?, data: User?, user: User? = nil) {
        self.success = success
        self.message = message
        self.data = data
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        success = try? c.decodeIfPresent(Bool.self, forKey: .success)
        message = try? c.decodeIfPresent(String.self, forKey: .message)
        let decodedUser = try? c.decodeIfPresent(User.self, forKey: .user)
        var decodedData = try? c.decodeIfPresent(User.self, forKey: .data)
        if decodedData?.profileImage == nil {
            struct Box: Decodable { let user: User? }
            if let nested = try? c.decodeIfPresent(Box.self, forKey: .data)?.user {
                if decodedData == nil || (decodedData?.profileImage == nil && nested.profileImage != nil) {
                    decodedData = nested
                }
            }
        }
        data = decodedData
        user = decodedUser
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(success, forKey: .success)
        try c.encodeIfPresent(message, forKey: .message)
        try c.encodeIfPresent(data, forKey: .data)
        try c.encodeIfPresent(user, forKey: .user)
    }
}

//Update Profile Model
struct UpdateProfileResponseModel: Codable {
    let success: Bool?
    let message: String?
    let data: User?
    let user: User?

    var resolvedUser: User? { data ?? user }

    enum CodingKeys: String, CodingKey {
        case success, message, data, user
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        success = try? c.decodeIfPresent(Bool.self, forKey: .success)
        if let text = try? c.decodeIfPresent(String.self, forKey: .message) {
            message = text
        } else if let list = try? c.decodeIfPresent([String].self, forKey: .message) {
            message = list.joined(separator: "\n")
        } else {
            message = nil
        }
        data = try? c.decodeIfPresent(User.self, forKey: .data)
        var decodedUser = try? c.decodeIfPresent(User.self, forKey: .user)
        if data?.profileImage == nil, decodedUser?.profileImage == nil {
            struct Box: Decodable { let user: User? }
            if let nested = try? c.decodeIfPresent(Box.self, forKey: .data)?.user {
                decodedUser = nested
            }
        }
        user = decodedUser
    }
}

//Change Password Model
struct ChangePasswordResponseModel: Codable {
    let success: Bool?
    let message: String?
}

struct AgencyItem {
    let id: String
    let name: String
    let imagePath: String?
}

struct AgenciesResponse: Decodable {
    let items: [AgencyItem]
    var names: [String] {
        items.map(\.name).filter { $0.isEmpty == false }
    }

    init(from decoder: Decoder) throws {
        if let list = Self.decodeItemList(from: decoder) {
            items = list
            return
        }
        let c = try decoder.container(keyedBy: DynamicCodingKey.self)
        let keys = ["data", "agencies", "items", "results", "list", "records"]
        for key in keys {
            if let nested = c.allKeys.first(where: { $0.stringValue == key }),
               let list = try? c.decode(AgenciesResponse.self, forKey: nested).items,
               list.isEmpty == false {
                items = list
                return
            }
        }
        items = []
    }

    private static func decodeItemList(from decoder: Decoder) -> [AgencyItem]? {
        guard var unkeyed = try? decoder.unkeyedContainer() else { return nil }
        var values: [AgencyItem] = []
        while unkeyed.isAtEnd == false {
            if let text = try? unkeyed.decode(String.self) {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty == false {
                    values.append(AgencyItem(id: "", name: trimmed, imagePath: nil))
                }
                continue
            }
            if let record = try? unkeyed.decode(AgencyRecord.self) {
                let name = record.displayName ?? ""
                if name.isEmpty == false || (record.imagePath?.isEmpty == false) || record.id.isEmpty == false {
                    values.append(AgencyItem(id: record.id, name: name, imagePath: record.imagePath))
                }
                continue
            }
            _ = try? unkeyed.decode(AnyDecodableValue.self)
        }
        return values
    }
}

private struct AgencyRecord: Decodable {
    let id: String
    let displayName: String?
    let imagePath: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: DynamicCodingKey.self)
        id = Self.firstId(in: c, keys: ["id", "_id", "agencyId", "agency_id"])
        displayName = Self.firstString(
            in: c,
            keys: ["name", "agencyName", "agency_name", "companyName", "company_name", "title", "label"]
        )
        var path = Self.firstString(
            in: c,
            keys: [
                "image", "logo", "photo", "banner",
                "imageUrl", "imageURL", "image_url",
                "logoUrl", "logoURL", "logo_url",
                "agencyImage", "agency_image",
                "companyLogo", "company_logo",
                "logoImage", "logo_image",
                "brandingImage", "branding_image",
                "profileImage", "profile_image"
            ]
        )
        if path == nil {
            path = Self.firstNestedImage(in: c, keys: ["image", "logo", "photo", "banner", "file", "media"])
        }
        imagePath = path
    }

    private static func firstId(in c: KeyedDecodingContainer<DynamicCodingKey>, keys: [String]) -> String {
        if let text = firstString(in: c, keys: keys) { return text }
        for key in keys {
            guard let codingKey = DynamicCodingKey(stringValue: key) else { continue }
            if let value = try? c.decodeIfPresent(Int.self, forKey: codingKey) {
                return String(value)
            }
            if let value = try? c.decodeIfPresent(Int64.self, forKey: codingKey) {
                return String(value)
            }
            if let value = try? c.decodeIfPresent(Double.self, forKey: codingKey) {
                return String(Int(value))
            }
        }
        return ""
    }

    private static func firstString(in c: KeyedDecodingContainer<DynamicCodingKey>, keys: [String]) -> String? {
        for key in keys {
            guard let codingKey = DynamicCodingKey(stringValue: key) else { continue }
            if let value = try? c.decodeIfPresent(String.self, forKey: codingKey) {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty == false { return trimmed }
            }
        }
        return nil
    }

    private static func firstNestedImage(in c: KeyedDecodingContainer<DynamicCodingKey>, keys: [String]) -> String? {
        for key in keys {
            guard let codingKey = DynamicCodingKey(stringValue: key),
                  let nested = try? c.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: codingKey)
            else { continue }
            if let path = firstString(in: nested, keys: ["url", "path", "src", "image", "logo", "filename", "file"]) {
                return path
            }
        }
        return nil
    }
}

private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { self.stringValue = String(intValue); self.intValue = intValue }
}

private struct AnyDecodableValue: Decodable {
    init(from decoder: Decoder) throws {
        _ = try? decoder.singleValueContainer()
    }
}

struct NotificationItemModel: Codable {
    let id: String
    let title: String?
    let message: String?
    let body: String?
    let createdAt: String?
    let isRead: Bool?
    let leadId: String?
    let type: String?

    var displayTitle: String {
        let text = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "Notification".localized : text
    }

    var displayMessage: String {
        (message ?? body ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayDate: String {
        Self.formattedDate(createdAt)
    }

    enum CodingKeys: String, CodingKey {
        case id, _id, title, message, body, description, type
        case createdAt, created_at, sentAt, sent_at, date
        case isRead, is_read, read
        case leadId, lead_id
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.decodeID(c, keys: [.id, ._id]) ?? UUID().uuidString
        title = Self.decodeString(c, keys: [.title])
        message = Self.decodeString(c, keys: [.message, .body, .description])
        body = Self.decodeString(c, keys: [.body, .description])
        createdAt = Self.decodeString(c, keys: [.createdAt, .created_at, .sentAt, .sent_at, .date])
        isRead = Self.decodeBool(c, keys: [.isRead, .is_read, .read])
        leadId = Self.decodeID(c, keys: [.leadId, .lead_id])
        type = Self.decodeString(c, keys: [.type])
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(title, forKey: .title)
        try c.encodeIfPresent(message, forKey: .message)
        try c.encodeIfPresent(body, forKey: .body)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(isRead, forKey: .isRead)
        try c.encodeIfPresent(leadId, forKey: .leadId)
        try c.encodeIfPresent(type, forKey: .type)
    }

    private static func decodeID(_ c: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> String? {
        for key in keys {
            if let value = try? c.decodeIfPresent(String.self, forKey: key) {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            }
            if let value = try? c.decodeIfPresent(Int.self, forKey: key) {
                return String(value)
            }
        }
        return nil
    }

    private static func decodeString(_ c: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> String? {
        for key in keys {
            if let value = try? c.decodeIfPresent(String.self, forKey: key) {
                return value
            }
        }
        return nil
    }

    private static func decodeBool(_ c: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> Bool? {
        for key in keys {
            if let value = try? c.decodeIfPresent(Bool.self, forKey: key) {
                return value
            }
            if let value = try? c.decodeIfPresent(Int.self, forKey: key) {
                return value != 0
            }
            if let value = try? c.decodeIfPresent(String.self, forKey: key) {
                switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
                case "true", "1", "yes": return true
                case "false", "0", "no": return false
                default: break
                }
            }
        }
        return nil
    }

    private static func formattedDate(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "" }
        guard let date = parseDate(raw) else { return raw }
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private static func parseDate(_ raw: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: raw) { return date }
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: raw) { return date }
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: raw) { return date }
        }
        return nil
    }
}

struct GetNotificationsResponseModel: Codable {
    let success: Bool?
    let message: String?
    let items: [NotificationItemModel]
    let page: Int
    let limit: Int
    let total: Int
    let hasMore: Bool

    init(from decoder: Decoder) throws {
        let parsed = try NotificationsResponseParser(from: decoder)
        success = parsed.success
        message = parsed.message
        items = parsed.items
        page = parsed.page
        limit = parsed.limit
        total = parsed.total
        hasMore = parsed.hasMore
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: NotificationsResponseKey.self)
        try c.encodeIfPresent(success, forKey: .success)
        try c.encodeIfPresent(message, forKey: .message)
        try c.encode(items, forKey: .data)
        try c.encode(page, forKey: .pageKey)
        try c.encode(limit, forKey: .limitKey)
        try c.encode(total, forKey: .totalKey)
        try c.encode(hasMore, forKey: .hasMoreKey)
    }
}

private enum NotificationsResponseKey: String, CodingKey {
    case success, message, data, notifications, items, docs, results, list
    case pageKey = "page"
    case limitKey = "limit"
    case totalKey = "total"
    case countKey = "count"
    case hasMoreKey = "hasMore"
    case hasMoreSnake = "has_more"
    case pagination
}

private struct NotificationsResponseParser: Decodable {
    let success: Bool?
    let message: String?
    let items: [NotificationItemModel]
    let page: Int
    let limit: Int
    let total: Int
    let hasMore: Bool

    init(from decoder: Decoder) throws {
        guard let container = try? decoder.container(keyedBy: NotificationsResponseKey.self) else {
            let list = try decoder.singleValueContainer().decode([NotificationItemModel].self)
            success = true
            message = nil
            items = list
            page = 1
            limit = max(list.count, 10)
            total = list.count
            hasMore = list.count >= 10
            return
        }

        success = try container.decodeIfPresent(Bool.self, forKey: .success)
        message = try container.decodeIfPresent(String.self, forKey: .message)

        let wrapped: NotificationsListData?
        if let value = try? container.decodeIfPresent(NotificationsListData.self, forKey: .data) {
            wrapped = value
        } else {
            wrapped = nil
        }

        let rootPagination: NotificationsPagination?
        if let value = try? container.decodeIfPresent(NotificationsPagination.self, forKey: .pagination) {
            rootPagination = value
        } else {
            rootPagination = nil
        }
        let pagination = rootPagination ?? wrapped?.pagination

        if let list = try? container.decode([NotificationItemModel].self, forKey: .data) {
            items = list
        } else if let wrapped, !wrapped.resolvedList.isEmpty {
            items = wrapped.resolvedList
        } else if let list = try? container.decode([NotificationItemModel].self, forKey: .notifications) {
            items = list
        } else if let list = try? container.decode([NotificationItemModel].self, forKey: .items) {
            items = list
        } else if let list = try? container.decode([NotificationItemModel].self, forKey: .docs) {
            items = list
        } else if let list = try? container.decode([NotificationItemModel].self, forKey: .results) {
            items = list
        } else if let list = try? container.decode([NotificationItemModel].self, forKey: .list) {
            items = list
        } else {
            items = wrapped?.resolvedList ?? []
        }

        if let value = wrapped?.page {
            page = value
        } else if let value = pagination?.page {
            page = value
        } else if let value = Self.decodeInt(container, keys: [.pageKey]) {
            page = value
        } else {
            page = 1
        }

        if let value = wrapped?.limit {
            limit = value
        } else if let value = pagination?.limit {
            limit = value
        } else if let value = Self.decodeInt(container, keys: [.limitKey]) {
            limit = value
        } else {
            limit = max(items.count, 10)
        }

        let knownTotal: Int?
        if let value = wrapped?.total {
            knownTotal = value
        } else if let value = pagination?.total {
            knownTotal = value
        } else {
            knownTotal = Self.decodeInt(container, keys: [.totalKey, .countKey])
        }
        total = knownTotal ?? items.count

        if let value = wrapped?.hasMore {
            hasMore = value
        } else if let value = pagination?.hasMore {
            hasMore = value
        } else if let value = Self.decodeBool(container, keys: [.hasMoreKey, .hasMoreSnake]) {
            hasMore = value
        } else if let knownTotal {
            hasMore = page * limit < knownTotal
        } else {
            hasMore = items.count >= limit
        }
    }

    private static func decodeInt(
        _ c: KeyedDecodingContainer<NotificationsResponseKey>,
        keys: [NotificationsResponseKey]
    ) -> Int? {
        for key in keys {
            if let value = try? c.decodeIfPresent(Int.self, forKey: key) { return value }
            if let value = try? c.decodeIfPresent(String.self, forKey: key), let intValue = Int(value) {
                return intValue
            }
        }
        return nil
    }

    private static func decodeBool(
        _ c: KeyedDecodingContainer<NotificationsResponseKey>,
        keys: [NotificationsResponseKey]
    ) -> Bool? {
        for key in keys {
            if let value = try? c.decodeIfPresent(Bool.self, forKey: key) {
                return value
            }
        }
        return nil
    }
}

private struct NotificationsPagination: Decodable {
    let page: Int?
    let limit: Int?
    let total: Int?
    let hasMore: Bool?

    enum CodingKeys: String, CodingKey {
        case pageKey = "page"
        case limitKey = "limit"
        case totalKey = "total"
        case countKey = "count"
        case hasMoreKey = "hasMore"
        case hasMoreSnake = "has_more"
        case hasNextPageKey = "hasNextPage"
        case hasNextPageSnake = "has_next_page"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        page = Self.decodeInt(c, keys: [.pageKey])
        limit = Self.decodeInt(c, keys: [.limitKey])
        total = Self.decodeInt(c, keys: [.totalKey, .countKey])
        if let value = try? c.decode(Bool.self, forKey: .hasMoreKey) {
            hasMore = value
        } else if let value = try? c.decode(Bool.self, forKey: .hasMoreSnake) {
            hasMore = value
        } else if let value = try? c.decode(Bool.self, forKey: .hasNextPageKey) {
            hasMore = value
        } else if let value = try? c.decode(Bool.self, forKey: .hasNextPageSnake) {
            hasMore = value
        } else {
            hasMore = nil
        }
    }

    private static func decodeInt(_ c: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> Int? {
        for key in keys {
            if let value = try? c.decodeIfPresent(Int.self, forKey: key) { return value }
            if let value = try? c.decodeIfPresent(String.self, forKey: key), let intValue = Int(value) {
                return intValue
            }
        }
        return nil
    }
}

private struct NotificationsListData: Decodable {
    let notifications: [NotificationItemModel]?
    let items: [NotificationItemModel]?
    let docs: [NotificationItemModel]?
    let results: [NotificationItemModel]?
    let list: [NotificationItemModel]?
    let nestedData: [NotificationItemModel]?
    let page: Int?
    let limit: Int?
    let total: Int?
    let count: Int?
    let hasMore: Bool?
    let pagination: NotificationsPagination?

    enum CodingKeys: String, CodingKey {
        case notifications, items, docs, results, list, data
        case pageKey = "page"
        case limitKey = "limit"
        case totalKey = "total"
        case countKey = "count"
        case hasMoreKey = "hasMore"
        case hasMoreSnake = "has_more"
        case pagination
    }

    init(from decoder: Decoder) throws {
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else {
            let array = try decoder.singleValueContainer().decode([NotificationItemModel].self)
            notifications = array
            items = nil
            docs = nil
            results = nil
            list = nil
            nestedData = nil
            page = nil
            limit = nil
            total = nil
            count = nil
            hasMore = nil
            pagination = nil
            return
        }

        notifications = try c.decodeIfPresent([NotificationItemModel].self, forKey: .notifications)
        items = try c.decodeIfPresent([NotificationItemModel].self, forKey: .items)
        docs = try c.decodeIfPresent([NotificationItemModel].self, forKey: .docs)
        results = try c.decodeIfPresent([NotificationItemModel].self, forKey: .results)
        list = try c.decodeIfPresent([NotificationItemModel].self, forKey: .list)
        nestedData = try c.decodeIfPresent([NotificationItemModel].self, forKey: .data)
        pagination = try c.decodeIfPresent(NotificationsPagination.self, forKey: .pagination)

        if let value = Self.decodeInt(c, keys: [.pageKey]) {
            page = value
        } else {
            page = pagination?.page
        }
        if let value = Self.decodeInt(c, keys: [.limitKey]) {
            limit = value
        } else {
            limit = pagination?.limit
        }
        if let value = Self.decodeInt(c, keys: [.totalKey, .countKey]) {
            total = value
        } else {
            total = pagination?.total
        }
        count = Self.decodeInt(c, keys: [.countKey])
        if let value = try? c.decode(Bool.self, forKey: .hasMoreKey) {
            hasMore = value
        } else if let value = try? c.decode(Bool.self, forKey: .hasMoreSnake) {
            hasMore = value
        } else {
            hasMore = pagination?.hasMore
        }
    }

    var resolvedList: [NotificationItemModel] {
        notifications ?? items ?? docs ?? results ?? list ?? nestedData ?? []
    }

    private static func decodeInt(_ c: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> Int? {
        for key in keys {
            if let value = try? c.decodeIfPresent(Int.self, forKey: key) { return value }
            if let value = try? c.decodeIfPresent(String.self, forKey: key), let intValue = Int(value) {
                return intValue
            }
        }
        return nil
    }
}

struct DeleteNotificationResponseModel: Codable {
    let success: Bool?
    let message: String?
}

struct NewNotificationsResponseModel: Decodable {
    let success: Bool?
    let message: String?
    let data: NewNotificationsData?

    var unreadCount: Int {
        data?.countNewNotification ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case success, message, data
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        success = try? c.decodeIfPresent(Bool.self, forKey: .success)
        message = try? c.decodeIfPresent(String.self, forKey: .message)
        if let nested = try? c.decodeIfPresent(NewNotificationsData.self, forKey: .data) {
            data = nested
        } else {
            data = try? NewNotificationsData(from: decoder)
        }
     }
    
}

struct NewNotificationsData: Decodable {
    
    let countNewNotification: Int?
    let unreadCount: Int?
    let lastFetchNotification: String?
    let newNotifications: [NotificationItemModel]?

    enum CodingKeys: String, CodingKey {
        case countNewNotification
        case count_new_notification
        case unreadCount
        case unread_count
        case lastFetchNotification
        case last_fetch_notification
        case newNotifications
        case new_notifications
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        countNewNotification = Self.decodeInt(c, keys: [.countNewNotification, .count_new_notification])
        unreadCount = Self.decodeInt(c, keys: [.unreadCount, .unread_count])
        lastFetchNotification = Self.decodeString(c, keys: [.lastFetchNotification, .last_fetch_notification])
        newNotifications = (try? c.decodeIfPresent([NotificationItemModel].self, forKey: .newNotifications))
            ?? (try? c.decodeIfPresent([NotificationItemModel].self, forKey: .new_notifications))
    }

    private static func decodeInt(_ c: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> Int? {
        for key in keys {
            if let value = try? c.decodeIfPresent(Int.self, forKey: key) { return value }
            if let value = try? c.decodeIfPresent(String.self, forKey: key), let intValue = Int(value) {
                return intValue
            }
        }
        return nil
    }

    private static func decodeString(_ c: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> String? {
        for key in keys {
            if let value = try? c.decodeIfPresent(String.self, forKey: key) {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty == false { return trimmed }
            }
        }
        return nil
     }
    
}

final class NotificationUnreadStore {
   
    static let shared = NotificationUnreadStore()
    
    static let didChange = Notification.Name("NotificationUnreadStore.didChange")

    private(set) var count = 0

    func apply(response: NewNotificationsResponseModel) {
        setCount(response.data?.countNewNotification ?? 0)
    }

    func reset() {
        setCount(0)
    }

    private func setCount(_ value: Int) {
        count = max(0, value)
        NotificationCenter.default.post(name: Self.didChange, object: nil)
    }
    
}
