//
//  AgentHomeVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class AgentHomeVC: UIViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var agencyLabel: UILabel!
    var agencyId: String = ""
    @IBOutlet weak var bellButton: UIButton!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var metricsLabel: UILabel!
    @IBOutlet weak var quickSearchCardView: CustomView!
    @IBOutlet weak var compareCardView: CustomView!
    @IBOutlet weak var marketingCardView: CustomView!
    @IBOutlet weak var reportCardView: CustomView!
    @IBOutlet weak var leadsCardView: CustomView!
    @IBOutlet weak var recentHost: UIStackView!
    @IBOutlet weak var savedTitleLabel: UILabel!
    @IBOutlet weak var savedCollection: UICollectionView!
    @IBOutlet weak var savedTitleHeight: NSLayoutConstraint!
    @IBOutlet weak var savedCollectionHeight: NSLayoutConstraint!
    @IBOutlet weak var savedCollectionTop: NSLayoutConstraint!
    @IBOutlet weak var recommendedAfterSaved: NSLayoutConstraint!
    @IBOutlet weak var recommendedCollection: UICollectionView!
    @IBOutlet weak var recommendedTitleLabel: UILabel?
    @IBOutlet weak var clientHost: UIStackView!

    private var saved: [PropertyItem] = []
    private var recommended: [PropertyItem] = []
    private let recommendedEmptyLabel = UILabel()
    private var recentAIItems: [AISearchHistoryItem] = []
    private var filterGroups: [DashboardFilterGroup] = []
    private var selectedFilters: [DashboardFilterKind: [DashboardFilterChip]] = [:]
    private var rangeFilters = PropertyRangeFilters()
    private var searchToken = UUID()
    private let filterBar = UIScrollView()
    private let quickSearchStack = UIStackView()
    private let rangeFilterBar = RangeFilterChipBar()
    private let agencyBannerSlider = AgencyBannerSlider()
    private var quickActionsTopToBanner: NSLayoutConstraint?
    private let quickSearchViewAllButton = UIButton(type: .system)
    private var filterBarHeightConstraint: NSLayoutConstraint?
    private let recommendedHomeLimit = 3
    private weak var recentTitleLabel: UILabel?
    private var recentTitleHeightConstraint: NSLayoutConstraint?
    private var recentTitleTopConstraint: NSLayoutConstraint?
    private var recentScrollHeightConstraint: NSLayoutConstraint?
    private var recentScrollTopConstraint: NSLayoutConstraint?
    private var metricsHeightConstraint: NSLayoutConstraint?
    private weak var clientTitleLabel: UILabel?
    private let recentAIHeader = UIView()
    private let recentAITitleLabel = UILabel()
    private let recentAISubtitleLabel = UILabel()
    private let recentAIViewAllButton = UIButton(type: .system)
    private let recentAIEmptyLabel = UILabel()
    private let recentAITable: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.isScrollEnabled = false
        table.alwaysBounceVertical = false
        table.bounces = false
        table.showsVerticalScrollIndicator = false
        table.rowHeight = AISearchQueryCell.rowHeight
        return table
    }()
    private var recentAIHeightConstraint: NSLayoutConstraint?
    private var recentAIToken = UUID()
    private var didInstallRecentAI = false
    private let recentAIHomeLimit = 2
    private var recentlyViewed: [PropertyItem] = []
    private var recentlyViewedToken = UUID()
    private var didInstallRecentlyViewed = false
    private let recentlyViewedHomeLimit = 3
    private let recentlyViewedHeader = UIView()
    private let recentlyViewedTitleLabel = UILabel()
    private let recentlyViewedViewAllButton = UIButton(type: .system)
    private let recentlyViewedEmptyLabel = UILabel()
    private let recentlyViewedCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = false
        collection.showsVerticalScrollIndicator = false
        collection.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        return collection
    }()
    private var recentlyViewedHeightConstraint: NSLayoutConstraint?
    private var recentlyViewedHeaderHeightConstraint: NSLayoutConstraint?
    private var recentlyViewedHeaderTopConstraint: NSLayoutConstraint?
    private var recentlyViewedCollectionTopConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        applyStyle()
        setupCollections()
        installQuickSearchEmptyLabel()
        installQuickSearchBar()
        installAgencyBannerSlider()
        installRecentlyViewedSection()
        installRecentAISearchSection()
        applyProfile(nil)
        showAgentProfile()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: LanguageManager.didChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(tabBecameSelected(_:)),
            name: AgentTabBarController.didChangeTab,
            object: nil
        )
        loadDashboardFilters()
        reloadProperties()
        hideAgentHomeExtras()
        loadRecentlyViewed()
        loadRecentAISearch()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        agencyBannerSlider.startAutoScroll()
        reloadDashboardChrome()
        showAgentProfile()
        loadRecentlyViewed()
        loadRecentAISearch()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        agencyBannerSlider.stopAutoScroll()
    }

    @objc private func tabBecameSelected(_ notification: Notification) {
        guard navigationController?.topViewController === self,
              tabBarController?.selectedViewController === navigationController else { return }
        refreshHomePage()
    }

    private func refreshHomePage() {
        selectedFilters = [:]
        rangeFilters = PropertyRangeFilters()
        rangeFilterBar.values = rangeFilters
        reloadDashboardChrome()
        showAgentProfile()
        loadDashboardFilters()
        loadRecentlyViewed()
        loadRecentAISearch()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        profileImageView.layer.masksToBounds = true
        CommonMethods.styleDashboardProfilePhoto(profileImageView)
        recommendedCollection.collectionViewLayout.invalidateLayout()
        recentlyViewedCollection.collectionViewLayout.invalidateLayout()
    }

    private func applyStyle() {
        view.backgroundColor = .screenBackgroundColor
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        agencyLabel.font = .systemFont(ofSize: 17, weight: .medium)
        agencyLabel.textColor = UIColor(red: 73/255, green: 80/255, blue: 87/255, alpha: 1)
        agencyLabel.numberOfLines = 2
        [quickSearchCardView, compareCardView, leadsCardView].forEach {
            if let card = $0 { CommonMethods.styleFormCard(card) }
        }
        marketingCardView.isHidden = true
        marketingCardView.isUserInteractionEnabled = false
        reportCardView.isHidden = true
        reportCardView.isUserInteractionEnabled = false
        CommonMethods.styleHomeNotificationBell(bellButton)
        badgeLabel.font = .systemFont(ofSize: 10, weight: .bold)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center
        badgeLabel.backgroundColor = UIColor(red: 220/255, green: 53/255, blue: 69/255, alpha: 1)
        badgeLabel.clipsToBounds = true
        badgeLabel.layer.cornerRadius = 9
        badgeLabel.layer.borderWidth = 1.5
        badgeLabel.layer.borderColor = UIColor.white.cgColor
        badgeLabel.isHidden = true
        badgeLabel.superview?.bringSubviewToFront(badgeLabel)
        recommendedTitleLabel?.text = "Quick Search".localized
    }

    private func showAgentProfile() {
        Task {
            do {
                let res = try await AuthViewModel.profileAPI()
                await MainActor.run { self.applyProfile(res.resolvedUser) }
            } catch {
                await MainActor.run { self.applyProfile(nil) }
            }
        }
    }

    private func applyProfile(_ user: User?) {
        if let user {
            AgentAccount.shared.apply(user: user)
        }
        agencyId = user?.agencyId?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? AgentAccount.shared.agencyId
       
        nameLabel.text = user?.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "--"
        let agency = (user?.agencyName ?? AgentAccount.shared.agency)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        agencyLabel.text = agency.isEmpty ? "--" : agency
        profileImageView.setMediaProfileImage(
            user?.profileImage,
            placeholder: UIImage(named: "profile")
        )
    }

    private func setupCollections() {
        recommendedCollection.register(PropertyCardCell.nib, forCellWithReuseIdentifier: PropertyCardCell.identifier)
        recommendedCollection.dataSource = self
        recommendedCollection.delegate = self
        recommendedCollection.showsHorizontalScrollIndicator = false
        recommendedCollection.backgroundColor = .clear
        if let layout = recommendedCollection.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 12
        }
    }

    private func installQuickSearchEmptyLabel() {
        recommendedEmptyLabel.translatesAutoresizingMaskIntoConstraints = false
        recommendedEmptyLabel.text = "No data found".localized
        recommendedEmptyLabel.textAlignment = .center
        recommendedEmptyLabel.numberOfLines = 0
        recommendedEmptyLabel.font = .systemFont(ofSize: 15, weight: .medium)
        recommendedEmptyLabel.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)
        recommendedEmptyLabel.isHidden = true
        guard let parent = recommendedCollection.superview else { return }
        parent.addSubview(recommendedEmptyLabel)
        NSLayoutConstraint.activate([
            recommendedEmptyLabel.centerXAnchor.constraint(equalTo: recommendedCollection.centerXAnchor),
            recommendedEmptyLabel.centerYAnchor.constraint(equalTo: recommendedCollection.centerYAnchor),
            recommendedEmptyLabel.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 32),
            recommendedEmptyLabel.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -32)
        ])
        updateQuickSearchEmptyState()
    }

    private func updateQuickSearchEmptyState() {
        let isEmpty = recommended.isEmpty
        recommendedEmptyLabel.text = "No data found".localized
        recommendedEmptyLabel.isHidden = !isEmpty
        recommendedCollection.isHidden = isEmpty
        quickSearchViewAllButton.isHidden = recommended.count <= recommendedHomeLimit
        recommendedCollection.superview?.bringSubviewToFront(quickSearchViewAllButton)
    }

    private func reloadDashboardChrome() {
        saved = AgentStore.shared.favoriteProperties()
        recommendedTitleLabel?.text = "Quick Search".localized
        hideAgentHomeExtras()
        recommendedCollection.reloadData()
        updateQuickSearchEmptyState()
        updateRecentAISearchSection()
        updateRecentlyViewedSection()
        refreshNotificationBadge() // api
    }

    private func refreshNotificationBadge() {
        Task {
            do {
                let response = try await AuthViewModel.notificationCountAPI()
                await MainActor.run {
                    NotificationUnreadStore.shared.apply(response: response)
                    self.applyNotificationBadge(NotificationUnreadStore.shared.count)
                }
            }
            catch {
                await MainActor.run {
                    self.badgeLabel.isHidden = true
                }
            }
        }
    }

    private func applyNotificationBadge(_ unread: Int) {
        badgeLabel.isHidden = unread <= 0
        guard unread > 0 else { return }
        badgeLabel.text = unread > 9 ? "9+" : "\(unread)"
    }

    private func installAgencyBannerSlider() {
        guard agencyBannerSlider.superview == nil,
              let parent = metricsLabel.superview else { return }
        let quickActionsTitle = parent.constraints.compactMap { constraint -> UILabel? in
            guard constraint.firstAttribute == .top,
                  let label = constraint.firstItem as? UILabel,
                  (constraint.secondItem as? UIView) === metricsLabel else { return nil }
            return label
        }.first
        guard let quickActionsTitle else { return }

        parent.insertSubview(agencyBannerSlider, belowSubview: quickActionsTitle)

        for constraint in parent.constraints {
            let first = constraint.firstItem as? UIView
            let second = constraint.secondItem as? UIView
            guard constraint.firstAttribute == .top, first === quickActionsTitle else { continue }
            constraint.isActive = false
            if let second {
                agencyBannerSlider.topAnchor.constraint(equalTo: second.bottomAnchor, constant: constraint.constant).isActive = true
            }
        }

        let gap = quickActionsTitle.topAnchor.constraint(equalTo: agencyBannerSlider.bottomAnchor, constant: 0)
        quickActionsTopToBanner = gap
        agencyBannerSlider.onVisibilityChange = { [weak self] visible in
            self?.quickActionsTopToBanner?.constant = visible ? 12 : 0
            self?.view.layoutIfNeeded()
        }
        NSLayoutConstraint.activate([
            agencyBannerSlider.leadingAnchor.constraint(equalTo: metricsLabel.leadingAnchor),
            agencyBannerSlider.trailingAnchor.constraint(equalTo: metricsLabel.trailingAnchor),
            gap
        ])
        agencyBannerSlider.load()
    }

    private func installQuickSearchBar(){
        guard filterBar.superview == nil,
              let content = recommendedCollection.superview,
              let title = recommendedTitleLabel ?? content.subviews.compactMap({ $0 as? UILabel }).first(where: {
                  $0.text == "Recommended Properties"
                      || $0.text == "Inventory by source"
                      || $0.text == "Quick Search"
              }) else { return }

        filterBar.translatesAutoresizingMaskIntoConstraints = false
        filterBar.showsHorizontalScrollIndicator = false
        filterBar.showsVerticalScrollIndicator = false
        quickSearchStack.translatesAutoresizingMaskIntoConstraints = false
        quickSearchStack.axis = .horizontal
        quickSearchStack.spacing = 8
        quickSearchStack.alignment = .center
        filterBar.addSubview(quickSearchStack)
        content.addSubview(filterBar)

        rangeFilterBar.host = self
        rangeFilterBar.horizontalInset = 20
        rangeFilterBar.onChanged = { [weak self] values in
            self?.rangeFilters = values
            self?.reloadProperties()
        }
        rangeFilterBar.translatesAutoresizingMaskIntoConstraints = false
        filterBar.addSubview(rangeFilterBar)

        quickSearchViewAllButton.translatesAutoresizingMaskIntoConstraints = false
        quickSearchViewAllButton.setTitle("View All".localized, for: .normal)
        quickSearchViewAllButton.setTitleColor(.darkThemeColor, for: .normal)
        quickSearchViewAllButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        quickSearchViewAllButton.isHidden = true
        quickSearchViewAllButton.setContentHuggingPriority(.required, for: .horizontal)
        quickSearchViewAllButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        quickSearchViewAllButton.addTarget(self, action: #selector(quickSearchViewAllTapped), for: .touchUpInside)
        content.addSubview(quickSearchViewAllButton)
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        content.constraints
            .filter { ($0.firstItem as? UIView) === recommendedCollection && $0.firstAttribute == .top }
            .forEach { $0.isActive = false }

        let height = filterBar.heightAnchor.constraint(equalToConstant: 82)
        filterBarHeightConstraint = height

        NSLayoutConstraint.activate([
            filterBar.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            filterBar.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            filterBar.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            height,
            recommendedCollection.topAnchor.constraint(equalTo: filterBar.bottomAnchor, constant: 8),
            quickSearchStack.leadingAnchor.constraint(equalTo: filterBar.contentLayoutGuide.leadingAnchor, constant: 20),
            quickSearchStack.trailingAnchor.constraint(equalTo: filterBar.contentLayoutGuide.trailingAnchor, constant: -20),
            quickSearchStack.topAnchor.constraint(equalTo: filterBar.contentLayoutGuide.topAnchor),
            quickSearchStack.heightAnchor.constraint(equalToConstant: 36),
            rangeFilterBar.topAnchor.constraint(equalTo: quickSearchStack.bottomAnchor, constant: 10),
            rangeFilterBar.leadingAnchor.constraint(equalTo: filterBar.contentLayoutGuide.leadingAnchor),
            rangeFilterBar.trailingAnchor.constraint(equalTo: filterBar.contentLayoutGuide.trailingAnchor),
            rangeFilterBar.bottomAnchor.constraint(equalTo: filterBar.contentLayoutGuide.bottomAnchor),
            quickSearchViewAllButton.centerYAnchor.constraint(equalTo: title.centerYAnchor),
            quickSearchViewAllButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            quickSearchViewAllButton.leadingAnchor.constraint(greaterThanOrEqualTo: title.trailingAnchor, constant: 8)
        ])
        content.bringSubviewToFront(quickSearchViewAllButton)
    }

    @objc private func quickSearchViewAllTapped() {
        tabBarController?.selectedIndex = 1
    }

    private func currentFilterRequest() -> PropertyFilterRequest {
        var request = PropertyFilterRequest.dashboard(selections: selectedFilters.values.flatMap { $0 })
        request.apply(rangeFilters)
        return request
    }

    @objc private func languageChanged() {
        selectedFilters = [:]
        rangeFilters = PropertyRangeFilters()
        rangeFilterBar.values = rangeFilters
        recommendedTitleLabel?.text = "Quick Search".localized
        quickSearchViewAllButton.setTitle("View All".localized, for: .normal)
        applyRecentAISearchCopy()
        recentlyViewedTitleLabel.text = "Recently Viewed".localized
        recentlyViewedViewAllButton.setTitle("View All".localized, for: .normal)
        recentlyViewedEmptyLabel.text = "No data found".localized
        loadDashboardFilters()
        reloadDashboardChrome()
        loadRecentlyViewed()
        loadRecentAISearch()
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
        
        filterBarHeightConstraint?.constant = 82
        filterBar.isHidden = false
        reloadProperties()
        
    }

    private func makeKeyButton(_ group: DashboardFilterGroup, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = index
        button.accessibilityIdentifier = group.key
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        if group.kind == .amenity {
            button.addTarget(self, action: #selector(amenityFilterTapped(_:)), for: .touchUpInside)
        }
        else {
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
        config.title = filterButtonTitle(for: group)
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

    private func filterButtonTitle(for group: DashboardFilterGroup) -> String {
        let chips = selectedFilters[group.kind] ?? []
        if chips.isEmpty || group.kind == .amenity { return group.kind.displayTitle }
        return chips.map(\.label).joined(separator: ", ")
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

    private func reloadProperties() {
        let token = UUID()
        searchToken = token
        let request = currentFilterRequest()
        Task {
            do {
                let items = try await TenantViewModels.searchPropertiesAPI(request)
                await MainActor.run {
                    guard self.searchToken == token else { return }
                    PropertyStore.shared.mergeRemote(items)
                    self.recommended = items
                    self.recommendedCollection.reloadData()
                    self.reloadDashboardChrome()
                }
            } catch {
                await MainActor.run {
                    guard self.searchToken == token else { return }
                    PropertyStore.shared.mergeRemote(nil)
                    self.recommended = []
                    self.recommendedCollection.reloadData()
                    self.reloadDashboardChrome()
                }
            }
        }
    }

    private func hideAgentHomeExtras() {
        metricsLabel.isHidden = true
        metricsLabel.text = nil
        if metricsHeightConstraint == nil {
            let height = metricsLabel.heightAnchor.constraint(equalToConstant: 0)
            height.priority = .required
            height.isActive = true
            metricsHeightConstraint = height
        }
        metricsHeightConstraint?.constant = 0
        metricsLabel.superview?.constraints.first {
            $0.firstItem === metricsLabel && $0.firstAttribute == .top
        }?.constant = 0

        savedTitleLabel.isHidden = true
        savedCollection.isHidden = true
        savedCollection.isUserInteractionEnabled = false
        savedTitleHeight.constant = 0
        savedCollectionHeight.constant = 0
        savedCollectionTop.constant = 0

        guard let scroll = recentHost.superview, let parent = scroll.superview else { return }
        scroll.isHidden = true
        recentHost.isHidden = true

        if recentTitleLabel == nil {
            recentTitleLabel = parent.constraints.compactMap { constraint -> UILabel? in
                if constraint.firstItem === scroll { return constraint.secondItem as? UILabel }
                if constraint.secondItem === scroll { return constraint.firstItem as? UILabel }
                return nil
            }.first
        }
        recentTitleLabel?.isHidden = true

        if recentScrollHeightConstraint == nil {
            recentScrollHeightConstraint = scroll.constraints.first {
                $0.firstAttribute == .height && $0.secondItem == nil
            }
        }
        recentScrollHeightConstraint?.constant = 0

        if recentTitleHeightConstraint == nil, let title = recentTitleLabel {
            let height = title.heightAnchor.constraint(equalToConstant: 0)
            height.priority = .required
            height.isActive = true
            recentTitleHeightConstraint = height
        }
        recentTitleHeightConstraint?.constant = 0

        if recentTitleTopConstraint == nil, let title = recentTitleLabel {
            recentTitleTopConstraint = parent.constraints.first {
                $0.firstItem === title && $0.firstAttribute == .top
            }
        }
        recentTitleTopConstraint?.constant = 0

        if recentScrollTopConstraint == nil, let title = recentTitleLabel {
            recentScrollTopConstraint = parent.constraints.first {
                ($0.firstItem === scroll && $0.secondItem === title)
                    || ($0.firstItem === title && $0.secondItem === scroll)
            }
        }
        recentScrollTopConstraint?.constant = 0

        parent.constraints.first {
            ($0.firstItem === savedTitleLabel && $0.secondItem === scroll)
                || ($0.firstItem === scroll && $0.secondItem === savedTitleLabel)
        }?.constant = 0
    }

    private func installRecentlyViewedSection() {
        guard !didInstallRecentlyViewed, let parent = recommendedCollection.superview else { return }
        didInstallRecentlyViewed = true

        recentlyViewedTitleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        recentlyViewedTitleLabel.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
        recentlyViewedTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        recentlyViewedTitleLabel.text = "Recently Viewed".localized

        recentlyViewedViewAllButton.setTitle("View All".localized, for: .normal)
        recentlyViewedViewAllButton.setTitleColor(.darkThemeColor, for: .normal)
        recentlyViewedViewAllButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        recentlyViewedViewAllButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        recentlyViewedViewAllButton.addTarget(self, action: #selector(recentlyViewedViewAllTapped), for: .touchUpInside)

        recentlyViewedHeader.translatesAutoresizingMaskIntoConstraints = false
        recentlyViewedTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        recentlyViewedViewAllButton.translatesAutoresizingMaskIntoConstraints = false
        recentlyViewedHeader.addSubview(recentlyViewedTitleLabel)
        recentlyViewedHeader.addSubview(recentlyViewedViewAllButton)
        NSLayoutConstraint.activate([
            recentlyViewedTitleLabel.leadingAnchor.constraint(equalTo: recentlyViewedHeader.leadingAnchor),
            recentlyViewedTitleLabel.centerYAnchor.constraint(equalTo: recentlyViewedHeader.centerYAnchor),
            recentlyViewedViewAllButton.leadingAnchor.constraint(greaterThanOrEqualTo: recentlyViewedTitleLabel.trailingAnchor, constant: 8),
            recentlyViewedViewAllButton.trailingAnchor.constraint(equalTo: recentlyViewedHeader.trailingAnchor),
            recentlyViewedViewAllButton.centerYAnchor.constraint(equalTo: recentlyViewedHeader.centerYAnchor)
        ])

        recentlyViewedCollection.translatesAutoresizingMaskIntoConstraints = false
        recentlyViewedCollection.dataSource = self
        recentlyViewedCollection.delegate = self
        recentlyViewedCollection.register(PropertyCardCell.nib, forCellWithReuseIdentifier: PropertyCardCell.identifier)
        let height = recentlyViewedCollection.heightAnchor.constraint(equalToConstant: 0)
        recentlyViewedHeightConstraint = height
        let headerHeight = recentlyViewedHeader.heightAnchor.constraint(equalToConstant: 0)
        recentlyViewedHeaderHeightConstraint = headerHeight

        recentlyViewedEmptyLabel.translatesAutoresizingMaskIntoConstraints = false
        recentlyViewedEmptyLabel.text = "No data found".localized
        recentlyViewedEmptyLabel.textAlignment = .center
        recentlyViewedEmptyLabel.numberOfLines = 0
        recentlyViewedEmptyLabel.font = .systemFont(ofSize: 15, weight: .medium)
        recentlyViewedEmptyLabel.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)

        parent.addSubview(recentlyViewedHeader)
        parent.addSubview(recentlyViewedCollection)
        parent.addSubview(recentlyViewedEmptyLabel)

        for constraint in parent.constraints {
            let first = constraint.firstItem as? UIView
            let second = constraint.secondItem as? UIView
            let labelLinkedToRecommended =
                (first is UILabel && first !== recommendedTitleLabel && second === recommendedCollection && constraint.firstAttribute == .top)
                || (second is UILabel && second !== recommendedTitleLabel && first === recommendedCollection && constraint.secondAttribute == .top)
            guard labelLinkedToRecommended else { continue }
            constraint.isActive = false
            let label = (first is UILabel ? first : second) ?? clientTitleLabel
            label?.topAnchor.constraint(equalTo: recentlyViewedCollection.bottomAnchor, constant: 20).isActive = true
        }

        NSLayoutConstraint.activate([
            recentlyViewedHeader.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 20),
            recentlyViewedHeader.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -20),
            recentlyViewedHeader.topAnchor.constraint(equalTo: recommendedCollection.bottomAnchor, constant: 0),
            headerHeight,
            recentlyViewedCollection.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            recentlyViewedCollection.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            recentlyViewedCollection.topAnchor.constraint(equalTo: recentlyViewedHeader.bottomAnchor, constant: 0),
            height,
            recentlyViewedEmptyLabel.centerXAnchor.constraint(equalTo: recentlyViewedCollection.centerXAnchor),
            recentlyViewedEmptyLabel.centerYAnchor.constraint(equalTo: recentlyViewedCollection.centerYAnchor),
            recentlyViewedEmptyLabel.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 32),
            recentlyViewedEmptyLabel.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -32)
        ])
        recentlyViewedHeaderTopConstraint = parent.constraints.first {
            $0.firstItem === recentlyViewedHeader && $0.firstAttribute == .top && $0.secondItem === recommendedCollection
        }
        recentlyViewedCollectionTopConstraint = parent.constraints.first {
            $0.firstItem === recentlyViewedCollection && $0.firstAttribute == .top && $0.secondItem === recentlyViewedHeader
        }
        updateRecentlyViewedSection()
    }

    private var recommendedHomeItems: [PropertyItem] {
        Array(recommended.prefix(recommendedHomeLimit))
    }

    private var recentlyViewedHomeItems: [PropertyItem] {
        Array(recentlyViewed.prefix(recentlyViewedHomeLimit))
    }

    private func loadRecentlyViewed() {
        let token = UUID()
        recentlyViewedToken = token
        Task {
            do {
                let items = try await TenantViewModels.recentlyViewedAPI()
                await MainActor.run {
                    guard self.recentlyViewedToken == token else { return }
                    PropertyStore.shared.setRecentlyViewed(items)
                    self.recentlyViewed = items
                    self.updateRecentlyViewedSection()
                }
            } catch {
                await MainActor.run {
                    guard self.recentlyViewedToken == token else { return }
                    self.recentlyViewed = []
                    PropertyStore.shared.setRecentlyViewed([])
                    self.updateRecentlyViewedSection()
                }
            }
        }
    }

    private func updateRecentlyViewedSection() {
        recentlyViewedTitleLabel.text = "Recently Viewed".localized
        recentlyViewedViewAllButton.setTitle("View All".localized, for: .normal)
        recentlyViewedEmptyLabel.text = nil
        let isEmpty = recentlyViewed.isEmpty
        recentlyViewedHeader.isHidden = isEmpty
        recentlyViewedCollection.isHidden = isEmpty
        recentlyViewedEmptyLabel.isHidden = true
        recentlyViewedViewAllButton.isHidden = isEmpty
        recentlyViewedHeaderHeightConstraint?.constant = isEmpty ? 0 : 22
        recentlyViewedHeaderTopConstraint?.constant = isEmpty ? 0 : 20
        recentlyViewedCollectionTopConstraint?.constant = isEmpty ? 0 : 8
        recentlyViewedHeightConstraint?.constant = isEmpty ? 0 : PropertyCardCell.preferredHeight
        recentlyViewedCollection.reloadData()
    }

    @objc private func recentlyViewedViewAllTapped() {
        let vc: TenantRecentlyViewedVC = TenantStoryboard.load("TenantRecentlyViewedVC")
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    private func installRecentAISearchSection() {
        guard !didInstallRecentAI, let parent = clientHost.superview else { return }
        didInstallRecentAI = true

        clientTitleLabel = parent.constraints.compactMap { constraint -> UILabel? in
            let isTop = constraint.firstAttribute == .top || constraint.secondAttribute == .top
            guard isTop else { return nil }
            if constraint.firstItem === clientHost { return constraint.secondItem as? UILabel }
            if constraint.secondItem === clientHost { return constraint.firstItem as? UILabel }
            return nil
        }.first
        clientTitleLabel?.isHidden = true
        clientTitleLabel?.text = nil
        if let title = clientTitleLabel, title.constraints.contains(where: { $0.firstAttribute == .height }) == false {
            title.heightAnchor.constraint(equalToConstant: 0).isActive = true
        }

        recentAITitleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        recentAITitleLabel.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
        recentAITitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        recentAISubtitleLabel.numberOfLines = 0
        recentAISubtitleLabel.font = .systemFont(ofSize: 13)
        recentAISubtitleLabel.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)

        recentAIEmptyLabel.textAlignment = .center
        recentAIEmptyLabel.numberOfLines = 0
        recentAIEmptyLabel.font = .systemFont(ofSize: 15, weight: .medium)
        recentAIEmptyLabel.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)

        recentAIViewAllButton.setTitleColor(.darkThemeColor, for: .normal)
        recentAIViewAllButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        recentAIViewAllButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        recentAIViewAllButton.addTarget(self, action: #selector(recentAIViewAllTapped), for: .touchUpInside)

        recentAITitleLabel.translatesAutoresizingMaskIntoConstraints = false
        recentAIViewAllButton.translatesAutoresizingMaskIntoConstraints = false
        recentAIHeader.addSubview(recentAITitleLabel)
        recentAIHeader.addSubview(recentAIViewAllButton)
        NSLayoutConstraint.activate([
            recentAITitleLabel.leadingAnchor.constraint(equalTo: recentAIHeader.leadingAnchor),
            recentAITitleLabel.topAnchor.constraint(equalTo: recentAIHeader.topAnchor),
            recentAITitleLabel.bottomAnchor.constraint(equalTo: recentAIHeader.bottomAnchor),
            recentAIViewAllButton.leadingAnchor.constraint(greaterThanOrEqualTo: recentAITitleLabel.trailingAnchor, constant: 8),
            recentAIViewAllButton.trailingAnchor.constraint(equalTo: recentAIHeader.trailingAnchor),
            recentAIViewAllButton.centerYAnchor.constraint(equalTo: recentAIHeader.centerYAnchor)
        ])

        recentAITable.dataSource = self
        recentAITable.delegate = self
        recentAITable.register(AISearchQueryCell.self, forCellReuseIdentifier: AISearchQueryCell.identifier)
        let height = recentAITable.heightAnchor.constraint(equalToConstant: 0)
        recentAIHeightConstraint = height
        height.isActive = true

        clientHost.spacing = 8
        clientHost.addArrangedSubview(recentAIHeader)
        clientHost.addArrangedSubview(recentAISubtitleLabel)
        clientHost.addArrangedSubview(recentAITable)
        clientHost.addArrangedSubview(recentAIEmptyLabel)
        applyRecentAISearchCopy()
        updateRecentAISearchSection()
    }

    private func applyRecentAISearchCopy() {
        recentAITitleLabel.text = "Recent Searches".localized
        recentAISubtitleLabel.text = "Get recently AI search history".localized
        recentAIViewAllButton.setTitle("View All".localized, for: .normal)
        recentAIEmptyLabel.text = "No data found".localized
    }

    private func loadRecentAISearch() {
        let token = UUID()
        recentAIToken = token
        Task {
            do {
                let items = try await AgentViewModels.recentlyAISearchAPI()
                await MainActor.run {
                    guard self.recentAIToken == token else { return }
                    self.recentAIItems = items
                    self.updateRecentAISearchSection()
                }
            } catch {
                await MainActor.run {
                    guard self.recentAIToken == token else { return }
                    self.recentAIItems = []
                    self.updateRecentAISearchSection()
                }
            }
        }
    }

    private var recentAIHomeItems: [AISearchHistoryItem] {
        Array(recentAIItems.prefix(recentAIHomeLimit))
    }

    private func updateRecentAISearchSection() {
        applyRecentAISearchCopy()
        let isEmpty = recentAIItems.isEmpty
        recentAIHeader.isHidden = isEmpty
        recentAISubtitleLabel.isHidden = isEmpty
        recentAITable.isHidden = isEmpty
        recentAIEmptyLabel.isHidden = true
        recentAIEmptyLabel.text = nil
        clientHost.isHidden = isEmpty
        recentAIViewAllButton.isHidden = isEmpty || recentAIItems.count <= recentAIHomeLimit
        recentAIViewAllButton.isEnabled = recentAIItems.count > recentAIHomeLimit
        recentAITable.isScrollEnabled = false
        recentAITable.alwaysBounceVertical = false
        recentAITable.bounces = false
        recentAIHeightConstraint?.constant = isEmpty ? 0 : CGFloat(recentAIHomeItems.count) * AISearchQueryCell.rowHeight
        recentAITable.reloadData()
    }

    @objc private func recentAIViewAllTapped() {
        let vc = AgentAISearchHistoryVC()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    private func confirmDeleteRecentAI(_ item: AISearchHistoryItem) {
        CommonMethods.showConfirmationAlert(
            message: "Delete this search history?",
            confirmTitle: "Delete",
            confirmStyle: .destructive,
            from: self
        ) { [weak self] in
            self?.deleteRecentAI(item)
        }
    }

    private func deleteRecentAI(_ item: AISearchHistoryItem) {
        Task {
            do {
                try await AgentViewModels.deleteAISearchHistoryAPI(id: item.historyId)
                await MainActor.run {
                    self.recentAIItems.removeAll { $0.historyId == item.historyId }
                    self.updateRecentAISearchSection()
                }
            } catch {
                await MainActor.run {
                    let message = ((error as? APIError)?.errorDescription ?? error.localizedDescription)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    let text = message.isEmpty ? "Unable to delete search history.".localized : message
                    CommonMethods.showAlert(message: text, from: self)
                }
            }
        }
    }

    @IBAction func notificationsTapped(_ sender: Any) {
        let vc: AgentNotificationsVC = AgentStoryboard.load("AgentNotificationsVC")
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func aiSearchTapped(_ sender: Any) {
        openAISearch()
    }

    @IBAction func compareTapped(_ sender: Any) {
        AgentStore.pendingSavedSection = 2
        tabBarController?.selectedIndex = 2
    }

    @IBAction func marketingTapped(_ sender: Any) {
        let vc: AgentMarketingVC = AgentStoryboard.load("AgentMarketingVC")
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func reportTapped(_ sender: Any) {
        if let request = RealtorDesk.shared.activeRequest ?? RealtorDesk.shared.inboundRequests().first {
            let vc = AgentRecommendationReviewVC()
            vc.requestId = request.id
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        let compared = AgentStore.shared.comparedProperties()
        let listings = compared.count >= 2 ? compared : AgentStore.shared.workingSetOrInventory().prefix(3).map { $0 }
        let vc: AgentReportVC = AgentStoryboard.load("AgentReportVC")
        vc.properties = listings
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func leadsTapped(_ sender: Any) {
        let vc: AgentLeadsVC = AgentStoryboard.load("AgentLeadsVC")
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension AgentHomeVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionView === recentlyViewedCollection ? recentlyViewedHomeItems.count : recommendedHomeItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PropertyCardCell.identifier,
            for: indexPath
        ) as? PropertyCardCell else {
            return UICollectionViewCell()
        }
        let property = collectionView === recentlyViewedCollection
            ? recentlyViewedHomeItems[indexPath.item]
            : recommendedHomeItems[indexPath.item]
        let isRecentlyViewed = collectionView === recentlyViewedCollection
        cell.configure(
            with: property,
            isFavorite: AgentStore.shared.isFavorite(property.id) || property.isFav,
            showsSource: true,
            showsDelete: isRecentlyViewed
        )
        if isRecentlyViewed {
            cell.onDelete = { [weak self] in
                self?.deleteRecentlyViewedRemote(property) { success in
                    guard success else { return }
                    self?.loadRecentlyViewed()
                }
            }
        } else {
            cell.onFavorite = { [weak self] in
                self?.toggleAgentWorkingSet(property) {
                    guard let self else { return }
                    let isOn = AgentStore.shared.isFavorite(property.id)
                    if let index = self.recommended.firstIndex(where: { $0.id == property.id }) {
                        self.recommended[index].isFav = isOn
                    }
                    if let index = self.recentlyViewed.firstIndex(where: { $0.id == property.id }) {
                        self.recentlyViewed[index].isFav = isOn
                    }
                    self.recommendedCollection.reloadData()
                    self.recentlyViewedCollection.reloadData()
                }
            }
        }
        cell.onTap = { [weak self] in
            self?.openPropertyDetails(property)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let property = collectionView === recentlyViewedCollection
            ? recentlyViewedHomeItems[indexPath.item]
            : recommendedHomeItems[indexPath.item]
        openPropertyDetails(property)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 236, height: collectionView.bounds.height)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        recentAIHomeItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: AISearchQueryCell.identifier,
            for: indexPath
        ) as? AISearchQueryCell else {
            return UITableViewCell()
        }
        let item = recentAIHomeItems[indexPath.row]
        cell.configure(query: item.query)
        cell.onDelete = { [weak self] in
            self?.confirmDeleteRecentAI(item)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openAISearch(
            prefilled: recentAIHomeItems[indexPath.row].query,
            chatId: recentAIHomeItems[indexPath.row].historyId
        )
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === recentAITable else { return }
        if scrollView.contentOffset.y != 0 {
            scrollView.contentOffset.y = 0
        }
    }
}
