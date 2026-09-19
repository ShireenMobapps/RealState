//
//  TenantSearchVC.swift
//  AIPoweredRealEstate
//

import UIKit

class TenantSearchVC: UIViewController {

    @IBOutlet weak var keywordField: CustomTextField!
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var rentButton: UIButton!
    @IBOutlet weak var filtersButton: UIButton!
    @IBOutlet weak var sortButton: UIButton!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var saveSearchButton: UIButton!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!

    private var criteria = PropertySearchCriteria()
    private var allResults: [PropertyItem] = []
    private var results: [PropertyItem] = []
    private var filterGroups: [DashboardFilterGroup] = []
    private var selectedFilters: [DashboardFilterKind: [DashboardFilterChip]] = [:]
    private var searchToken = UUID()
    private let filterBar = UIScrollView()
    private let quickSearchStack = UIStackView()
    private let rangeFilterBar = RangeFilterChipBar()
    private var rangeFilters = PropertyRangeFilters()
    private let contactAgentButton = CustomButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .screenBackgroundColor
        keywordField.delegate = self
        keywordField.addTarget(self, action: #selector(keywordChanged), for: .editingChanged)
        CommonMethods.styleTextField(keywordField)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PropertyCardCell.nib, forCellWithReuseIdentifier: PropertyCardCell.identifier)
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 24, right: 16)
        collectionView.keyboardDismissMode = .onDrag
        saveSearchButton.isHidden = true
        installDashboardFilterBar()
        installContactAgentButton()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: LanguageManager.didChange,
            object: nil
        )
        loadDashboardFilters()
        reloadProperties()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        contactAgentButton.setTitle("Contact Agent".localized, for: .normal)
        if let pending = PropertyStore.shared.consumePendingCriteria() {
            applyPendingCriteria(pending)
        }
        collectionView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
        CommonMethods.updateGradientFrame(for: contactAgentButton)
    }

    private func installDashboardFilterBar() {
        guard let chipStack = buyButton.superview as? UIStackView else { return }
        [buyButton, rentButton, filtersButton, sortButton].forEach {
            $0?.isHidden = true
            $0?.isUserInteractionEnabled = false
        }
        chipStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        chipStack.axis = .vertical
        chipStack.distribution = .fill
        chipStack.spacing = 10
        chipStack.constraints
            .filter { $0.firstAttribute == .height }
            .forEach { $0.isActive = false }

        filterBar.translatesAutoresizingMaskIntoConstraints = false
        filterBar.showsHorizontalScrollIndicator = false
        quickSearchStack.translatesAutoresizingMaskIntoConstraints = false
        quickSearchStack.axis = .horizontal
        quickSearchStack.spacing = 8
        quickSearchStack.alignment = .center
        filterBar.addSubview(quickSearchStack)
        chipStack.addArrangedSubview(filterBar)
        rangeFilterBar.host = self
        rangeFilterBar.onChanged = { [weak self] values in
            self?.rangeFilters = values
            self?.reloadProperties()
        }
        chipStack.addArrangedSubview(rangeFilterBar)

        NSLayoutConstraint.activate([
            filterBar.heightAnchor.constraint(equalToConstant: 36),
            quickSearchStack.leadingAnchor.constraint(equalTo: filterBar.contentLayoutGuide.leadingAnchor),
            quickSearchStack.trailingAnchor.constraint(equalTo: filterBar.contentLayoutGuide.trailingAnchor),
            quickSearchStack.topAnchor.constraint(equalTo: filterBar.contentLayoutGuide.topAnchor),
            quickSearchStack.bottomAnchor.constraint(equalTo: filterBar.contentLayoutGuide.bottomAnchor),
            quickSearchStack.heightAnchor.constraint(equalTo: filterBar.frameLayoutGuide.heightAnchor)
        ])
    }

    private func installContactAgentButton() {
        guard let chipStack = buyButton.superview as? UIStackView else { return }

        contactAgentButton.setTitle("Contact Agent".localized, for: .normal)
       
        contactAgentButton.setTitleColor(.white, for: .normal)
        
        contactAgentButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
       
        contactAgentButton.translatesAutoresizingMaskIntoConstraints = false
       
        contactAgentButton.addTarget(self, action: #selector(contactAgentTapped), for: .touchUpInside)
        
        CommonMethods.styleYellowGradientButton(contactAgentButton)
       
        view.addSubview(contactAgentButton)

        view.constraints
            .filter {
                ($0.firstItem as? UIView) === chipStack && $0.firstAttribute == .top
                    || ($0.secondItem as? UIView) === chipStack && $0.secondAttribute == .top
            }
            .forEach { $0.isActive = false }

        NSLayoutConstraint.activate([
            contactAgentButton.topAnchor.constraint(equalTo: keywordField.bottomAnchor, constant: 12),
            contactAgentButton.leadingAnchor.constraint(equalTo: keywordField.leadingAnchor),
            contactAgentButton.trailingAnchor.constraint(equalTo: keywordField.trailingAnchor),
            contactAgentButton.heightAnchor.constraint(equalToConstant: 48),
            chipStack.topAnchor.constraint(equalTo: contactAgentButton.bottomAnchor, constant: 12)
        ])
    }

    @objc private func contactAgentTapped() {
        openContactAgent(property: results.first)
    }

    @objc private func languageChanged() {
        selectedFilters = [:]
        rangeFilters = PropertyRangeFilters()
        rangeFilterBar.values = rangeFilters
        loadDashboardFilters()
    }

    private func loadDashboardFilters() {
        Task {
            do {
                let data = try await TenantViewModels.filterOptionsAPI()
                await MainActor.run { self.applyFilterOptions(data) }
            } catch {
                await MainActor.run {
                    self.applyFilterOptions(
                        FilterOptionsData(
                            language: LanguageManager.shared.currentLanguage,
                            listingTypes: [],
                            propertyTypes: [],
                            furnishedStatuses: [],
                            amenities: []
                        )
                    )
                }
            }
        }
    }

    private func applyFilterOptions(_ data: FilterOptionsData) {
        filterGroups = data.dashboardGroups
        let validKinds = Set(filterGroups.map(\.kind))
        selectedFilters = selectedFilters.reduce(into: [:]) { result, entry in
            let (kind, chips) = entry
            guard validKinds.contains(kind),
                  let group = filterGroups.first(where: { $0.kind == kind }) else { return }
            let kept = chips.filter { chip in
                group.options.contains { $0.value.caseInsensitiveCompare(chip.value) == .orderedSame }
            }
            if !kept.isEmpty {
                result[kind] = kept
            }
        }
        selectedFilters = filterGroups.selectedFiltersKeepingFirst(selectedFilters)
        quickSearchStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, group) in filterGroups.enumerated() {
            quickSearchStack.addArrangedSubview(makeKeyButton(group, index: index))
        }
        reloadProperties()
    }

    private func makeKeyButton(_ group: DashboardFilterGroup, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = index
        button.accessibilityIdentifier = group.key
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        if group.kind == .amenity {
            button.addTarget(self, action: #selector(amenityFilterTapped(_:)), for: .touchUpInside)
        } else {
            button.showsMenuAsPrimaryAction = true
            button.menu = UIMenu(children: [
                UIDeferredMenuElement.uncached { [weak self] completion in
                    guard let self, self.filterGroups.indices.contains(index) else {
                        completion([])
                        return
                    }
                    completion(self.menuActions(for: self.filterGroups[index]))
                }
            ])
        }
        applyKeyAppearance(button, group: group)
        return button
    }

    @objc private func amenityFilterTapped(_ sender: UIButton) {
        guard filterGroups.indices.contains(sender.tag) else { return }
        let group = filterGroups[sender.tag]
        guard group.kind == .amenity else { return }
        FilterListPickerVC.present(
            from: self,
            group: group,
            selected: selectedFilters[.amenity] ?? []
        ) { [weak self] chips in
            guard let self else { return }
            if chips.isEmpty {
                self.selectedFilters.removeValue(forKey: .amenity)
            } else {
                self.selectedFilters[.amenity] = chips
            }
            self.refreshKeyButtons()
            self.reloadProperties()
        }
    }

    private func menuActions(for group: DashboardFilterGroup) -> [UIMenuElement] {
        let selected = selectedFilters[group.kind] ?? []
        let allowsMultiple = group.kind == .amenity
        var actions: [UIMenuElement] = [
            UIAction(
                title: "Any".localized,
                attributes: allowsMultiple ? .keepsMenuPresented : [],
                state: selected.isEmpty ? .on : .off
            ) { [weak self] _ in
                self?.select(nil, in: group)
            }
        ]
        for option in group.options {
            let isOn = selected.contains {
                $0.value.caseInsensitiveCompare(option.value) == .orderedSame
            }
            actions.append(
                UIAction(
                    title: option.label,
                    attributes: allowsMultiple ? .keepsMenuPresented : [],
                    state: isOn ? .on : .off
                ) { [weak self] _ in
                    self?.select(option, in: group, toggleOff: isOn)
                }
            )
        }
        return actions
    }

    private func select(_ option: DashboardFilterChip?, in group: DashboardFilterGroup, toggleOff: Bool = false) {
        if group.kind == .amenity {
            var current = selectedFilters[.amenity] ?? []
            if let option {
                if toggleOff {
                    current.removeAll {
                        $0.value.caseInsensitiveCompare(option.value) == .orderedSame
                    }
                } else if !current.contains(where: {
                    $0.value.caseInsensitiveCompare(option.value) == .orderedSame
                }) {
                    current.append(option)
                }
                if current.isEmpty {
                    selectedFilters.removeValue(forKey: .amenity)
                } else {
                    selectedFilters[.amenity] = current
                }
            } else {
                selectedFilters.removeValue(forKey: .amenity)
            }
        } else if let option {
            selectedFilters[group.kind] = [option]
        } else {
            selectedFilters.removeValue(forKey: group.kind)
        }
        refreshKeyButtons()
        reloadProperties()
    }

    private func applyKeyAppearance(_ button: UIButton, group: DashboardFilterGroup) {
        
        var config = UIButton.Configuration.plain()
       
        config.title = {
            let chips = selectedFilters[group.kind] ?? []
            if chips.isEmpty || group.kind == .amenity { return group.kind.displayTitle }
            return chips.map(\.label).joined(separator: ", ")
        }()
        
        config.image = UIImage(systemName: "chevron.down")
       
        config.imagePlacement = .trailing
       
        config.imagePadding = 6
        
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 12)
       
        config.baseForegroundColor = .darkThemeColor
        config.background.backgroundColor = .white
        config.background.strokeColor = UIColor.accentThemeColor
        config.background.strokeWidth = 1
       
        config.background.cornerRadius = 18
       
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var next = incoming
            next.font = .systemFont(ofSize: 13, weight: .semibold)
            return next
        }
        config.imageColorTransformer = UIConfigurationColorTransformer { _ in
            .darkThemeColor
        }
        button.configuration = config
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
    }

    private func refreshKeyButtons() {
        quickSearchStack.arrangedSubviews
            .compactMap { $0 as? UIButton }
            .forEach { button in
                guard filterGroups.indices.contains(button.tag) else { return }
                let group = filterGroups[button.tag]
                applyKeyAppearance(button, group: group)
        }
    }

    private func applyPendingCriteria(_ pending: PropertySearchCriteria) {
        criteria = pending
        if pending.keyword.isEmpty {
            keywordField.text = pending.location
        } else {
            keywordField.text = pending.keyword
        }
        selectedFilters = [:]

        if let listing = pending.listingType {
            let listingValue = listing.apiListingType
            if let chip = matchChip(kind: .listingType, value: listingValue, label: listing) {
                selectedFilters[.listingType] = [chip]
            }
        }
        if let type = pending.propertyType {
            let typeValue = type.apiPropertyType
            if let chip = matchChip(kind: .propertyType, value: typeValue, label: type) {
                selectedFilters[.propertyType] = [chip]
            }
        }
        if let furnished = pending.furnished {
            let value = furnished ? "FURNISHED" : "UNFURNISHED"
            let label = furnished ? "Furnished" : "Unfurnished"
            if let chip = matchChip(kind: .furnished, value: value, label: label) {
                selectedFilters[.furnished] = [chip]
            }
        }
        let amenityChips = pending.amenities.compactMap { amenity in
            matchChip(kind: .amenity, value: amenity, label: amenity)
        }
        if !amenityChips.isEmpty {
            selectedFilters[.amenity] = amenityChips
        }
        selectedFilters = filterGroups.selectedFiltersKeepingFirst(selectedFilters)
        rangeFilters = PropertyRangeFilters(
            bedrooms: pending.minBedrooms,
            bathrooms: pending.minBathrooms,
            minPrice: pending.minPrice,
            maxPrice: pending.maxPrice,
            minSize: pending.minArea,
            maxSize: pending.maxArea
        )
        rangeFilterBar.values = rangeFilters

        refreshKeyButtons()
        reloadProperties()
    }

    private func matchChip(kind: DashboardFilterKind, value: String, label: String) -> DashboardFilterChip? {
        guard let group = filterGroups.first(where: { $0.kind == kind }) else { return nil }
        for option in group.options {
            if option.value.caseInsensitiveCompare(value) == .orderedSame
                || option.label.caseInsensitiveCompare(label) == .orderedSame {
                return option
            }
            if chipMatchesNormalized(option, kind: kind, value: value) {
                return option
            }
        }
        return nil
    }

    private func chipMatchesNormalized(
        _ option: DashboardFilterChip,
        kind: DashboardFilterKind,
        value: String
    ) -> Bool {
        switch kind {
        case .listingType:
            return option.value.apiListingType.caseInsensitiveCompare(value) == .orderedSame
        case .propertyType:
            return option.value.apiPropertyType.caseInsensitiveCompare(value) == .orderedSame
        case .furnished:
            return option.value.apiFurnishedStatus.caseInsensitiveCompare(value) == .orderedSame
        case .amenity:
            return false
        }
    }

    private func currentFilterRequest() -> PropertyFilterRequest {
        var request = PropertyFilterRequest.dashboard(selections: selectedFilters.values.flatMap { $0 })
        request.apply(criteria)
        request.apply(rangeFilters)
        let keyword = keywordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if request.location == nil, keyword.isEmpty == false {
            request.location = keyword
        }
        return request
    }

    private func syncCriteriaFromFilters() {
        criteria.keyword = keywordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let listing = selectedFilters[.listingType]?.first {
            criteria.listingType = listing.value.apiListingType == "RENT" ? "Rent" : "Buy"
        }
        else {
            criteria.listingType = nil
        }
        criteria.propertyType = selectedFilters[.propertyType]?.first?.label
        if let furnished = selectedFilters[.furnished]?.first {
            let status = furnished.value.apiFurnishedStatus
            switch status {
            case "FURNISHED":
                criteria.furnished = true
            case "UNFURNISHED":
                criteria.furnished = false
            default:
                criteria.furnished = nil
            }
        } else {
            criteria.furnished = nil
        }
        let amenityLabels = (selectedFilters[.amenity] ?? []).map(\.label)
        criteria.amenities = Set(amenityLabels)
        criteria.location = nil
    }

    private func reloadProperties() {
        let token = UUID()
        searchToken = token
        let request = currentFilterRequest()
        syncCriteriaFromFilters()
        Task {
            do {
                let items = try await TenantViewModels.searchPropertiesAPI(request)
                await MainActor.run {
                    guard self.searchToken == token else { return }
                    PropertyStore.shared.mergeRemote(items)
                    self.allResults = items
                    self.applyKeywordFilter()
                }
            }
            catch {
                await MainActor.run {
                    guard self.searchToken == token else { return }
                    PropertyStore.shared.mergeRemote(nil)
                    self.allResults = []
                    self.applyKeywordFilter()
                }
            }
        }
    }

    @objc private func keywordChanged() {
        applyKeywordFilter()
    }

    private func applyKeywordFilter() {
        let keyword = keywordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        criteria.keyword = keyword
        results = keyword.isEmpty ? allResults : allResults.filter { $0.matchesKeyword(keyword) }
        countLabel.text = "%d properties".localized(results.count)
        emptyLabel.isHidden = !results.isEmpty
        collectionView.reloadData()
    }

    @IBAction func aiSearchTapped(_ sender: Any) {
        openAISearch()
    }

    @IBAction func listingTapped(_ sender: UIButton) {}

    @IBAction func filtersTapped(_ sender: Any) {}

    @IBAction func sortTapped(_ sender: Any) {}

    @IBAction func saveSearchTapped(_ sender: Any) {
        syncCriteriaFromFilters()
        PropertyStore.shared.saveSearch(from: criteria)
        let alert = UIAlertController(
            title: "Search Saved".localized,
            message: "Find it on the Saved tab to edit preferences and alerts.".localized,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
        present(alert, animated: true)
    }
}

extension TenantSearchVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        applyKeywordFilter()
        return true
    }
}

extension TenantSearchVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        results.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PropertyCardCell.identifier,
            for: indexPath
        )
            as? PropertyCardCell else {
            return UICollectionViewCell()
        }
        
        let property = results[indexPath.item]
       
        cell.configure(with: property, isFavorite: PropertyStore.shared.isFavorite(property.id) || property.isFav)
        cell.onFavorite = { [weak self] in
            self?.toggleFavoriteRemote(propertyId: property.id) { _ in
                self?.collectionView.reloadItems(at: [indexPath])
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        openPropertyDetails(results[indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 32
        return CGSize(
            width: width,
            height: PropertyCardCell.height(forTitle: results[indexPath.item].title, width: width)
        )
    }
    
}
