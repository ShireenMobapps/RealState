//
//  AgentClientMatchVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class AgentClientRequestsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var items: [RealtorAssistanceRequest] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Client requests".localized
        view.backgroundColor = .screenBackgroundColor
        navigationController?.navigationBar.tintColor = .darkThemeColor
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .screenBackgroundColor
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        items = RealtorDesk.shared.inboundRequests()
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(items.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        if items.isEmpty {
            config.text = "No client requests yet.".localized
            cell.selectionStyle = .none
            cell.accessoryType = .none
        } else {
            let item = items[indexPath.row]
            config.text = "\(item.buyerName) · \(item.status.rawValue.localized)"
            config.secondaryText = item.requirement.summaryText
            config.secondaryTextProperties.numberOfLines = 0
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        }
        cell.contentConfiguration = config
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard items.indices.contains(indexPath.row) else { return }
        let detail = AgentClientRequestDetailVC()
        detail.requestId = items[indexPath.row].id
        navigationController?.pushViewController(detail, animated: true)
    }
}

final class AgentClientRequestDetailVC: UIViewController {

    var requestId: String = ""
    private let scroll = UIScrollView()
    private let stack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Client request".localized
        view.backgroundColor = .screenBackgroundColor
        navigationController?.navigationBar.tintColor = .darkThemeColor
        scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        view.addSubview(scroll)
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -32),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40)
        ])
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        reload()
    }

    private func reload() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let request = RealtorDesk.shared.requests.first(where: { $0.id == requestId }) else { return }
        stack.addArrangedSubview(infoCard(title: "New Client Request".localized, body: """
        \("Client".localized): \(request.buyerName)
        \(request.buyerEmail)
        \(request.buyerPhone)

        \("Looking for:".localized)
        \(request.requirement.summaryText)
        """))
        stack.addArrangedSubview(action("Search centralized inventory".localized, #selector(searchInventory)))
        stack.addArrangedSubview(action("AI search for this client".localized, #selector(aiSearch)))
        stack.addArrangedSubview(action("Review AI ranking".localized, #selector(reviewRanking)))
        stack.addArrangedSubview(action("Create client report".localized, #selector(createReport)))
        let note = UILabel()
        note.text = "Saving a listing only shortlists it for this client. It does not make you the listing agent or owner.".localized
        note.font = .systemFont(ofSize: 13, weight: .regular)
        note.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)
        note.numberOfLines = 0
        stack.addArrangedSubview(note)
    }

    @objc private func searchInventory() {
        guard let request = RealtorDesk.shared.requests.first(where: { $0.id == requestId }) else { return }
        RealtorDesk.shared.setActiveRequest(request.id)
        RealtorDesk.shared.activeLeadId = RealtorDesk.shared.leads.first(where: { $0.assistanceRequestId == request.id })?.id
        tabBarController?.selectedIndex = 1
        navigationController?.popToRootViewController(animated: true)
    }

    @objc private func aiSearch() {
        guard let request = RealtorDesk.shared.requests.first(where: { $0.id == requestId }) else { return }
        RealtorDesk.shared.setActiveRequest(request.id)
        RealtorDesk.shared.activeLeadId = RealtorDesk.shared.leads.first(where: { $0.assistanceRequestId == request.id })?.id
        openAISearch(
            prefilled: request.requirement.query.isEmpty ? request.requirement.oneLine : request.requirement.query,
            approveLeadIfNeeded: true
        )
    }

    @objc private func reviewRanking() {
        let vc = AgentRecommendationReviewVC()
        vc.requestId = requestId
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func createReport() {
        let vc = AgentRecommendationReviewVC()
        vc.requestId = requestId
        navigationController?.pushViewController(vc, animated: true)
    }

    private func infoCard(title: String, body: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .darkThemeColor
        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.font = .systemFont(ofSize: 15, weight: .regular)
        bodyLabel.numberOfLines = 0
        let inner = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        inner.axis = .vertical
        inner.spacing = 8
        inner.translatesAutoresizingMaskIntoConstraints = false
        let card = UIView()
        card.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            inner.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            inner.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            inner.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        CommonMethods.styleFormCard(card)
        return card
    }

    private func action(_ title: String, _ selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .darkThemeColor
        button.layer.cornerRadius = 14
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        button.addTarget(self, action: selector, for: .touchUpInside)
        return button
    }
}

final class AgentRecommendationReviewVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var requestId: String?
    private var report: ClientFacingReport?
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AI ranking".localized
        view.backgroundColor = .screenBackgroundColor
        navigationController?.navigationBar.tintColor = .darkThemeColor
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .screenBackgroundColor
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Send to buyer".localized,
            style: .done,
            target: self,
            action: #selector(sendTapped)
        )
        buildDraft()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func buildDraft() {
        let request = requestId.flatMap { id in RealtorDesk.shared.requests.first { $0.id == id } }
            ?? RealtorDesk.shared.activeRequest
            ?? RealtorDesk.shared.inboundRequests().first
        guard let request else { return }
        RealtorDesk.shared.setActiveRequest(request.id)
        let shortlist = AgentStore.shared.favoriteProperties()
        let compared = AgentStore.shared.comparedProperties()
        let pool = compared.count >= 2 ? compared : (shortlist.isEmpty ? PropertyStore.shared.all : shortlist)
        report = RealtorDesk.shared.draftReport(request: request, properties: pool)
        tableView.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? (report?.matches.count ?? 0) : 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Top 3 · Why this property?".localized : "AI comparison".localized
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        if indexPath.section == 1 {
            config.text = report?.comparisonSummary
            config.textProperties.numberOfLines = 0
            cell.selectionStyle = .none
            cell.accessoryType = .none
        } else if let match = report?.matches[indexPath.row],
                  let property = PropertyStore.shared.all.first(where: { $0.id == match.propertyId }) {
            config.text = "\(match.rank). \(property.title)"
            config.secondaryText = """
            \(property.priceText) · \(property.location) · \(property.source)
            \(property.detailSpecsText)
            \("Why this property?".localized) \(match.why)
            \(match.approved ? "Approved".localized : "Tap to approve".localized)
            """
            config.secondaryTextProperties.numberOfLines = 0
            config.image = UIImage(named: property.imageName)
            config.imageProperties.maximumSize = CGSize(width: 56, height: 56)
            config.imageProperties.cornerRadius = 8
            cell.accessoryType = match.approved ? .checkmark : .none
            cell.tintColor = .darkThemeColor
        }
        cell.contentConfiguration = config
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 0, report != nil else { return }
        report?.matches[indexPath.row].approved.toggle()
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    @objc private func sendTapped() {
        guard var report else { return }
        let approved = report.matches.filter(\.approved)
        guard !approved.isEmpty else {
            let alert = UIAlertController(title: "Approve listings first".localized, message: "Review and approve the properties before sharing with the buyer.".localized, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
            present(alert, animated: true)
            return
        }
        report.matches = approved
        let items = approved.compactMap { match in PropertyStore.shared.all.first { $0.id == match.propertyId } }
        report.comparisonSummary = PropertyStore.shared.comparisonSummary(for: items)
        RealtorDesk.shared.shareReport(report)
        let alert = UIAlertController(
            title: "Sent to buyer".localized,
            message: "The client-facing report is now available in the buyer's app.".localized,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}
