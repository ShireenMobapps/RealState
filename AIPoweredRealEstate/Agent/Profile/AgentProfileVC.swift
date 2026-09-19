//
//  AgentProfileVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class AgentProfileVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private enum Row: CaseIterable {
        case edit, leads, notifications, language, changePassword, help, logout

        var title: String {
            switch self {
            case .edit: return "Edit Profile".localized
            case .leads: return "Leads".localized
            case .notifications: return "Notifications".localized
            case .language: return "Language".localized
            case .changePassword: return "Change Password".localized
            case .help: return "Help & Support".localized
            case .logout: return "Logout".localized
            }
        }

        var icon: String {
            switch self {
            case .edit: return "pencil"
            case .leads: return "person.badge.plus"
            case .notifications: return "bell.fill"
            case .language: return "globe"
            case .changePassword: return "key.fill"
            case .help: return "questionmark.circle.fill"
            case .logout: return "rectangle.portrait.and.arrow.right"
            }
         }
      }

    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var agencyLabel: UILabel!
    var agencyId: String = ""
    @IBOutlet weak var profileCardView: CustomView!
    @IBOutlet weak var tableView: UITableView!
    private let rows = Row.allCases
    private var notificationUnread = 0
    private var badgeToken = UUID()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .screenBackgroundColor
        CommonMethods.styleFormCard(profileCardView)
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        ProfileMenuCell.register(on: tableView)
        tableView.tableFooterView = UIView()
        photoView.contentMode = .scaleAspectFill
        photoView.clipsToBounds = true
        nameLabel.font = .systemFont(ofSize: 20, weight: .bold)
        nameLabel.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
        applyProfile(nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        notificationUnread = NotificationUnreadStore.shared.count
        tableView.reloadData()
        loadProfile()
        loadNotificationBadge()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        photoView.layer.cornerRadius = photoView.bounds.width / 2
        photoView.layer.masksToBounds = true
        CommonMethods.styleDashboardProfilePhoto(photoView)
    }

    private func loadProfile() {
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
        let name = user?.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        nameLabel.text = name.isEmpty ? nil : name
        if let agency = user?.agencyName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !agency.isEmpty,
           let email = user?.email?.trimmingCharacters(in: .whitespacesAndNewlines),
           !email.isEmpty {
            agencyLabel.text = "\(agency)  ·  \(email)"
        } else {
            agencyLabel.text = user?.email ?? user?.agencyName
        }
        let placeholder = UIImage(named: "profile") ?? UIImage(named: "tenantProfile")
        photoView.setMediaProfileImage(user?.profileImage, placeholder: placeholder)
    }

    private func loadNotificationBadge() {
        let token = UUID()
        badgeToken = token
        Task {
            do {
                let response = try await AgentViewModels.newNotificationsAPI()
                await MainActor.run {
                    guard self.badgeToken == token else { return }
                    NotificationUnreadStore.shared.apply(response: response)
                    self.notificationUnread = NotificationUnreadStore.shared.count
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    guard self.badgeToken == token else { return }
                    self.notificationUnread = NotificationUnreadStore.shared.count
                    self.tableView.reloadData()
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProfileMenuCell.identifier, for: indexPath) as? ProfileMenuCell else {
            return UITableViewCell()
        }
        let row = rows[indexPath.row]
        let subtitle: String?
        switch row {
        case .leads: subtitle = "%d open".localized(AgentStore.shared.openLeadCount)
        case .notifications:
            subtitle = notificationUnread == 0 ? nil : "%d unread".localized(notificationUnread)
        case .language:
            subtitle = LanguageManager.shared.currentLanguage == "es" ? "Español" : "English"
        default: subtitle = nil
        }
        cell.configure(icon: row.icon, title: row.title, subtitle: subtitle, isDestructive: row == .logout)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch rows[indexPath.row] {
        case .edit:
            push(AgentStoryboard.load("AgentEditProfileVC") as TenantEditProfileVC)
        case .leads:
            push(AgentStoryboard.load("AgentLeadsVC"))
        case .notifications:
            push(AgentStoryboard.load("AgentNotificationsVC"))
        case .language:
            let picker: TenantOptionPickerVC = TenantStoryboard.load("TenantOptionPickerVC")
            picker.dismissesOnSelect = false
            let selected = LanguageManager.shared.currentLanguage == "es" ? "Español" : "English"
            picker.configure(title: "Language", options: TenantAccount.languages, selected: selected) { value in
                LanguageManager.shared.applyFromProfile(displayName: value, from: picker)
            }
            push(picker)
        case .changePassword:
            push(TenantChangePasswordVC())
        case .help:
            let page: TenantTextPageVC = TenantStoryboard.load("TenantTextPageVC")
            page.configure(title: "Help & Support".localized, body: TenantLegalContent.help)
            push(page)
        case .logout:
            logout()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 54 }

    private func push(_ controller: UIViewController) {
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }

    private func logout() {
        CommonMethods.showConfirmationAlert(title: "Logout".localized,message: "Are you sure you want to log out?".localized, from: self) {
            
            let sts = KeyChainManager.shared.deleteValue(key: "token")
            let _ = KeyChainManager.shared.deleteValue(key: "UserRole")
            if sts == true{
                NotificationUnreadStore.shared.reset()
                self.goToWelcomeTapped()
            }
        }
    }
}
