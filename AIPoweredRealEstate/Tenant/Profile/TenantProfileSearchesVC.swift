//
//  TenantProfileSearchesVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class TenantProfileSearchesVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!

    private let spinner = UIActivityIndicatorView(style: .medium)
    private var items: [AISearchHistoryItem] = []
    private var loadToken = UUID()
    private var isUpdating = false
    private lazy var removeAllItem: UIBarButtonItem = {
        let item = UIBarButtonItem(
            title: "Remove All".localized,
            style: .plain,
            target: self,
            action: #selector(removeAllTapped)
        )
        item.tintColor = .accentThemeColor
        return item
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        TenantProfileStyle.applyPushed(self, title: "Saved Searches")
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = AISearchQueryCell.rowHeight
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        tableView.register(AISearchQueryCell.self, forCellReuseIdentifier: AISearchQueryCell.identifier)
        emptyLabel.text = "No data found".localized
        emptyLabel.isHidden = true
        insetSearchCards()
        installSpinner()
        updateRemoveAllButton()
    }

    private func insetSearchCards() {
        guard let parent = tableView.superview else { return }
        parent.constraints
            .filter {
                ($0.firstItem === tableView && ($0.firstAttribute == .leading || $0.firstAttribute == .trailing))
                    || ($0.secondItem === tableView && ($0.secondAttribute == .leading || $0.secondAttribute == .trailing))
            }
            .forEach { $0.isActive = false }
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -20)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        loadItems()
    }

    private func installSpinner() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func updateRemoveAllButton() {
        let show = items.count > 1 && !isUpdating
        navigationItem.rightBarButtonItem = AISearchHistoryItem.showsRemoveAll(count: items.count) ? removeAllItem : nil
        removeAllItem.isEnabled = show
        removeAllItem.title = "Remove All".localized
    }

    private func loadItems() {
        let token = UUID()
        loadToken = token
        spinner.startAnimating()
        emptyLabel.isHidden = true
        Task {
            do {
                let remote = try await AgentViewModels.recentlyAISearchAPI()
                await MainActor.run {
                    guard self.loadToken == token else { return }
                    self.applyItems(remote)
                }
            } catch {
                await MainActor.run {
                    guard self.loadToken == token else { return }
                    self.applyItems([])
                }
            }
        }
    }

    private func applyItems(_ remote: [AISearchHistoryItem]) {
        spinner.stopAnimating()
        items = remote
        emptyLabel.text = "No data found".localized
        emptyLabel.isHidden = !remote.isEmpty
        tableView.reloadData()
        updateRemoveAllButton()
    }

    @objc private func removeAllTapped() {
        guard AISearchHistoryItem.showsRemoveAll(count: items.count), !isUpdating else { return }
        CommonMethods.showConfirmationAlert(
            message: "Clear all AI search history?",
            confirmTitle: "Remove All",
            confirmStyle: .destructive,
            from: self
        ) { [weak self] in
            self?.deleteAllHistory()
        }
    }

    private func deleteAllHistory() {
        isUpdating = true
        updateRemoveAllButton()
        Task {
            do {
                try await AgentViewModels.deleteAllAISearchHistoryAPI()
                await MainActor.run {
                    self.isUpdating = false
                    self.applyItems([])
                }
            } catch {
                await MainActor.run {
                    self.isUpdating = false
                    self.updateRemoveAllButton()
                    self.showAPIError(error)
                }
            }
        }
    }

    private func confirmDelete(_ item: AISearchHistoryItem) {
        guard !isUpdating else { return }
        CommonMethods.showConfirmationAlert(
            message: "Delete this search history?",
            confirmTitle: "Delete",
            confirmStyle: .destructive,
            from: self
        ) { [weak self] in
            self?.deleteHistory(item)
        }
    }

    private func deleteHistory(_ item: AISearchHistoryItem) {
        isUpdating = true
        updateRemoveAllButton()
        Task {
            do {
                try await AgentViewModels.deleteAISearchHistoryAPI(id: item.historyId)
                await MainActor.run {
                    self.isUpdating = false
                    self.items.removeAll { $0.historyId == item.historyId }
                    self.emptyLabel.isHidden = !self.items.isEmpty
                    self.tableView.reloadData()
                    self.updateRemoveAllButton()
                }
            } catch {
                await MainActor.run {
                    self.isUpdating = false
                    self.updateRemoveAllButton()
                    self.showAPIError(error)
                }
            }
        }
    }

    private func showAPIError(_ error: Error) {
        let message = ((error as? APIError)?.errorDescription ?? error.localizedDescription)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let text = message.isEmpty ? "Unable to delete search history.".localized : message
        CommonMethods.showAlert(message: text, from: self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: AISearchQueryCell.identifier,
            for: indexPath
        ) as? AISearchQueryCell else {
            return UITableViewCell()
        }
        let item = items[indexPath.row]
        cell.configure(query: item.query)
        cell.onDelete = { [weak self] in
            self?.confirmDelete(item)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openAISearch(
            prefilled: items[indexPath.row].query,
            chatId: items[indexPath.row].historyId
        )
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        AISearchQueryCell.rowHeight
    }
}
