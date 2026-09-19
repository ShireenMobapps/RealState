//
//  TenantRealtorRecommendationsVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class TenantRealtorRecommendationsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    private var report: ClientFacingReport?
    private var properties: [PropertyItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Realtor recommendations".localized
        view.backgroundColor = .screenBackgroundColor
        navigationController?.navigationBar.tintColor = .darkThemeColor
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .screenBackgroundColor
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        reload()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Compare".localized,
            style: .plain,
            target: self,
            action: #selector(compareTapped)
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        reload()
    }

    private func reload() {
        report = RealtorDesk.shared.latestSharedReport()
        properties = report?.matches.compactMap { match in
            PropertyStore.shared.all.first { $0.id == match.propertyId }
        } ?? []
        tableView.reloadData()
    }

    @objc private func compareTapped() {
        guard properties.count >= 2 else { return }
        openCompare(Array(properties.prefix(3)))
    }

    func numberOfSections(in tableView: UITableView) -> Int { 3 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return max(properties.count, 1)
        default: return 3
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Your realtor".localized
        case 1: return "Recommended properties".localized
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        cell.accessoryType = .none
        cell.selectionStyle = .default
        if indexPath.section == 0 {
            let request = RealtorDesk.shared.buyerActiveRequest
            let realtor = request.flatMap { RealtorDesk.shared.assignedRealtor(for: $0) }
            config.text = realtor?.name ?? "Assigned realtor".localized
            config.secondaryText = [realtor?.agency, report?.comparisonSummary].compactMap { $0 }.joined(separator: "\n")
            config.secondaryTextProperties.numberOfLines = 0
            cell.selectionStyle = .none
        } else if indexPath.section == 1 {
            if properties.isEmpty {
                config.text = "No recommendations yet.".localized
                cell.selectionStyle = .none
            } else {
                let property = properties[indexPath.row]
                let why = report?.matches.first { $0.propertyId == property.id }?.why ?? ""
                config.text = "\(indexPath.row + 1). \(property.title)"
                config.secondaryText = "\(property.priceText) · \(property.location)\n\(property.detailSpecsText)\n\(why)"
                config.secondaryTextProperties.numberOfLines = 0
                config.image = UIImage(named: property.imageName)
                config.imageProperties.maximumSize = CGSize(width: 56, height: 56)
                config.imageProperties.cornerRadius = 8
                cell.accessoryType = .disclosureIndicator
            }
        } else {
            let titles = ["Save".localized, "Request more information".localized, "Message realtor".localized]
            config.text = titles[indexPath.row]
            cell.accessoryType = .disclosureIndicator
        }
        cell.contentConfiguration = config
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1, properties.indices.contains(indexPath.row) {
            openPropertyDetails(properties[indexPath.row])
            return
        }
        guard indexPath.section == 2 else { return }
        switch indexPath.row {
        case 0:
            properties.forEach { property in
                if !PropertyStore.shared.isFavorite(property.id) {
                    PropertyStore.shared.toggleFavorite(property.id)
                }
            }
            presentOK("Saved".localized, "These listings were added to your favorites.".localized)
        case 1:
            requestMoreInfo()
        default:
            messageRealtor()
        }
    }

    private func requestMoreInfo() {
        guard let property = properties.first, let request = RealtorDesk.shared.buyerActiveRequest else { return }
        PropertyStore.shared.addEnquiry(
            property: property,
            name: TenantAccount.shared.name,
            email: TenantAccount.shared.email,
            phone: TenantAccount.shared.phone,
            message: "Please send more information on the recommended listings.".localized,
            kind: .moreInformation,
            requestId: request.id
        )
        presentOK("Request sent".localized, "Your SpeddyProp realtor will follow up.".localized)
    }

    private func messageRealtor() {
        guard let request = RealtorDesk.shared.buyerActiveRequest else { return }
        let alert = UIAlertController(title: "Message realtor".localized, message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Message".localized }
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "Send".localized, style: .default) { _ in
            let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !text.isEmpty else { return }
            RealtorDesk.shared.addMessage(requestId: request.id, fromBuyer: true, text: text)
            AgentStore.shared.recordBuyerMessage(request: request, text: text)
        })
        present(alert, animated: true)
    }

    private func presentOK(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
        present(alert, animated: true)
    }
}
