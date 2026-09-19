//
//  TenantEnquiryHistoryVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class TenantEnquiryHistoryVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        TenantProfileStyle.applyPushed(self, title: "Enquiry History")
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        emptyLabel.isHidden = !PropertyStore.shared.enquiries.isEmpty
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        PropertyStore.shared.enquiries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = PropertyStore.shared.enquiries[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = item.propertyTitle
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.locale
        formatter.dateStyle = .medium
        config.secondaryText = "\("Your realtor".localized): \(item.agentName)  ·  \(formatter.string(from: item.date))\n\("Source listing agent".localized): \(item.listingAgentName) · \(item.source)\n\(item.message)"
        config.textProperties.font = .systemFont(ofSize: 16, weight: .semibold)
        config.secondaryTextProperties.numberOfLines = 3
        cell.contentConfiguration = config
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }
}
