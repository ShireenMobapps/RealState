//
//  AgentSearchVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class AgentSearchVC: UIViewController {

    @IBOutlet weak var keywordField: CustomTextField!
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var rentButton: UIButton!
    @IBOutlet weak var filtersButton: UIButton!
    @IBOutlet weak var sortButton: UIButton!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var saveClientButton: UIButton!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var sourceStack: UIStackView!
    @IBOutlet weak var collectionView: UICollectionView!

    private var criteria = PropertySearchCriteria()
    private var allResults: [PropertyItem] = []
    private var results: [PropertyItem] = []
    private var filterGroups: [DashboardFilterGroup] = []
    private var selectedFilters: [DashboardFilterKind: [DashboardFilterChip]] = [:]
    private var rangeFilters = PropertyRangeFilters()
    private var searchToken = UUID()
    private let filterBar = UIScrollView()
    private let quickSearchStack = UIStackView()
    private let rangeFilterBar = RangeFilterChipBar()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .screenBackgroundColor
        keywordField.delegate = self
        keywordField.placeholder = "Location or keyword".localized
        keywordField.addTarget(self, action: #selector(keywordChanged), for: .editingChanged)
        CommonMethods.styleTextField(keywordField)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PropertyCardCell.nib, forCellWithReuseIdentifier: PropertyCardCell.identifier)
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 24, right: 16)
        collectionView.keyboardDismissMode = .onDrag
        saveClientButton.isHidden = true
        hideLegacyPortalUI()
        installDashboardFilterBar()
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
        applyActiveClientBrief()
        saveClientButton.isHidden = true
        collectionView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func hideLegacyPortalUI() {
        sourceStack.isHidden = true
        sourceStack.superview?.isHidden = true
        if let portalsLabel = view.subviews.first(where: {
            ($0 as? UILabel)?.text?.localizedCaseInsensitiveContains("Portal") == true
        }) {
            portalsLabel.isHidden = true
        }
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

        view.constraints
            .filter {
                ($0.firstItem as? UIView) === chipStack && $0.firstAttribute == .top
                    || ($0.secondItem as? UIView) === chipStack && $0.secondAttribute == .top
            }
            .forEach { $0.isActive = false }

        NSLayoutConstraint.activate([
            filterBar.heightAnchor.constraint(equalToConstant: 36),
            quickSearchStack.leadingAnchor.constraint(equalTo: filterBar.contentLayoutGuide.leadingAnchor),
            quickSearchStack.trailingAnchor.constraint(equalTo: filterBar.contentLayoutGuide.trailingAnchor),
            quickSearchStack.topAnchor.constraint(equalTo: filterBar.contentLayoutGuide.topAnchor),
            quickSearchStack.bottomAnchor.constraint(equalTo: filterBar.contentLayoutGuide.bottomAnchor),
            quickSearchStack.heightAnchor.constraint(equalTo: filterBar.frameLayoutGuide.heightAnchor),
            chipStack.topAnchor.constraint(equalTo: keywordField.bottomAnchor, constant: 12)
        ])
    }

    private func applyActiveClientBrief() {
        guard let request = RealtorDesk.shared.activeRequest else { return }
        let requirement = request.requirement
        if (keywordField.text ?? "").isEmpty {
            keywordField.text = requirement.query.isEmpty ? requirement.location : requirement.query
        }
        if selectedFilters[.listingType] == nil, let purpose = requirement.purpose {
            if let chip = matchChip(kind: .listingType, value: purpose.apiListingType, label: purpose) {
                selectedFilters[.listingType] = [chip]
            }
        }
        if selectedFilters[.propertyType] == nil, let type = requirement.propertyType {
            if let chip = matchChip(kind: .propertyType, value: type.apiPropertyType, label: type) {
                selectedFilters[.propertyType] = [chip]
            }
        }
        if selectedFilters[.furnished] == nil, let furnished = requirement.furnished {
            let value = furnished ? "FURNISHED" : "UNFURNISHED"
            let label = furnished ? "Furnished" : "Unfurnished"
            if let chip = matchChip(kind: .furnished, value: value, label: label) {
                selectedFilters[.furnished] = [chip]
            }
        }
        selectedFilters = filterGroups.selectedFiltersKeepingFirst(selectedFilters)
        if rangeFilters.bedrooms == nil { rangeFilters.bedrooms = requirement.bedrooms }
        if rangeFilters.bathrooms == nil { rangeFilters.bathrooms = requirement.bathrooms }
        if rangeFilters.maxPrice == nil { rangeFilters.maxPrice = requirement.budgetMax }
        rangeFilterBar.values = rangeFilters
        refreshKeyButtons()
        reloadProperties()
    }

    @objc private func languageChanged() {
        selectedFilters = [:]
        rangeFilters = PropertyRangeFilters()
        rangeFilterBar.values = rangeFilters
        keywordField.placeholder = "Location or keyword".localized
        saveClientButton.setTitle("Save for client".localized, for: .normal)
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

    private func matchChip(kind: DashboardFilterKind, value: String, label: String) -> DashboardFilterChip? {
        guard let group = filterGroups.first(where: { $0.kind == kind }) else { return nil }
        for option in group.options {
            if option.value.caseInsensitiveCompare(value) == .orderedSame
                || option.label.caseInsensitiveCompare(label) == .orderedSame {
                return option
            }
            switch kind {
            case .listingType:
                if option.value.apiListingType.caseInsensitiveCompare(value) == .orderedSame {
                    return option
                }
            case .propertyType:
                if option.value.apiPropertyType.caseInsensitiveCompare(value) == .orderedSame {
                    return option
                }
            case .furnished:
                if option.value.apiFurnishedStatus.caseInsensitiveCompare(value) == .orderedSame {
                    return option
                }
            case .amenity:
                break
            }
        }
        return nil
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
        } else {
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
        criteria.amenities = Set((selectedFilters[.amenity] ?? []).map(\.label))
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
            } catch {
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

    @IBAction func saveForClientTapped(_ sender: Any) {
        syncCriteriaFromFilters()
        let query = keywordField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? [criteria.listingType, criteria.location, criteria.propertyType].compactMap { $0 }.joined(separator: " ")
        let alert = UIAlertController(
            title: "Save client search".localized,
            message: "Store this brief under a client name.".localized,
            preferredStyle: .alert
        )
        alert.addTextField { $0.placeholder = "Client name".localized }
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "Save".localized, style: .default) { [weak self] _ in
            let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !name.isEmpty else { return }
            AgentStore.shared.addClientSearch(
                client: name,
                query: query.isEmpty ? "Filtered inventory search".localized : query
            )
            self?.presentSimpleAlert(
                title: "Saved".localized,
                message: "Find it on the Workspace tab under Clients.".localized
            )
        })
        present(alert, animated: true)
    }

    private func presentSimpleAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
        present(alert, animated: true)
    }
}

extension AgentSearchVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        applyKeywordFilter()
        return true
    }
}

extension AgentSearchVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        results.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PropertyCardCell.identifier,
            for: indexPath
        ) as? PropertyCardCell else {
            return UICollectionViewCell()
        }
        let property = results[indexPath.item]
        cell.configure(
            with: property,
            isFavorite: AgentStore.shared.isFavorite(property.id) || property.isFav,
            showsSource: true
        )
        cell.onFavorite = { [weak self] in
            self?.toggleAgentWorkingSet(property) {
                guard let self else { return }
                let isOn = AgentStore.shared.isFavorite(property.id)
                if let index = self.allResults.firstIndex(where: { $0.id == property.id }) {
                    self.allResults[index].isFav = isOn
                }
                if let index = self.results.firstIndex(where: { $0.id == property.id }) {
                    self.results[index].isFav = isOn
                }
                if let reloadIndex = self.results.firstIndex(where: { $0.id == property.id }) {
                    self.collectionView.reloadItems(at: [IndexPath(item: reloadIndex, section: 0)])
                } else {
                    self.collectionView.reloadData()
                }
            }
        }
        cell.onTap = { [weak self] in
            self?.openPropertyDetails(property)
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
