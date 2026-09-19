//
//  TenantHomeVC.swift
//  AIPoweredRealEstate
//

import UIKit

class TenantHomeVC: UIViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var aiSearchCardView: CustomView!
    @IBOutlet weak var quickSearchStack: UIStackView!
    @IBOutlet weak var recommendedCollection: UICollectionView!
    @IBOutlet weak var recentlyCollection: UICollectionView!

    private let contactAgentButton = CustomButton(type: .system)
    private let agencyBannerSlider = AgencyBannerSlider()
    private var aiSearchTopToBanner: NSLayoutConstraint?
    private let bellButton = UIButton(type: .system)
    private let badgeLabel = UILabel()
    private let recentlyEmptyLabel = UILabel()
    private let recommendedEmptyLabel = UILabel()
    private let recentlyViewAllButton = UIButton(type: .system)
    private let recommendedViewAllButton = UIButton(type: .system)
    private var recentlyViewAllCenterYConstraint: NSLayoutConstraint?
    private var recommendedViewAllCenterYConstraint: NSLayoutConstraint?
    private var filterGroups: [DashboardFilterGroup] = []
    private var selectedFilters: [DashboardFilterKind: [DashboardFilterChip]] = [:]
    private var rangeFilters = PropertyRangeFilters()
    private let rangeFilterBar = RangeFilterChipBar()
    private var recommended: [PropertyItem] = []
    private var recently: [PropertyItem] = []
    private var searchToken = UUID()
    private var recentlyToken = UUID()
    private weak var recommendedTitleLabel: UILabel?
    private weak var recentlyTitleLabel: UILabel?
    private var recommendedHeightConstraint: NSLayoutConstraint?
    private var recommendedTitleHeightConstraint: NSLayoutConstraint?
    private var recommendedTopSpacingConstraint: NSLayoutConstraint?
    private var recommendedCollectionTopConstraint: NSLayoutConstraint?
    private var recentlyAfterRecommendedConstraint: NSLayoutConstraint?
    private var recentlyHeightConstraint: NSLayoutConstraint?
    private var recentlyTitleHeightConstraint: NSLayoutConstraint?
    private var recentlyCollectionTopConstraint: NSLayoutConstraint?
    private let recommendedExpandedHeight: CGFloat = PropertyCardCell.preferredHeight
    private let recommendedTopSpacing: CGFloat = 20
    private let recommendedCollectionTopSpacing: CGFloat = 8
    private let recentlyAfterRecommendedSpacing: CGFloat = 20
    private let recentlyHomeLimit = 3
    private let recommendedHomeLimit = 3
    private var isShowingAPIErrorAlert = false
    private var recentAIItems: [AISearchHistoryItem] = []
    private var recentAIToken = UUID()
    private var didInstallRecentAI = false
    private let recentAIHomeLimit = 2
    private let recentAIHeader = UIView()
    private let recentAITitleLabel = UILabel()
    private let recentAISubtitleLabel = UILabel()
    private let recentAIViewAllButton = UIButton(type: .system)
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
    private var recentAIHeaderHeightConstraint: NSLayoutConstraint?
    private var recentAIHeaderTopConstraint: NSLayoutConstraint?
    private var recentAISubtitleTopConstraint: NSLayoutConstraint?
    private var recentAISubtitleHeightConstraint: NSLayoutConstraint?
    private var recentAITableTopConstraint: NSLayoutConstraint?
    private var recentlyAfterRecentAIConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        applyStyle()
        setupCollections()
        setupRecentlyEmptyLabel()
        setupRecommendedEmptyLabel()
        setupRecentlyViewAllButton()
        setupRecommendedViewAllButton()
        resolveRecommendedSectionViews()
        resolveRecentlyTitleLabel()
        resolveRecentlySectionViews()
        installRecentAISearchSection()
        installContactAgentButton()
        installAgencyBannerSlider()
        installRangeFilterBar()
        resolveRecommendedViewAllPosition()
        installNotificationButton()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: LanguageManager.didChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(tabBecameSelected(_:)),
            name: TenantTabBarController.didChangeTab,
            object: nil
        )
        loadDashboardFilters()
        reloadProperties()
        loadRecentlyViewed()
        loadRecentAISearch()
       
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        agencyBannerSlider.startAutoScroll()
        recommendedCollection.reloadData()
        loadRecentlyViewed()
        loadRecentAISearch()
        showTenantProfile()
        refreshNotificationBadge()
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
        showTenantProfile()
        refreshNotificationBadge()
        loadDashboardFilters()
        loadRecentlyViewed()
        loadRecentAISearch()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        CommonMethods.styleDashboardProfilePhoto(profileImageView)
        recommendedCollection.collectionViewLayout.invalidateLayout()
        recentlyCollection.collectionViewLayout.invalidateLayout()
        CommonMethods.updateGradientFrame(for: contactAgentButton)
    }

    private func applyStyle() {
        view.backgroundColor = .screenBackgroundColor
        CommonMethods.styleFormCard(aiSearchCardView)
        applyTenantHeader(nil)
        showTenantProfile()
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
                    self.handleHomeAPIError(error)
                }
            }
        }
    }

    private func applyNotificationBadge(_ unread: Int) {
        badgeLabel.isHidden = unread <= 0
        guard unread > 0 else { return }
        badgeLabel.text = unread > 9 ? "9+" : "\(unread)"
    }
    
    

    func showTenantProfile() {
        Task {
            do {
                let res = try await AuthViewModel.profileAPI()
                await MainActor.run { self.applyTenantHeader(res.resolvedUser) }
            } catch {
                await MainActor.run {
                    self.applyTenantHeader(nil)
                    self.handleHomeAPIError(error)
                }
            }
        }
    }

    private func applyTenantHeader(_ user: User?) {
        if let user {
            TenantAccount.shared.apply(user: user)
        } else {
            TenantAccount.shared.clear()
        }
        nameLabel.text = user?.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        addressLabel.text = user?.email?.trimmingCharacters(in: .whitespacesAndNewlines)
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 24
        let placeholder = UIImage(named: "profile") ?? UIImage(named: "tenantProfile")
        if let url = Constant.mediaImageURL(user?.profileImage) {
            profileImageView.sd_setImage(with: url, placeholderImage: placeholder, options: [.retryFailed, .refreshCached])
        } else {
            profileImageView.image = placeholder
        }
    }

    private func handleHomeAPIError(_ error: Error) {
        let message = ((error as? APIError)?.errorDescription ?? error.localizedDescription)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard message.isEmpty == false else { return }
        guard isShowingAPIErrorAlert == false, presentedViewController == nil else { return }

        isShowingAPIErrorAlert = true
        let isTokenFailed = message.caseInsensitiveCompare("Not authorized, token failed") == .orderedSame
        CommonMethods.showAlert(message: message, from: self) { [weak self] in
            guard let self else { return }
            if isTokenFailed {
                self.moveToWelcomeAfterInvalidToken()
            } else {
                self.isShowingAPIErrorAlert = false
            }
        }
    }

    private func moveToWelcomeAfterInvalidToken() {
        KeyChainManager.shared.deleteValue(key: "token")
        KeyChainManager.shared.deleteValue(key: "UserRole")
        TenantAccount.shared.clear()
        PropertyStore.shared.mergeRemote(nil)
        PropertyStore.shared.setRecentlyViewed([])
        goToWelcomeTapped()
    }

    private func setupCollections() {
        [recommendedCollection, recentlyCollection].forEach { collection in
            collection?.register(PropertyCardCell.nib, forCellWithReuseIdentifier: PropertyCardCell.identifier)
            collection?.dataSource = self
            collection?.delegate = self
            collection?.showsHorizontalScrollIndicator = false
            collection?.backgroundColor = .clear
            collection?.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            if let layout = collection?.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.scrollDirection = .horizontal
                layout.minimumLineSpacing = 12
            }
        }
    }

    private func installContactAgentButton() {
        contactAgentButton.setTitle("Contact Agent".localized, for: .normal)
        contactAgentButton.setTitleColor(.white, for: .normal)
        contactAgentButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        contactAgentButton.translatesAutoresizingMaskIntoConstraints = false
        contactAgentButton.addTarget(self, action: #selector(contactAgentTapped), for: .touchUpInside)
        CommonMethods.styleYellowGradientButton(contactAgentButton)

        guard let parent = aiSearchCardView.superview else { return }
        parent.insertSubview(contactAgentButton, aboveSubview: aiSearchCardView)

        // Quick Search title is pinned to the AI card in the storyboard.
        for constraint in parent.constraints {
            let first = constraint.firstItem as? UIView
            let second = constraint.secondItem as? UIView
            guard constraint.firstAttribute == .top,
                  first is UILabel,
                  second === aiSearchCardView else { continue }
            constraint.isActive = false
            first?.topAnchor.constraint(equalTo: contactAgentButton.bottomAnchor, constant: 16).isActive = true
        }

        NSLayoutConstraint.activate([
            contactAgentButton.topAnchor.constraint(equalTo: aiSearchCardView.bottomAnchor, constant: 12),
            contactAgentButton.leadingAnchor.constraint(equalTo: aiSearchCardView.leadingAnchor),
            contactAgentButton.trailingAnchor.constraint(equalTo: aiSearchCardView.trailingAnchor),
            contactAgentButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func installAgencyBannerSlider() {
        guard agencyBannerSlider.superview == nil,
              let parent = aiSearchCardView.superview else { return }
        parent.insertSubview(agencyBannerSlider, belowSubview: aiSearchCardView)

        for constraint in parent.constraints {
            let first = constraint.firstItem as? UIView
            let second = constraint.secondItem as? UIView
            guard constraint.firstAttribute == .top,
                  first === aiSearchCardView else { continue }
            constraint.isActive = false
            if let second {
                agencyBannerSlider.topAnchor.constraint(equalTo: second.bottomAnchor, constant: constraint.constant).isActive = true
            }
        }

        let gap = aiSearchCardView.topAnchor.constraint(equalTo: agencyBannerSlider.bottomAnchor, constant: 0)
        aiSearchTopToBanner = gap
        agencyBannerSlider.onVisibilityChange = { [weak self] visible in
            self?.aiSearchTopToBanner?.constant = visible ? 12 : 0
            self?.view.layoutIfNeeded()
        }
        NSLayoutConstraint.activate([
            agencyBannerSlider.leadingAnchor.constraint(equalTo: aiSearchCardView.leadingAnchor),
            agencyBannerSlider.trailingAnchor.constraint(equalTo: aiSearchCardView.trailingAnchor),
            gap
        ])
        agencyBannerSlider.load()
    }

    private func installRangeFilterBar() {
        guard rangeFilterBar.superview == nil,
              let filterScroll = quickSearchStack.superview as? UIScrollView else { return }

        rangeFilterBar.host = self
        rangeFilterBar.horizontalInset = 24
        rangeFilterBar.onChanged = { [weak self] values in
            self?.rangeFilters = values
            self?.reloadProperties()
        }
        rangeFilterBar.translatesAutoresizingMaskIntoConstraints = false
        filterScroll.addSubview(rangeFilterBar)

        filterScroll.constraints.forEach { constraint in
            let first = constraint.firstItem as? UIView
            let second = constraint.secondItem as? UIView
            if first === filterScroll, constraint.firstAttribute == .height, constraint.secondItem == nil {
                constraint.isActive = false
            }
            if first === quickSearchStack, constraint.firstAttribute == .height {
                constraint.isActive = false
            }
            if second === quickSearchStack, constraint.secondAttribute == .bottom {
                constraint.isActive = false
            }
            if first === quickSearchStack, constraint.firstAttribute == .bottom {
                constraint.isActive = false
            }
        }

        NSLayoutConstraint.activate([
            filterScroll.heightAnchor.constraint(equalToConstant: 82),
            quickSearchStack.heightAnchor.constraint(equalToConstant: 36),
            rangeFilterBar.topAnchor.constraint(equalTo: quickSearchStack.bottomAnchor, constant: 10),
            rangeFilterBar.leadingAnchor.constraint(equalTo: filterScroll.contentLayoutGuide.leadingAnchor),
            rangeFilterBar.trailingAnchor.constraint(equalTo: filterScroll.contentLayoutGuide.trailingAnchor),
            rangeFilterBar.bottomAnchor.constraint(equalTo: filterScroll.contentLayoutGuide.bottomAnchor)
        ])
    }

    @objc private func contactAgentTapped() {
        openContactAgent()
    }

    private func installNotificationButton() {
        guard let parent = profileImageView.superview else { return }
        guard bellButton.superview == nil else { return }

        CommonMethods.styleHomeNotificationBell(bellButton)
        bellButton.translatesAutoresizingMaskIntoConstraints = false
        bellButton.accessibilityLabel = "Notifications".localized
        bellButton.addTarget(self, action: #selector(notificationsTapped), for: .touchUpInside)

        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.font = .systemFont(ofSize: 10, weight: .bold)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center
        badgeLabel.backgroundColor = UIColor(red: 220/255, green: 53/255, blue: 69/255, alpha: 1)
        badgeLabel.clipsToBounds = true
        badgeLabel.layer.cornerRadius = 9
        badgeLabel.layer.borderWidth = 1.5
        badgeLabel.layer.borderColor = UIColor.white.cgColor
        badgeLabel.isHidden = true

        parent.addSubview(bellButton)
        parent.addSubview(badgeLabel)
        parent.bringSubviewToFront(badgeLabel)

        // Only drop trailing pins on name/address.
        // Do NOT touch constraints that use profile.trailing (name's leading uses that).
        for constraint in parent.constraints {
            let first = constraint.firstItem as? UIView
            let second = constraint.secondItem as? UIView
            let pinsNameTrailing =
                (first === nameLabel && constraint.firstAttribute == .trailing) ||
                (second === nameLabel && constraint.secondAttribute == .trailing)
            let pinsAddressTrailing =
                (first === addressLabel && constraint.firstAttribute == .trailing) ||
                (second === addressLabel && constraint.secondAttribute == .trailing)
            if pinsNameTrailing || pinsAddressTrailing {
                constraint.isActive = false
            }
        }

        nameLabel.textAlignment = .left
        addressLabel.textAlignment = .left
        nameLabel.setContentHuggingPriority(.required, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        addressLabel.setContentHuggingPriority(.required, for: .horizontal)
        addressLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        NSLayoutConstraint.activate([
            bellButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            bellButton.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -20),
            bellButton.widthAnchor.constraint(equalToConstant: 40),
            bellButton.heightAnchor.constraint(equalToConstant: 40),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: bellButton.leadingAnchor, constant: -8),
            addressLabel.trailingAnchor.constraint(lessThanOrEqualTo: bellButton.leadingAnchor, constant: -8),
            badgeLabel.topAnchor.constraint(equalTo: bellButton.topAnchor, constant: -2),
            badgeLabel.trailingAnchor.constraint(equalTo: bellButton.trailingAnchor, constant: 2),
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 18),
            badgeLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
        refreshNotificationBadge()
    }


    @objc private func notificationsTapped() {
        let vc: TenantNotificationsVC = TenantStoryboard.load("TenantNotificationsVC")
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func languageChanged() {
        selectedFilters = [:]
        rangeFilters = PropertyRangeFilters()
        rangeFilterBar.values = rangeFilters
        contactAgentButton.setTitle("Contact Agent".localized, for: .normal)
        bellButton.accessibilityLabel = "Notifications".localized
        recentlyEmptyLabel.text = "No data found".localized
        recommendedEmptyLabel.text = "No data found".localized
        recentlyViewAllButton.setTitle("View All".localized, for: .normal)
        recommendedViewAllButton.setTitle("View All".localized, for: .normal)
        applyRecentAISearchCopy()
        loadDashboardFilters()
        loadRecentlyViewed()
        loadRecentAISearch()
    }

    private func setupRecentlyEmptyLabel() {
        recentlyEmptyLabel.translatesAutoresizingMaskIntoConstraints = false
        recentlyEmptyLabel.text = "No data found".localized
        recentlyEmptyLabel.textAlignment = .center
        recentlyEmptyLabel.numberOfLines = 0
        recentlyEmptyLabel.font = .systemFont(ofSize: 15, weight: .medium)
        recentlyEmptyLabel.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)
        recentlyEmptyLabel.isHidden = true
        guard let parent = recentlyCollection.superview else { return }
        parent.addSubview(recentlyEmptyLabel)
        NSLayoutConstraint.activate([
            recentlyEmptyLabel.centerXAnchor.constraint(equalTo: recentlyCollection.centerXAnchor),
            recentlyEmptyLabel.centerYAnchor.constraint(equalTo: recentlyCollection.centerYAnchor),
            recentlyEmptyLabel.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 32),
            recentlyEmptyLabel.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -32)
        ])
        updateRecentlyEmptyState()
    }

    private func setupRecommendedEmptyLabel() {
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
        updateRecommendedEmptyState()
    }

    private func setupRecentlyViewAllButton() {
        recentlyViewAllButton.translatesAutoresizingMaskIntoConstraints = false
        recentlyViewAllButton.setTitle("View All".localized, for: .normal)
        recentlyViewAllButton.setTitleColor(.darkThemeColor, for: .normal)
        recentlyViewAllButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        recentlyViewAllButton.isHidden = false
        recentlyViewAllButton.addTarget(self, action: #selector(recentlyViewAllTapped), for: .touchUpInside)
        guard let parent = recentlyCollection.superview else { return }
        parent.addSubview(recentlyViewAllButton)
        let centerY = recentlyViewAllButton.centerYAnchor.constraint(equalTo: recentlyCollection.topAnchor)
        recentlyViewAllCenterYConstraint = centerY
        NSLayoutConstraint.activate([
            recentlyViewAllButton.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -24),
            centerY,
            recentlyViewAllButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    private func setupRecommendedViewAllButton() {
        recommendedViewAllButton.translatesAutoresizingMaskIntoConstraints = false
        recommendedViewAllButton.setTitle("View All".localized, for: .normal)
        recommendedViewAllButton.setTitleColor(.darkThemeColor, for: .normal)
        recommendedViewAllButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        recommendedViewAllButton.isHidden = true
        recommendedViewAllButton.setContentHuggingPriority(.required, for: .horizontal)
        recommendedViewAllButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        recommendedViewAllButton.addTarget(self, action: #selector(recommendedViewAllTapped), for: .touchUpInside)
        guard let parent = recommendedCollection.superview else { return }
        parent.addSubview(recommendedViewAllButton)
        let centerY = recommendedViewAllButton.centerYAnchor.constraint(equalTo: recommendedCollection.topAnchor)
        recommendedViewAllCenterYConstraint = centerY
        NSLayoutConstraint.activate([
            recommendedViewAllButton.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -24),
            centerY,
            recommendedViewAllButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    private func resolveRecommendedViewAllPosition() {
        guard let parent = recommendedCollection.superview else { return }
        let title = recommendedTitleLabel
            ?? parent.subviews.compactMap { $0 as? UILabel }.first {
                $0.text?.localizedCaseInsensitiveContains("Recommended") == true
            }
        guard let title else { return }
        recommendedTitleLabel = title
        recommendedViewAllCenterYConstraint?.isActive = false
        let centerY = recommendedViewAllButton.centerYAnchor.constraint(equalTo: title.centerYAnchor)
        recommendedViewAllCenterYConstraint = centerY
        centerY.isActive = true
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        recommendedViewAllButton.leadingAnchor.constraint(
            greaterThanOrEqualTo: title.trailingAnchor,
            constant: 8
        ).isActive = true
        parent.bringSubviewToFront(recommendedViewAllButton)
    }

    private func resolveRecentlyTitleLabel() {
        guard let parent = recentlyCollection.superview else { return }
        recentlyTitleLabel = parent.constraints.compactMap { constraint -> UILabel? in
            let first = constraint.firstItem as? UIView
            let second = constraint.secondItem as? UIView
            guard (first === recentlyCollection && second is UILabel)
                    || (second === recentlyCollection && first is UILabel) else { return nil }
            let label = (first as? UILabel) ?? (second as? UILabel)
            guard label !== recommendedTitleLabel else { return nil }
            return label
        }.first
        if let title = recentlyTitleLabel {
            recentlyViewAllCenterYConstraint?.isActive = false
            let centerY = recentlyViewAllButton.centerYAnchor.constraint(equalTo: title.centerYAnchor)
            recentlyViewAllCenterYConstraint = centerY
            centerY.isActive = true
            title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            recentlyViewAllButton.leadingAnchor.constraint(
                greaterThanOrEqualTo: title.trailingAnchor,
                constant: 8
            ).isActive = true
        }
        resolveRecentlySectionViews()
    }

    private func resolveRecentlySectionViews() {
        recentlyHeightConstraint = recentlyCollection.constraints.first {
            $0.firstAttribute == .height && $0.secondItem == nil
        }
        guard let parent = recentlyCollection.superview else { return }
        if let title = recentlyTitleLabel {
            if recentlyTitleHeightConstraint == nil {
                let height = title.heightAnchor.constraint(equalToConstant: max(title.intrinsicContentSize.height, 22))
                height.isActive = true
                recentlyTitleHeightConstraint = height
            }
            recentlyCollectionTopConstraint = parent.constraints.first {
                ($0.firstItem === recentlyCollection && $0.secondItem === title)
                    || ($0.firstItem === title && $0.secondItem === recentlyCollection)
            }
        }
    }

    private func installRecentAISearchSection() {
        guard !didInstallRecentAI, let parent = recommendedCollection.superview else { return }
        didInstallRecentAI = true

        recentAITitleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        recentAITitleLabel.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
        recentAITitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        recentAISubtitleLabel.numberOfLines = 0
        recentAISubtitleLabel.font = .systemFont(ofSize: 13)
        recentAISubtitleLabel.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)

        recentAIViewAllButton.setTitleColor(.darkThemeColor, for: .normal)
        recentAIViewAllButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        recentAIViewAllButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        recentAIViewAllButton.addTarget(self, action: #selector(recentAIViewAllTapped), for: .touchUpInside)

        recentAIHeader.translatesAutoresizingMaskIntoConstraints = false
        recentAITitleLabel.translatesAutoresizingMaskIntoConstraints = false
        recentAIViewAllButton.translatesAutoresizingMaskIntoConstraints = false
        recentAISubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        recentAITable.translatesAutoresizingMaskIntoConstraints = false
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

        let headerHeight = recentAIHeader.heightAnchor.constraint(equalToConstant: 0)
        recentAIHeaderHeightConstraint = headerHeight
        let subtitleHeight = recentAISubtitleLabel.heightAnchor.constraint(equalToConstant: 0)
        recentAISubtitleHeightConstraint = subtitleHeight
        let tableHeight = recentAITable.heightAnchor.constraint(equalToConstant: 0)
        recentAIHeightConstraint = tableHeight

        parent.addSubview(recentAIHeader)
        parent.addSubview(recentAISubtitleLabel)
        parent.addSubview(recentAITable)

        recentlyAfterRecommendedConstraint?.isActive = false

        let headerTop = recentAIHeader.topAnchor.constraint(equalTo: recommendedCollection.bottomAnchor, constant: 0)
        recentAIHeaderTopConstraint = headerTop
        let subtitleTop = recentAISubtitleLabel.topAnchor.constraint(equalTo: recentAIHeader.bottomAnchor, constant: 0)
        recentAISubtitleTopConstraint = subtitleTop
        let tableTop = recentAITable.topAnchor.constraint(equalTo: recentAISubtitleLabel.bottomAnchor, constant: 0)
        recentAITableTopConstraint = tableTop

        NSLayoutConstraint.activate([
            recentAIHeader.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 20),
            recentAIHeader.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -20),
            headerTop,
            headerHeight,
            recentAISubtitleLabel.leadingAnchor.constraint(equalTo: recentAIHeader.leadingAnchor),
            recentAISubtitleLabel.trailingAnchor.constraint(equalTo: recentAIHeader.trailingAnchor),
            subtitleTop,
            subtitleHeight,
            recentAITable.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 20),
            recentAITable.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -20),
            tableTop,
            tableHeight
        ])

        if let title = recentlyTitleLabel {
            let after = title.topAnchor.constraint(equalTo: recentAITable.bottomAnchor, constant: recentlyAfterRecommendedSpacing)
            recentlyAfterRecentAIConstraint = after
            after.isActive = true
        }

        applyRecentAISearchCopy()
        updateRecentAISearchSection()
    }

    private func applyRecentAISearchCopy() {
        recentAITitleLabel.text = "Recent Searches".localized
        recentAISubtitleLabel.text = "Get recently AI search history".localized
        recentAIViewAllButton.setTitle("View All".localized, for: .normal)
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
        recentAIViewAllButton.isHidden = isEmpty || recentAIItems.count <= recentAIHomeLimit
        recentAIViewAllButton.isEnabled = recentAIItems.count > recentAIHomeLimit
        recentAITable.isScrollEnabled = false
        recentAITable.alwaysBounceVertical = false
        recentAITable.bounces = false
        recentAIHeaderHeightConstraint?.constant = isEmpty ? 0 : 22
        recentAIHeaderTopConstraint?.constant = isEmpty ? 0 : 20
        recentAISubtitleHeightConstraint?.isActive = isEmpty
        recentAISubtitleTopConstraint?.constant = isEmpty ? 0 : 4
        recentAITableTopConstraint?.constant = isEmpty ? 0 : 8
        recentAIHeightConstraint?.constant = isEmpty ? 0 : CGFloat(recentAIHomeItems.count) * AISearchQueryCell.rowHeight
        recentlyAfterRecentAIConstraint?.constant = recently.isEmpty ? 0 : recentlyAfterRecommendedSpacing
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

    private func updateRecentlyEmptyState() {
        let isEmpty = recently.isEmpty
        recentlyEmptyLabel.isHidden = true
        recentlyEmptyLabel.text = nil
        recentlyCollection.isHidden = isEmpty
        recentlyTitleLabel?.isHidden = isEmpty
        recentlyViewAllButton.isHidden = isEmpty
        recentlyHeightConstraint?.constant = isEmpty ? 0 : PropertyCardCell.preferredHeight
        recentlyTitleHeightConstraint?.constant = isEmpty ? 0 : 22
        recentlyCollectionTopConstraint?.constant = isEmpty ? 0 : 8
        let sectionSpacing: CGFloat = isEmpty ? 0 : recentlyAfterRecommendedSpacing
        recentlyAfterRecentAIConstraint?.constant = sectionSpacing
        if recentlyAfterRecentAIConstraint == nil {
            recentlyAfterRecommendedConstraint?.constant = sectionSpacing
        }
        view.layoutIfNeeded()
    }

    @objc private func recentlyViewAllTapped() {
        let vc: TenantRecentlyViewedVC = TenantStoryboard.load("TenantRecentlyViewedVC")
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func recommendedViewAllTapped() {
        let vc: TenantRecommendedListVC = TenantStoryboard.load("TenantRecommendedListVC")
        vc.filterSelections = selectedFilters.values.flatMap { $0 }
        vc.rangeFilters = rangeFilters
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    private var recentlyHomeItems: [PropertyItem] {
        Array(recently.prefix(recentlyHomeLimit))
    }

    private var recommendedHomeItems: [PropertyItem] {
        Array(recommended.prefix(recommendedHomeLimit))
    }

    private func loadRecentlyViewed() {
        let token = UUID()
        recentlyToken = token
        Task {
            do {
                let items = try await TenantViewModels.recentlyViewedAPI()
                await MainActor.run {
                    guard self.recentlyToken == token else { return }
                    PropertyStore.shared.setRecentlyViewed(items)
                    self.recently = items
                    self.recentlyCollection.reloadData()
                    self.updateRecentlyEmptyState()
                }
            } catch {
                await MainActor.run {
                    guard self.recentlyToken == token else { return }
                    self.recently = []
                    PropertyStore.shared.setRecentlyViewed([])
                    self.recentlyCollection.reloadData()
                    self.updateRecentlyEmptyState()
                    self.handleHomeAPIError(error)
                }
            }
        }
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
                    self.handleHomeAPIError(error)
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

    private func resolveRecommendedSectionViews() {
        recommendedHeightConstraint = recommendedCollection.constraints.first {
            $0.firstAttribute == .height && $0.secondItem == nil
        }
        guard let parent = recommendedCollection.superview else { return }
        recommendedTitleLabel = parent.constraints.compactMap { constraint -> UILabel? in
            let first = constraint.firstItem as? UIView
            let second = constraint.secondItem as? UIView
            guard (first === recommendedCollection && second is UILabel)
                    || (second === recommendedCollection && first is UILabel) else { return nil }
            return (first as? UILabel) ?? (second as? UILabel)
        }.first
        if let label = recommendedTitleLabel {
            if recommendedTitleHeightConstraint == nil {
                let height = label.heightAnchor.constraint(equalToConstant: label.intrinsicContentSize.height)
                height.isActive = true
                recommendedTitleHeightConstraint = height
            }
            recommendedTopSpacingConstraint = parent.constraints.first {
                ($0.firstItem === label && $0.firstAttribute == .top)
                    || ($0.secondItem === label && $0.secondAttribute == .top)
            }
            recommendedCollectionTopConstraint = parent.constraints.first {
                ($0.firstItem === recommendedCollection && $0.secondItem === label)
                    || ($0.firstItem === label && $0.secondItem === recommendedCollection)
            }
        }
        recentlyAfterRecommendedConstraint = parent.constraints.first { constraint in
            let first = constraint.firstItem as? UIView
            let second = constraint.secondItem as? UIView
            guard constraint.firstAttribute == .top || constraint.secondAttribute == .top else { return false }
            return (first === recommendedCollection && second is UILabel && second !== recommendedTitleLabel)
                || (second === recommendedCollection && first is UILabel && first !== recommendedTitleLabel)
        }
        updateRecommendedEmptyState()
    }

    private func updateRecommendedEmptyState() {
        let isEmpty = recommended.isEmpty
        recommendedTitleLabel?.isHidden = false
        recommendedEmptyLabel.isHidden = !isEmpty
        recommendedCollection.isHidden = isEmpty
        recommendedViewAllButton.isHidden = recommended.count <= recommendedHomeLimit
        recommendedCollection.superview?.bringSubviewToFront(recommendedViewAllButton)
        recommendedHeightConstraint?.constant = recommendedExpandedHeight
        if let label = recommendedTitleLabel {
            recommendedTitleHeightConstraint?.constant = max(label.intrinsicContentSize.height, 22)
        }
        recommendedTopSpacingConstraint?.constant = recommendedTopSpacing
        recommendedCollectionTopConstraint?.constant = recommendedCollectionTopSpacing
        if recentlyAfterRecentAIConstraint == nil {
            recentlyAfterRecommendedConstraint?.constant = recently.isEmpty ? 0 : recentlyAfterRecommendedSpacing
        }
        view.layoutIfNeeded()
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
                    self.updateRecommendedEmptyState()
                    self.recommendedCollection.reloadData()
                    self.recentlyCollection.reloadData()
                    self.updateRecentlyEmptyState()
                }
            } catch {
                await MainActor.run {
                    guard self.searchToken == token else { return }
                    PropertyStore.shared.mergeRemote(nil)
                    self.recommended = []
                    self.updateRecommendedEmptyState()
                    self.recommendedCollection.reloadData()
                    self.recentlyCollection.reloadData()
                    self.updateRecentlyEmptyState()
                    self.handleHomeAPIError(error)
                }
            }
        }
    }

    private func currentFilterRequest() -> PropertyFilterRequest {
        var request = PropertyFilterRequest.dashboard(selections: selectedFilters.values.flatMap { $0 })
        request.apply(rangeFilters)
        return request
    }

    @IBAction func aiSearchTapped(_ sender: UIButton) {
        openAISearch()
    }

    @IBAction func quickSearchTapped(_ sender: UIButton) {
        sender.sendActions(for: .menuActionTriggered)
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
}

extension TenantHomeVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionView == recommendedCollection
            ? recommendedHomeItems.count
            : recentlyHomeItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PropertyCardCell.identifier,
            for: indexPath
        ) as? PropertyCardCell else {
            return UICollectionViewCell()
        }
        let property = collectionView == recommendedCollection
            ? recommendedHomeItems[indexPath.item]
            : recentlyHomeItems[indexPath.item]
        let isRecentlyViewed = collectionView !== recommendedCollection
        cell.configure(
            with: property,
            isFavorite: PropertyStore.shared.isFavorite(property.id) || property.isFav,
            showsDelete: isRecentlyViewed
        )
        cell.onFavorite = nil
        cell.onDelete = nil
        if isRecentlyViewed {
            cell.onDelete = { [weak self] in
                self?.deleteRecentlyViewedRemote(property) { success in
                    guard success else { return }
                    self?.loadRecentlyViewed()
                }
            }
        } else {
            cell.onFavorite = { [weak self] in
                self?.toggleFavoriteRemote(propertyId: property.id) { isFav in
                    guard let self else { return }
                    if let index = self.recommended.firstIndex(where: { $0.id == property.id }) {
                        self.recommended[index].isFav = isFav
                    }
                    if let index = self.recently.firstIndex(where: { $0.id == property.id }) {
                        self.recently[index].isFav = isFav
                    }
                    self.recommendedCollection.reloadData()
                    self.recentlyCollection.reloadData()
                }
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let property = collectionView == recommendedCollection
            ? recommendedHomeItems[indexPath.item]
            : recentlyHomeItems[indexPath.item]
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
