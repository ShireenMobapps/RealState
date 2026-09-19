//
//  TenantProfileVC.swift
//  AIPoweredRealEstate
//

import UIKit

enum ProfileTab {
    case realtor, leads, notifications, savedSearches, recentlyViewed
    case changePassword, language, currency, help, terms, privacy, logout
}

struct profileRow {
    var icon: UIImage?
    var titleName: String?
    var subtitle: String?
    var kind: ProfileTab
}

class TenantProfileVC: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var profileCardView: CustomView!
    @IBOutlet weak var tableView: UITableView!

    var unreadNotificcation: NewNotificationsData?
    var ProfileTabs: [profileRow] = []
    var agentCount: Int?
    var leadCount: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .screenBackgroundColor
        titleLabel.text = "Profile".localized
        CommonMethods.styleFormCard(profileCardView)
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 56, bottom: 0, right: 20)
        tableView.dataSource = self
        tableView.delegate = self
        ProfileMenuCell.register(on: tableView)
        tableView.tableFooterView = UIView()
        photoView.contentMode = .scaleAspectFill
        photoView.clipsToBounds = true
        photoView.image = photoView.image ?? UIImage(named: "profile")
        reloadProfileTabs()
        styleEditLabel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        titleLabel.text = "Profile".localized
        getUserProfile()
        loadAgentsLeadsAndNotificationCount()
        reloadProfileTabs()
        styleEditLabel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        photoView.layer.cornerRadius = photoView.bounds.width / 2
        photoView.layer.masksToBounds = true
        CommonMethods.styleDashboardProfilePhoto(photoView)
    }

    @IBAction func editProfileTapped(_ sender: Any) {
        push(TenantStoryboard.load("TenantEditProfileVC") as TenantEditProfileVC)
    }

    private func styleEditLabel() {
        for case let label as UILabel in profileCardView.subviews where label !== nameLabel && label !== addressLabel {
            guard (label.text ?? "").isEmpty == false else { continue }
            label.textColor = .accentThemeColor
            label.font = .systemFont(ofSize: 16, weight: .semibold)
        }
    }

    private func push(_ controller: UIViewController) {
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }

    func getUserProfile() {
        Task {
            do {
                let response = try await AuthViewModel.profileAPI()
                await MainActor.run { self.applyProfile(response.resolvedUser) }
            } catch {
                await MainActor.run { self.applyProfile(nil) }
            }
        }
    }

    private func applyProfile(_ user: User?) {
        if let user {
            TenantAccount.shared.apply(user: user)
        } else {
            TenantAccount.shared.clear()
        }
        nameLabel.text = user?.name
        addressLabel.text = user?.email
        let placeholder = UIImage(named: "profile")
        if let url = Constant.mediaImageURL(user?.profileImage) {
            photoView.sd_setImage(with: url, placeholderImage: placeholder, options: [.retryFailed, .refreshCached])
        } else {
            photoView.image = placeholder
        }
    }

    private func loadAgentsLeadsAndNotificationCount() {
        Task {
            async let agentsTask = TenantViewModels.agentsAPI()
            async let leadsTask = TenantViewModels.myLeadsAPI(syncBuyerStore: true)
            async let notificationTask = AuthViewModel.notificationCountAPI()

            let agents = try? await agentsTask
            let leads = try? await leadsTask
            let notifications = try? await notificationTask

            await MainActor.run {
                self.agentCount = agents?.count ?? 0
                self.leadCount = leads?.count ?? 0
                if let notifications {
                    NotificationUnreadStore.shared.apply(response: notifications)
                }
                self.unreadNotificcation = notifications?.data
                self.reloadProfileTabs()
            }
        }
    }

    private func reloadProfileTabs() {
        ProfileTabs = [
            .init(
                icon: tabIcon("person.crop.circle.badge.checkmark"),
                titleName: "Your realtor".localized,
                subtitle: realtorSubtitle(),
                kind: .realtor
            ),
            .init(
                icon: tabIcon("list.bullet.rectangle"),
                titleName: "My Leads".localized,
                subtitle: leadsSubtitle(),
                kind: .leads
            ),
            .init(
                icon: tabIcon("bell.fill"),
                titleName: "Notifications".localized,
                subtitle: notificationsSubtitle(),
                kind: .notifications
            ),
            .init(
                icon: tabIcon("bookmark.fill"),
                titleName: "Saved Searches".localized,
                subtitle: nil,
                kind: .savedSearches
            ),
            .init(
                icon: tabIcon("clock.fill"),
                titleName: "Recently Viewed".localized,
                subtitle: nil,
                kind: .recentlyViewed
            ),
            .init(
                icon: tabIcon("key.fill"),
                titleName: "Change Password".localized,
                subtitle: nil,
                kind: .changePassword
            ),
            .init(
                icon: tabIcon("globe"),
                titleName: "Language".localized,
                subtitle: TenantAccount.shared.language,
                kind: .language
            ),
            .init(
                icon: tabIcon("dollarsign.circle.fill"),
                titleName: "Currency".localized,
                subtitle: TenantAccount.shared.currency,
                kind: .currency
            ),
            .init(
                icon: tabIcon("questionmark.circle.fill"),
                titleName: "Help & Support".localized,
                subtitle: nil,
                kind: .help
            ),
            .init(
                icon: tabIcon("doc.text.fill"),
                titleName: "Terms & Conditions".localized,
                subtitle: nil,
                kind: .terms
            ),
            .init(
                icon: tabIcon("lock.fill"),
                titleName: "Privacy Policy".localized,
                subtitle: nil,
                kind: .privacy
            ),
            .init(
                icon: tabIcon("rectangle.portrait.and.arrow.right"),
                titleName: "Logout".localized,
                subtitle: nil,
                kind: .logout
            )
        ]
        tableView.reloadData()
    }

    private func tabIcon(_ name: String) -> UIImage? {
        UIImage(systemName: name)?.withRenderingMode(.alwaysTemplate)
    }

    private func realtorSubtitle() -> String {
        let count = agentCount ?? 0
        if let name = RealtorDesk.shared.buyerAssignedRealtor()?.name {
            return "%@ · %d available".localized(name, count)
        }
        return count == 0
            ? "Contact Agent".localized
            : "%d agents available".localized(count)
    }

    private func leadsSubtitle() -> String {
        let count = leadCount ?? 0
        return count == 0 ? "None yet".localized : "%d leads".localized(count)
    }

    private func notificationsSubtitle() -> String? {
        let unread = NotificationUnreadStore.shared.count
        return unread == 0 ? nil : "%d unread".localized(unread)
    }

    private func logout() {
        CommonMethods.showConfirmationAlert(
            title: "Logout".localized,
            message: "Are you sure you want to log out?".localized,
            from: self
        ) {
            let sts = KeyChainManager.shared.deleteValue(key: "token")
            let _ = KeyChainManager.shared.deleteValue(key: "UserRole")
            TenantAccount.shared.clear()
            PropertyStore.shared.mergeRemote(nil)
            PropertyStore.shared.setRecentlyViewed([])
            NotificationUnreadStore.shared.reset()
            if sts == true {
                self.goToWelcomeTapped()
            }
        }
    }
}

