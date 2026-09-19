//
//  TenantLeadsVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class TenantLeadsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!

    private var leads: [PlatformLead] = []
    private var loadToken = UUID()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Leads".localized
        view.backgroundColor = .screenBackgroundColor
        navigationController?.navigationBar.tintColor = .darkThemeColor
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        tableView.allowsSelection = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 108
        tableView.register(BuyerLeadCell.self, forCellReuseIdentifier: BuyerLeadCell.identifier)
        emptyLabel.text = "No leads found".localized
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
        spinner.hidesWhenStopped = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        loadLeads()
    }

    private func loadLeads() {
        let token = UUID()
        loadToken = token
        spinner.startAnimating()
        emptyLabel.isHidden = true
        Task {
            do {
                let remote = try await TenantViewModels.myLeadsAPI(syncBuyerStore: true)
                await MainActor.run {
                    guard self.loadToken == token else { return }
                    self.applyLeads(remote)
                }
            }
            catch {
                await MainActor.run {
                    guard self.loadToken == token else { return }
                    self.applyLeads([])
                }
            }
        }
    }

    private func applyLeads(_ remote: [PlatformLead]) {
        spinner.stopAnimating()
        leads = remote
        emptyLabel.text = "No leads found".localized
        emptyLabel.isHidden = !leads.isEmpty
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { leads.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BuyerLeadCell.identifier, for: indexPath) as! BuyerLeadCell
        cell.configure(leads[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
