//
//  TenantAISearchVC.swift
//  AIPoweredRealEstate
//

import UIKit

class TenantAISearchVC: UIViewController {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputCardView: CustomView!
    @IBOutlet weak var messageTextField: CustomTextField!
    @IBOutlet weak var sendButton: CustomButton!
    @IBOutlet weak var recommendationsCollection: UICollectionView!
    @IBOutlet weak var recommendationsHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var recommendationsTitleLabel: UILabel!

    var initialQuery: String?
    var chatId: String?
    var approveLeadIfNeeded = false

    private var messages: [AIChatMessage] = [
        AIChatMessage(
            sender: .assistant,
            text: "Tell me what you're looking for... a villa near the beach, a 2-bed apartment in Santo Domingo, or anything in between.".localized,
            isParameters: false
        )
    ]
    private var matches: [PropertyItem] = []
    private var assembledMessage = ""
    private var isSending = false
    private var filterOptions: FilterOptionsData?
    private var currentOptions: [DashboardFilterChip] = []
    private var localFilters = AIExtractedFilters()
    private var pendingField: ChatFilterField?
    private var amenityTitles: [String: String] = [:]
    private var hideActionButtons = false
    private var savedSearchId: String?
    private let optionScroll = UIScrollView()
    private let optionStack = UIStackView()
    private let helpBar = UIStackView()
    private var inputBottomConstraint: NSLayoutConstraint?
    private let inputBottomResting: CGFloat = 12

    override func viewDidLoad() {
        super.viewDidLoad()
        applyStyle()
        setupChat()
        setupRecommendations()
        observeKeyboard()
        markActiveLeadApprovedIfNeeded()
        sendInitialQueryIfNeeded()
    }

