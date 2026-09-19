//
//  AgentLeadsVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class AgentLeadsVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!

    private let spinner = UIActivityIndicatorView(style: .medium)
    private let searchField = CustomTextField()
    private var searchHeightConstraint: NSLayoutConstraint?
    private var tableTopToSearch: NSLayoutConstraint?
    private var tableTopToSafe: NSLayoutConstraint?
    private let searchVisibleLimit = 3
    private var leads: [PlatformLead] = []
    private var filterRecord: [PlatformLead] = []
    private var loadToken = UUID()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Leads".localized
        view.backgroundColor = .screenBackgroundColor
        navigationController?.navigationBar.tintColor = .darkThemeColor
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.layoutMargins = .zero
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 108
        tableView.register(BuyerLeadCell.self, forCellReuseIdentifier: BuyerLeadCell.identifier)
        tableView.keyboardDismissMode = .onDrag
        emptyLabel.text = "No data found".localized
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.font = .systemFont(ofSize: 15, weight: .regular)
        emptyLabel.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)
        emptyLabel.isHidden = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        installSearchBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        loadLeads()
    }

    private func installSearchBar() {
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.placeholder = "Search by name, email, phone or message".localized
        searchField.returnKeyType = .search
        searchField.clearButtonMode = .whileEditing
        searchField.delegate = self
        searchField.addTarget(self, action: #selector(keywordChanged), for: .editingChanged)
        CommonMethods.styleTextField(searchField)
        searchField.leftPadding = 40
        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        icon.tintColor = UIColor.darkThemeColor.withAlphaComponent(0.45)
        icon.contentMode = .scaleAspectFit
        let wrap = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 24))
        icon.frame = CGRect(x: 12, y: 2, width: 20, height: 20)
        wrap.addSubview(icon)
        searchField.leftView = wrap
        searchField.leftViewMode = .always
        view.addSubview(searchField)

        view.constraints
            .filter { ($0.firstItem as? UIView) === tableView && $0.firstAttribute == .top }
            .forEach { $0.isActive = false }

        let height = searchField.heightAnchor.constraint(equalToConstant: 0)
        searchHeightConstraint = height
        tableTopToSearch = tableView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 0)
        tableTopToSafe = tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8)

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            height,
            tableTopToSafe!
        ])
        searchField.isHidden = true
        searchField.alpha = 0
    }

    private func updateSearchVisibility() {
        let show = leads.count > searchVisibleLimit
        searchField.isHidden = !show
        searchField.alpha = show ? 1 : 0
        searchHeightConstraint?.constant = show ? 44 : 0
        tableTopToSearch?.constant = show ? 8 : 0
        tableTopToSearch?.isActive = show
        tableTopToSafe?.isActive = !show
        if !show {
            searchField.text = nil
            searchField.resignFirstResponder()
        }
        view.layoutIfNeeded()
    }

    @objc private func keywordChanged() {
        applyKeywordFilter()
    }

    private func applyKeywordFilter() {
        let keyword = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        filterRecord = keyword.isEmpty ? leads : leads.filter { $0.matchesLeadSearch(keyword) }
        emptyLabel.text = "No data found".localized
        emptyLabel.isHidden = spinner.isAnimating || !filterRecord.isEmpty
        tableView.reloadData()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        applyKeywordFilter()
        return true
    }

    private func loadLeads() {
        let token = UUID()
        loadToken = token
        spinner.startAnimating()
        emptyLabel.isHidden = true
        Task {
            do {
                let remote = try await AgentViewModels.agentLeadsAPI(page: 1, limit: 10)
                await MainActor.run {
                    guard self.loadToken == token else { return }
                    self.applyLeads(remote)
                }
            } catch {
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
        AgentStore.shared.replaceLeads(from: remote)
        updateSearchVisibility()
        applyKeywordFilter()
    }

    private func changeLeadStatus(_ lead: PlatformLead, status: String) {
        spinner.startAnimating()
        tableView.isUserInteractionEnabled = false
        Task {
            do {
                try await AgentViewModels.updateLeadStatusAPI(id: lead.id, status: status)
                await MainActor.run {
                    self.tableView.isUserInteractionEnabled = true
                    if let index = self.leads.firstIndex(where: { $0.id == lead.id }) {
                        self.leads[index].apiStatus = status
                    }
                    self.applyKeywordFilter()
                    self.loadLeads()
                }
            } catch {
                await MainActor.run {
                    self.spinner.stopAnimating()
                    self.tableView.isUserInteractionEnabled = true
                    let message = ((error as? APIError)?.errorDescription ?? error.localizedDescription)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    CommonMethods.showAlert(
                        message: message.isEmpty ? "Unable to update lead status. Please try again.".localized : message,
                        from: self
                    )
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filterRecord.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BuyerLeadCell.identifier, for: indexPath) as! BuyerLeadCell
        let lead = filterRecord[indexPath.row]
        cell.configureForAgent(lead) { [weak self] status in
            self?.changeLeadStatus(lead, status: status)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let lead = filterRecord[indexPath.row]
        RealtorDesk.shared.setActiveLead(lead.id)
        let vc: AgentLeadDetailVC = AgentStoryboard.load("AgentLeadDetailVC")
        vc.leadID = lead.id
        navigationController?.pushViewController(vc, animated: true)
    }
}

final class AgentLeadDetailVC: UIViewController {

    var leadID: String = ""
    @IBOutlet weak var status: UISegmentedControl!
    @IBOutlet weak var body: UILabel!

    private let detailsStack = UIStackView()
    private let actionsStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Lead".localized
        view.backgroundColor = .screenBackgroundColor
        navigationController?.navigationBar.tintColor = .darkThemeColor
        status.isHidden = true
        status.isUserInteractionEnabled = false
        body.isHidden = true
        installLayout()
        populate()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        if leadID.isEmpty == false {
            RealtorDesk.shared.setActiveLead(leadID)
        }
        populate()
    }

    private func installLayout() {
        detailsStack.axis = .vertical
        detailsStack.spacing = 16
        detailsStack.translatesAutoresizingMaskIntoConstraints = false

        actionsStack.axis = .vertical
        actionsStack.spacing = 10
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        [
            actionButton("Search properties with AI".localized, #selector(searchTapped)),
            actionButton("Contact Buyer via WhatsApp".localized, #selector(whatsAppTapped))
        ].forEach { actionsStack.addArrangedSubview($0) }

        view.addSubview(detailsStack)
        view.addSubview(actionsStack)
        NSLayoutConstraint.activate([
            detailsStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            detailsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            detailsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            actionsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            actionsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            actionsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            detailsStack.bottomAnchor.constraint(lessThanOrEqualTo: actionsStack.topAnchor, constant: -20)
        ])
    }

    private func populate() {
        detailsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let lead = AgentStore.shared.leads.first(where: { $0.id == leadID }) else {
            detailsStack.addArrangedSubview(sectionCard(
                title: "Lead".localized,
                body: "This lead is no longer available.".localized
            ))
            actionsStack.isHidden = true
            return
        }

        let status = lead.apiStatus.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let showActions = status == "approved"
        actionsStack.isHidden = !showActions
        actionsStack.arrangedSubviews.forEach { $0.isHidden = !showActions }

        let contactLines = [lead.clientName, lead.email, lead.phone]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        detailsStack.addArrangedSubview(sectionCard(
            title: "Buyer details".localized,
            body: contactLines.isEmpty ? "No buyer details.".localized : contactLines
        ))

        var requirementLines: [String] = []
        if !lead.propertyTitle.isEmpty {
            requirementLines.append("\("Property".localized): \(lead.propertyTitle)")
        }
        requirementLines.append("\("Type".localized): \(lead.kind.rawValue.localized)")
        if let listingAgent = lead.listingAgentName, !listingAgent.isEmpty {
            requirementLines.append("\("Source listing agent".localized): \(listingAgent)")
        }
        let message = lead.message.trimmingCharacters(in: .whitespacesAndNewlines)
        if !message.isEmpty {
            requirementLines.append(message)
        }
        detailsStack.addArrangedSubview(sectionCard(
            title: "Requirements".localized,
            body: requirementLines.joined(separator: "\n")
        ))
    }

    private func sectionCard(title: String, body: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .darkThemeColor
        titleLabel.numberOfLines = 0

        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.font = .systemFont(ofSize: 14, weight: .regular)
        bodyLabel.textColor = UIColor(red: 73/255, green: 80/255, blue: 87/255, alpha: 1)
        bodyLabel.numberOfLines = 0

        let inner = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        inner.axis = .vertical
        inner.spacing = 8
        inner.translatesAutoresizingMaskIntoConstraints = false

        let card = UIView()
        card.addSubview(inner)
        CommonMethods.styleFormCard(card)
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            inner.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            inner.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            inner.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func actionButton(_ title: String, _ selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.backgroundColor = .darkThemeColor
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: selector, for: .touchUpInside)
        return button
    }

    @objc private func searchTapped() {
        let lead = AgentStore.shared.leads.first(where: { $0.id == leadID })
        RealtorDesk.shared.setActiveLead(leadID)
        if let requestId = lead?.requestId {
            RealtorDesk.shared.setActiveRequest(requestId)
        }
        openAISearch(prefilled: Self.searchQuery(from: lead), approveLeadIfNeeded: true)
    }

    private static func searchQuery(from lead: AgentLead?) -> String? {
        let query = lead?.message.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard query.isEmpty == false else { return nil }
        if query.caseInsensitiveCompare("No requirements yet.".localized) == .orderedSame {
            return nil
        }
        return query
    }

    @objc private func whatsAppTapped() {
        guard let lead = AgentStore.shared.leads.first(where: { $0.id == leadID }) else { return }
        let digits = lead.phone.filter(\.isNumber)
        let text = "Hi \(lead.clientName), this is \(AgentAccount.shared.name) from SpeddyProp. I received your inquiry and can help with your search."
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "whatsapp://send?phone=\(digits)&text=\(encoded)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: "https://wa.me/\(digits)?text=\(encoded)") {
            UIApplication.shared.open(url)
        }
        if let platform = RealtorDesk.shared.leads.first(where: { $0.id == lead.id || $0.assistanceRequestId == lead.requestId }) {
            RealtorDesk.shared.addContact(leadId: platform.id, method: .whatsapp, message: text, notes: "Realtor contacted buyer", fromBuyer: false)
            AgentStore.shared.setLeadStatus(id: leadID, status: .contacted)
        }
    }
}