extension TenantProfileVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        ProfileTabs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProfileMenuCell.identifier, for: indexPath) as? ProfileMenuCell else {
            return UITableViewCell()
        }
        let row = ProfileTabs[indexPath.row]
        cell.configure(
            icon: row.icon,
            title: row.titleName ?? "",
            subtitle: row.subtitle,
            isDestructive: row.kind == .logout
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch ProfileTabs[indexPath.row].kind {
        case .realtor:
            openContactAgent()
        case .leads:
            openBuyerLeads()
        case .notifications:
            push(TenantStoryboard.load("TenantNotificationsVC") as TenantNotificationsVC)
        case .savedSearches:
            push(TenantStoryboard.load("TenantProfileSearchesVC") as TenantProfileSearchesVC)
        case .recentlyViewed:
            push(TenantStoryboard.load("TenantRecentlyViewedVC") as TenantRecentlyViewedVC)
        case .changePassword:
            push(TenantChangePasswordVC())
        case .language:
            let picker: TenantOptionPickerVC = TenantStoryboard.load("TenantOptionPickerVC")
            picker.dismissesOnSelect = false
            let selected = LanguageManager.shared.currentLanguage == "es" ? "Español" : "English"
            picker.configure(title: "Language", options: TenantAccount.languages, selected: selected) { value in
                LanguageManager.shared.applyFromProfile(displayName: value, from: picker)
            }
            push(picker)
        case .currency:
            let picker: TenantOptionPickerVC = TenantStoryboard.load("TenantOptionPickerVC")
            picker.configure(title: "Currency".localized, options: TenantAccount.currencies, selected: TenantAccount.shared.currency) { value in
                TenantAccount.shared.currency = value
            }
            push(picker)
        case .help:
            let page: TenantTextPageVC = TenantStoryboard.load("TenantTextPageVC")
            page.configure(title: "Help & Support".localized, body: TenantLegalContent.help)
            push(page)
        case .terms:
            let page: TenantTextPageVC = TenantStoryboard.load("TenantTextPageVC")
            page.configure(title: "Terms & Conditions".localized, body: TenantLegalContent.terms)
            push(page)
        case .privacy:
            let page: TenantTextPageVC = TenantStoryboard.load("TenantTextPageVC")
            page.configure(title: "Privacy Policy".localized, body: TenantLegalContent.privacy)
            push(page)
        case .logout:
            logout()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 54 }
}