    private func markActiveLeadApprovedIfNeeded() {
        guard isAgentFlow, approveLeadIfNeeded else { return }
        let leadId = RealtorDesk.shared.activeLeadId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard leadId.isEmpty == false else { return }
        let current = AgentStore.shared.leads.first(where: { $0.id == leadId })?.apiStatus
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
        if current == "approved" { return }
        Task {
            do {
                try await AgentViewModels.updateLeadStatusAPI(id: leadId, status: "approved")
                await MainActor.run {
                    AgentStore.shared.markLeadApiStatus(id: leadId, status: "approved")
                }
            } catch {
                print("AGENT LEAD STATUS PUT FAILED: \(error.localizedDescription)")
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        recommendationsCollection.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CommonMethods.updateGradientFrame(for: sendButton)
        recommendationsCollection.collectionViewLayout.invalidateLayout()
    }

    private func applyStyle() {
        view.backgroundColor = .screenBackgroundColor
        CommonMethods.styleFormCard(inputCardView)
        CommonMethods.styleTextField(messageTextField)
        CommonMethods.stylePrimaryButton(sendButton)
        recommendationsHeightConstraint.constant = 0
        recommendationsCollection.isHidden = true
        hideRecommendationsTitle()
        installHelpBar()
        installOptionBar()
    }

    private func installHelpBar() {
        helpBar.axis = .horizontal
        helpBar.spacing = 8
        helpBar.distribution = .fillEqually
        helpBar.translatesAutoresizingMaskIntoConstraints = false
        helpBar.isHidden = true
        view.addSubview(helpBar)
        NSLayoutConstraint.activate([
            helpBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            helpBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            helpBar.bottomAnchor.constraint(equalTo: inputCardView.topAnchor, constant: -10),
            helpBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func installOptionBar() {
        optionScroll.translatesAutoresizingMaskIntoConstraints = false
        optionScroll.showsHorizontalScrollIndicator = false
        optionScroll.isHidden = true
        optionStack.axis = .horizontal
        optionStack.spacing = 8
        optionStack.translatesAutoresizingMaskIntoConstraints = false
        optionScroll.addSubview(optionStack)
        view.addSubview(optionScroll)
        NSLayoutConstraint.activate([
            optionScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            optionScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            optionScroll.bottomAnchor.constraint(equalTo: inputCardView.topAnchor, constant: -10),
            optionScroll.heightAnchor.constraint(equalToConstant: 40),
            optionStack.leadingAnchor.constraint(equalTo: optionScroll.contentLayoutGuide.leadingAnchor),
            optionStack.trailingAnchor.constraint(equalTo: optionScroll.contentLayoutGuide.trailingAnchor),
            optionStack.topAnchor.constraint(equalTo: optionScroll.contentLayoutGuide.topAnchor),
            optionStack.bottomAnchor.constraint(equalTo: optionScroll.contentLayoutGuide.bottomAnchor),
            optionStack.heightAnchor.constraint(equalTo: optionScroll.frameLayoutGuide.heightAnchor)
        ])
    }

    private func hideOptions() {
        currentOptions = []
        optionScroll.isHidden = true
        optionStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    @objc private func optionTapped(_ sender: UIButton) {
        guard currentOptions.indices.contains(sender.tag) else { return }
        let option = currentOptions[sender.tag]
        hideOptions()
        if option.kind == .amenity {
            amenityTitles[option.value] = option.label
            amenityTitles[option.label] = option.label
            sendMessage(option.label, displayText: option.label.localized)
        } else {
            sendMessage(option.value, displayText: option.label.localized)
        }
    }

    private func refreshHelpBar() {
        helpBar.arrangedSubviews.forEach { $0.removeFromSuperview() }
        helpBar.isHidden = hideActionButtons || matches.isEmpty || !optionScroll.isHidden
        guard hideActionButtons == false, !matches.isEmpty else { return }
        if isAgentFlow {
            helpBar.addArrangedSubview(helpButton("Review AI ranking".localized, #selector(reviewRankingTapped)))
            helpBar.addArrangedSubview(helpButton("Search inventory".localized, #selector(searchInventoryTapped)))
        } else {
            helpBar.addArrangedSubview(helpButton("Search Myself".localized, #selector(searchMyselfTapped)))
            let contact = helpButton("Contact Agent".localized, #selector(contactAgentTapped))
            CommonMethods.styleYellowGradientButton(contact, cornerRadius: 12)
            helpBar.addArrangedSubview(contact)
        }
    }

    private func helpButton(_ title: String, _ selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .darkThemeColor
        button.layer.cornerRadius = 12
        button.addTarget(self, action: selector, for: .touchUpInside)
        return button
    }

    @objc private func searchMyselfTapped() {
        hideActionButtons = true
        helpBar.isHidden = true
        helpBar.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    @objc private func contactAgentTapped() {
        openContactAgent(property: matches.first)
    }

    @objc private func reviewRankingTapped() {
        let vc = AgentRecommendationReviewVC()
        vc.requestId = RealtorDesk.shared.activeRequestId
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func searchInventoryTapped() {
        tabBarController?.selectedIndex = 1
        navigationController?.popToRootViewController(animated: true)
    }

    private func setupChat() {
        tableView.register(AIChatCell.nib, forCellReuseIdentifier: AIChatCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .interactive
        messageTextField.delegate = self
        messageTextField.returnKeyType = .send
        inputBottomConstraint = view.constraints.first {
            ($0.secondItem as? UIView) === inputCardView && $0.secondAttribute == .bottom
        }
    }

    private func observeKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardFrameWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @objc private func keyboardFrameWillChange(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let curve = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt)
            ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let keyboard = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - keyboard.minY)
        let extra = max(0, overlap - view.safeAreaInsets.bottom)
        inputBottomConstraint?.constant = inputBottomResting + extra
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curve << 16)
        ) {
            self.view.layoutIfNeeded()
        }
    }

    private func setupRecommendations() {
        recommendationsCollection.register(PropertyCardCell.nib, forCellWithReuseIdentifier: PropertyCardCell.identifier)
        recommendationsCollection.dataSource = self
        recommendationsCollection.delegate = self
        recommendationsCollection.showsHorizontalScrollIndicator = false
        recommendationsCollection.backgroundColor = .clear
        recommendationsCollection.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        if let layout = recommendationsCollection.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 12
        }
    }

    @IBAction func backTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func sendTapped(_ sender: UIButton) {
        let query = messageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !query.isEmpty else { return }
        messageTextField.text = nil
        hideOptions()
        sendMessage(query, displayText: query)
    }

    private func sendInitialQueryIfNeeded() {
        let query = initialQuery?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !query.isEmpty else { return }
        initialQuery = nil
        messages = []
        tableView.reloadData()
        sendMessage(query, displayText: query)
    }

    private func sendMessage(_ value: String, displayText: String) {
        guard !isSending else { return }
        let text = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        hideOptions()
        helpBar.isHidden = true
        append(AIChatMessage(sender: .user, text: displayText, isParameters: false))
        runChatAPI(text)
    }

    private func resetChatFilters() {
        assembledMessage = ""
        localFilters = emptyFilters()
        pendingField = nil
        amenityTitles = [:]
        hideActionButtons = false
        savedSearchId = nil
        matches = []
        hideOptions()
        updateRecommendations()
    }

    private func runChatAPI(_ message: String) {
        isSending = true
        sendButton.isEnabled = false
        append(AIChatMessage(sender: .assistant, text: "Understanding your requirements...".localized, isParameters: false))
        saveSearch(message: message)
        Task {
            do {
                let data = try await TenantViewModels.chatAPI(message: message, chatId: chatId)
                await MainActor.run { self.applyChat(data) }
            } catch {
                await MainActor.run {
                    self.removeLoadingMessage()
                    self.finishSending()
                    self.handleChatAPIError(error)
                }
            }
        }
    }

    private func saveSearch(message: String) {
        let text = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else { return }
        Task {
            do {
                try await TenantViewModels.savedSearchAPI(message: text, chatId: chatId)
            } catch {
                print("SAVED SEARCH CALL FAILED: \(error.localizedDescription)")
            }
        }
    }

    private func applyChat(_ data: AIChatData) {
        removeLoadingMessage()
        matches = data.items
        updateRecommendations()
        let apiMessage = data.message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if apiMessage.isEmpty == false {
            append(AIChatMessage(sender: .assistant, text: apiMessage, isParameters: false))
        }
        helpBar.isHidden = true
        hideOptions()
        finishSending()
    }

    private func handleChatAPIError(_ error: Error) {
        let message = ((error as? APIError)?.errorDescription ?? error.localizedDescription)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let text = message.isEmpty ? "I couldn't complete that search. Please try again.".localized : message
        append(AIChatMessage(sender: .assistant, text: text, isParameters: false))
        guard presentedViewController == nil else { return }
        let isTokenFailed = message.caseInsensitiveCompare("Not authorized, token failed") == .orderedSame
        CommonMethods.showAlert(message: text, from: self) { [weak self] in
            guard let self, isTokenFailed else { return }
            KeyChainManager.shared.deleteValue(key: "token")
            KeyChainManager.shared.deleteValue(key: "UserRole")
            TenantAccount.shared.clear()
            self.goToWelcomeTapped()
        }
    }

    private func chatPayload() -> String {
        var parts: [String] = []
        let filters = localFilters.sanitized()
        if assembledMessage.isEmpty == false {
            parts.append(assembledMessage)
        }
        if let value = filters.listingType { parts.append("listingType \(value)") }
        if let value = filters.propertyType { parts.append("propertyType \(value)") }
        if let value = filters.location { parts.append("location \(value)") }
        if let value = filters.bedrooms { parts.append("\(value) BHK bedrooms \(value)") }
        if let value = filters.bathrooms { parts.append("\(value) bathroom bathrooms \(value)") }
        if let value = filters.minPrice { parts.append("minPrice \(value)") }
        if let value = filters.maxPrice { parts.append("maxPrice \(value)") }
        if let value = filters.furnishedStatus { parts.append("furnishedStatus \(value)") }
        if filters.amenities.isEmpty == false {
            let names = filters.amenities.compactMap { value -> String? in
                let name = amenityDisplayName(value)
                return name.isMongoObjectId ? nil : name
            }
            if names.isEmpty == false {
                parts.append("amenities \(names.joined(separator: " "))")
            }
        }
        return parts.joined(separator: ", ")
    }

    private func applyLocalAnswer(_ text: String) {
        switch pendingField {
        case .listingType:
            localFilters = localFilters.mergingMissing(from: AIExtractedFilters(listingType: text.apiListingType))
        case .propertyType:
            localFilters = localFilters.mergingMissing(from: AIExtractedFilters(propertyType: text.apiPropertyType))
        case .location:
            localFilters = localFilters.mergingMissing(from: AIExtractedFilters(location: text))
        case .bedrooms:
            if let count = parseBedrooms(text) {
                localFilters = localFilters.mergingMissing(from: AIExtractedFilters(bedrooms: count))
            }
        case .bathrooms:
            if let count = parseBathrooms(text) {
                localFilters = localFilters.mergingMissing(from: AIExtractedFilters(bathrooms: count))
            }
        case .price:
            if let amount = parsePrice(text) {
                localFilters = localFilters.mergingMissing(from: AIExtractedFilters(maxPrice: amount))
            }
        case .furnished:
            localFilters = localFilters.mergingMissing(from: AIExtractedFilters(furnishedStatus: text.apiFurnishedStatus))
        case .amenities:
            let name = amenityDisplayName(text)
            amenityTitles[text] = name
            localFilters = localFilters.mergingMissing(from: AIExtractedFilters(amenities: [name]))
        case .none:
            inferFilters(from: text)
        }
        pendingField = nil
    }

    private func inferFilters(from text: String) {
        if localFilters.hasBathrooms == false, let count = parseBathrooms(text) {
            localFilters = localFilters.mergingMissing(from: AIExtractedFilters(bathrooms: count))
        }
        if localFilters.hasBedrooms == false, let count = parseBedrooms(text) {
            localFilters = localFilters.mergingMissing(from: AIExtractedFilters(bedrooms: count))
        }
        if localFilters.hasPrice == false, let amount = parsePrice(text) {
            localFilters = localFilters.mergingMissing(from: AIExtractedFilters(maxPrice: amount))
        }
    }

    private func amenityDisplayName(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return trimmed }
        if let cached = amenityTitles[trimmed], cached.isEmpty == false {
            return cached
        }
        if let amenity = filterOptions?.amenities?.first(where: { $0.id == trimmed || $0.name?.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            let name = (amenity.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if name.isEmpty == false {
                amenityTitles[trimmed] = name
                return name
            }
        }
        return trimmed
    }

    private func parseBedrooms(_ text: String) -> Int? {
        parseRoomCount(text, keywords: ["bhk", "bedrooms", "bedroom", "beds", "bed"])
    }

    private func parseBathrooms(_ text: String) -> Int? {
        parseRoomCount(text, keywords: ["bathrooms", "bathroom", "baths", "bath"])
    }

    private func parseRoomCount(_ text: String, keywords: [String]) -> Int? {
        let lower = text.lowercased()
        for keyword in keywords {
            let escaped = NSRegularExpression.escapedPattern(for: keyword)
            let patterns = [
                "(\\d{1,2})\\s*\(escaped)",
                "\(escaped)\\s*(\\d{1,2})"
            ]
            for pattern in patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
                let range = NSRange(lower.startIndex..., in: lower)
                if let match = regex.firstMatch(in: lower, range: range),
                   match.numberOfRanges > 1,
                   let group = Range(match.range(at: 1), in: lower),
                   let value = Int(lower[group]),
                   AIExtractedFilters.validRoomCount(value) != nil {
                    return value
                }
            }
        }
        if let value = Int(lower.trimmingCharacters(in: .whitespacesAndNewlines)),
           AIExtractedFilters.validRoomCount(value) != nil {
            return value
        }
        return nil
    }

    private func parsePrice(_ text: String) -> Int? {
        let lower = text.lowercased().replacingOccurrences(of: ",", with: "")
        let patterns = [
            "(?:under|below|max|upto|up to|budget)\\s*(\\d{3,})",
            "(\\d{3,})\\s*(?:/month|/mo|month|rs|inr|usd|\\$)"
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(lower.startIndex..., in: lower)
            if let match = regex.firstMatch(in: lower, range: range),
               match.numberOfRanges > 1,
               let group = Range(match.range(at: 1), in: lower),
               let value = Int(lower[group]), value >= 100 {
                return value
            }
        }
        if let value = Int(lower.trimmingCharacters(in: .whitespacesAndNewlines)), value >= 100 {
            return value
        }
        return nil
    }

    private func emptyFilters() -> AIExtractedFilters {
        AIExtractedFilters(
            langInput: LanguageManager.shared.currentLanguage,
            listingType: nil,
            propertyType: nil,
            location: nil,
            bedrooms: nil,
            bathrooms: nil,
            minPrice: nil,
            maxPrice: nil,
            furnishedStatus: nil,
            amenities: []
        )
     }

    private func missingPrompts(from filters: AIExtractedFilters?) -> [FilterPrompt] {
        var prompts: [FilterPrompt] = []
        if filters?.hasListingType != true {
            prompts.append(FilterPrompt(
                field: .listingType,
                question: "Are you looking to buy or rent?".localized,
                options: chips(from: filterOptions?.listingTypes, kind: .listingType, fallback: [
                    ("BUY", "Buy"),
                    ("RENT", "Rent")
                ])
            ))
        }
        if filters?.hasPropertyType != true {
            prompts.append(FilterPrompt(
                field: .propertyType,
                question: "What type of property do you want?".localized,
                options: chips(from: filterOptions?.propertyTypes, kind: .propertyType, fallback: [
                    ("APARTMENT", "Apartment"),
                    ("FLAT", "Flat"),
                    ("HOUSE", "House"),
                    ("VILLA", "Villa")
                ])
            ))
        }
        if filters?.hasLocation != true {
            prompts.append(FilterPrompt(
                field: .location,
                question: "Which city or area are you looking in?".localized,
                options: []
            ))
        }
        if filters?.hasBedrooms != true {
            prompts.append(FilterPrompt(
                field: .bedrooms,
                question: "How many bedrooms?".localized,
                options: (1...4).map { DashboardFilterChip(kind: .propertyType, value: "\($0) BHK", label: "\($0) BHK") }
            ))
        }
        if filters?.hasBathrooms != true {
            prompts.append(FilterPrompt(
                field: .bathrooms,
                question: "How many bathrooms?".localized,
                options: (1...4).map { DashboardFilterChip(kind: .propertyType, value: "\($0) bathroom", label: "\($0) Bath") }
            ))
        }
        if filters?.hasPrice != true {
            prompts.append(FilterPrompt(
                field: .price,
                question: "What is your maximum budget?".localized,
                options: [
                    DashboardFilterChip(kind: .propertyType, value: "15000", label: "15,000"),
                    DashboardFilterChip(kind: .propertyType, value: "25000", label: "25,000"),
                    DashboardFilterChip(kind: .propertyType, value: "50000", label: "50,000"),
                    DashboardFilterChip(kind: .propertyType, value: "100000", label: "1,00,000")
                ]
            ))
        }
        if filters?.hasFurnished != true {
            prompts.append(FilterPrompt(
                field: .furnished,
                question: "What furnished status do you prefer?".localized,
                options: chips(from: filterOptions?.furnishedStatuses, kind: .furnished, fallback: [
                    ("FURNISHED", "Furnished"),
                    ("SEMI_FURNISHED", "Semi Furnished"),
                    ("UNFURNISHED", "Unfurnished")
                ])
            ))
        }
        if filters?.hasAmenities != true {
            prompts.append(FilterPrompt(
                field: .amenities,
                question: "Which amenities do you need?".localized,
                options: chips(from: amenityOptions(), kind: .amenity, fallback: [
                    ("parking", "Parking"),
                    ("gym", "Gym"),
                    ("pool", "Pool"),
                    ("security", "Security")
                ])
            ))
        }
        return prompts
    }

    private func amenityOptions() -> [FilterOption] {
        (filterOptions?.amenities ?? []).compactMap { amenity in
            let name = amenity.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let id = amenity.id?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !name.isEmpty || !id.isEmpty else { return nil }
            return FilterOption(value: id.isEmpty ? name : id, label: name.isEmpty ? id : name)
        }
    }

    private func chips(
        from options: [FilterOption]?,
        kind: DashboardFilterKind,
        fallback: [(String, String)]
    ) -> [DashboardFilterChip] {
        let remote = (options ?? []).compactMap { DashboardFilterChip(kind: kind, option: $0) }
        if !remote.isEmpty { return remote }
        return fallback.map { DashboardFilterChip(kind: kind, value: $0.0, label: $0.1) }
    }

    private func hideRecommendationsTitle() {
        recommendationsTitleLabel.text = nil
        recommendationsTitleLabel.isHidden = true
        if recommendationsTitleLabel.constraints.contains(where: {
            $0.firstAttribute == .height && $0.secondItem == nil
        }) == false {
            recommendationsTitleLabel.heightAnchor.constraint(equalToConstant: 0).isActive = true
        }
        recommendationsTitleLabel.superview?.constraints.first {
            $0.firstItem === recommendationsCollection && $0.secondItem === recommendationsTitleLabel
        }?.constant = 0
    }

    private func updateRecommendations() {
        let hasItems = !matches.isEmpty
        hideRecommendationsTitle()
        recommendationsCollection.isHidden = !hasItems
        recommendationsHeightConstraint.constant = hasItems ? PropertyCardCell.preferredHeight : 0
        recommendationsCollection.reloadData()
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    private func removeLoadingMessage() {
        if messages.last?.text == "Understanding your requirements...".localized {
            messages.removeLast()
            tableView.reloadData()
        }
    }

    private func finishSending() {
        isSending = false
        sendButton.isEnabled = true
    }

    private func append(_ message: AIChatMessage) {
        messages.append(message)
        tableView.reloadData()
        let last = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: last, at: .bottom, animated: true)
    }

    private func toggleAISearchFavorite(_ property: PropertyItem) {
        let apply: (Bool) -> Void = { [weak self] isFav in
            guard let self, let index = self.matches.firstIndex(where: { $0.id == property.id }) else { return }
            self.matches[index].isFav = isFav
            self.recommendationsCollection.reloadItems(at: [IndexPath(item: index, section: 0)])
        }
        if isAgentFlow {
            toggleAgentWorkingSet(property) {
                apply(AgentStore.shared.isFavorite(property.id))
            }
        } else {
            toggleFavoriteRemote(propertyId: property.id, completion: apply)
        }
    }
}

extension TenantAISearchVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AIChatCell.identifier, for: indexPath) as? AIChatCell else {
            return UITableViewCell()
        }
        cell.configure(messages[indexPath.row])
        return cell
    }
}

extension TenantAISearchVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        matches.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PropertyCardCell.identifier,
            for: indexPath
        ) as? PropertyCardCell else {
            return UICollectionViewCell()
        }
        let property = matches[indexPath.item]
        let isFavorite = isAgentFlow
            ? (AgentStore.shared.isFavorite(property.id) || property.isFav)
            : (PropertyStore.shared.isFavorite(property.id) || property.isFav)
        cell.configure(with: property, isFavorite: isFavorite, showsSource: isAgentFlow)
        cell.onFavorite = { [weak self] in
            self?.toggleAISearchFavorite(property)
        }
        cell.onTap = { [weak self] in
            self?.openPropertyDetails(property)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        openPropertyDetails(matches[indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 236, height: collectionView.bounds.height)
    }
}

extension TenantAISearchVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped(sendButton)
        return true
    }
}

private enum ChatFilterField {
    case listingType, propertyType, location, bedrooms, bathrooms, price, furnished, amenities
}

private struct FilterPrompt {
    let field: ChatFilterField
    let question: String
    let options: [DashboardFilterChip]
}
