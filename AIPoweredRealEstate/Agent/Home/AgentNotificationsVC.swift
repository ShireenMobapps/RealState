//
//  AgentNotificationsVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class AgentNotificationsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    private let emptyLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)

    private var items: [NotificationItemModel] = []
    private var page = 1
    private let limit = 10
    private var hasMore = true
    private var isLoading = false
    private var loadToken = UUID()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notifications".localized
        view.backgroundColor = .screenBackgroundColor
        navigationController?.navigationBar.tintColor = .darkThemeColor
        tableView.backgroundColor = .screenBackgroundColor
        tableView.separatorStyle = .none
        tableView.separatorColor = .clear
        tableView.sectionHeaderTopPadding = 0
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 108
        NotificationCell.register(on: tableView)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = "No notification found".localized
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.font = .systemFont(ofSize: 15, weight: .medium)
        emptyLabel.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)
        emptyLabel.isHidden = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        view.addSubview(emptyLabel)
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        markNotificationsFetched()
        reloadFromStart()
    }

    private func reloadFromStart() {
        page = 1
        hasMore = true
        loadPage(reset: true)
    }

    private func loadPage(reset: Bool) {
        guard !isLoading else { return }
        guard hasMore || reset else { return }
        isLoading = true
        let token = UUID()
        loadToken = token
        let requestPage = reset ? 1 : page
        if reset {
            spinner.startAnimating()
            emptyLabel.isHidden = true
        }
        Task {
            do {
                let response = try await AgentViewModels.notificationsAPI(page: requestPage, limit: limit)
                await MainActor.run {
                    guard self.loadToken == token else { return }
                    self.spinner.stopAnimating()
                    self.apply(response, reset: reset)
                }
            } catch {
                await MainActor.run {
                    guard self.loadToken == token else { return }
                    self.spinner.stopAnimating()
                    self.isLoading = false
                    if reset {
                        self.items = []
                        self.hasMore = false
                        self.updateEmptyState()
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }

    private func apply(_ response: GetNotificationsResponseModel, reset: Bool) {
        isLoading = false
        if reset {
            items = response.items
            page = 2
        } else {
            let existing = Set(items.map(\.id))
            items.append(contentsOf: response.items.filter { !existing.contains($0.id) })
            page = response.page + 1
        }
        hasMore = response.hasMore && !response.items.isEmpty
        updateEmptyState()
        tableView.reloadData()
    }

    private func updateEmptyState() {
        emptyLabel.text = "No notification found".localized
        emptyLabel.isHidden = !items.isEmpty
        tableView.isHidden = items.isEmpty
    }

    private func markNotificationsFetched() {
        Task {
            do {
                let response = try await AgentViewModels.newNotificationsAPI()
                await MainActor.run {
                    NotificationUnreadStore.shared.apply(response: response)
                }
            } catch {
                return
            }
        }
    }

    private func deleteNotification(id: String) {
        let notificationId = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !notificationId.isEmpty else { return }
        Task {
            do {
                _ = try await AgentViewModels.deleteNotificationAPI(id: notificationId)
                await MainActor.run {
                    self.items.removeAll { $0.id == notificationId }
                    self.updateEmptyState()
                    self.tableView.reloadData()
                }
            } catch {
                return
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NotificationCell.identifier, for: indexPath) as? NotificationCell else {
            return UITableViewCell()
        }
        let item = items[indexPath.row]
        cell.configure(item)
        cell.onDelete = { [weak self] in
            self?.deleteNotification(id: item.id)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard hasMore, !isLoading, !items.isEmpty else { return }
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        if offsetY > contentHeight - height - 120 {
            loadPage(reset: false)
        }
    }
}
