//
//  AgentReportVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class AgentReportVC: UIViewController {

    var properties: [PropertyItem] = []
    var clientName: String?
    var lockedLeadId: String?

    @IBOutlet weak var clientField: CustomTextField!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var shareButton: CustomButton!
    @IBOutlet weak var reportCardView: CustomView!

    private var clients: [ReportClient] = []
    private var selectedClient: ReportClient?
    private var loadToken = UUID()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let clientNameLabel = UILabel()
    private let clientDetailLabel = UILabel()
    private var clientBanner: UIView?
    private weak var changeClientButton: UIButton?
    private weak var clientCardControl: UIControl?

    struct ReportClient {
        let id: String
        let name: String
        let email: String
        let phone: String
        let message: String

        init(id: String, name: String, email: String, phone: String, message: String = "") {
            self.id = id
            self.name = name
            self.email = email
            self.phone = phone
            self.message = message
        }

        var rowTitle: String {
            let extras = [email, phone].filter { !$0.isEmpty }
            if extras.isEmpty { return name }
            return "\(name) — \(extras.joined(separator: " · "))"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Client report".localized
        view.backgroundColor = .screenBackgroundColor
        navigationController?.navigationBar.tintColor = .darkThemeColor
        CommonMethods.styleTextField(clientField)
        clientField.font = .systemFont(ofSize: 14, weight: .medium)
        clientField.layer.cornerRadius = 10
        clientField.leftPadding = 12
        CommonMethods.stylePrimaryButton(shareButton)
        CommonMethods.styleFormCard(reportCardView)
        bodyLabel.numberOfLines = 0
        bodyLabel.lineBreakMode = .byWordWrapping
        installSpinner()
        installClientBanner()
        if let locked = clientForActiveLead() {
            selectClient(locked)
        } else if let name = clientName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            selectClient(named: name)
        } else if let latest = latestClient() {
            selectClient(latest)
        } else {
            clientField.text = nil
        }
        updateClientBanner()
        refresh()
        loadClients()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CommonMethods.updateGradientFrame(for: shareButton)
    }

    private func installSpinner() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        spinner.color = .darkThemeColor
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func installClientBanner() {
        clientField.isHidden = true
        clientField.isUserInteractionEnabled = false
        clientField.constraints.filter { $0.firstAttribute == .height }.forEach { $0.constant = 0 }

        let title = UILabel()
        title.text = "Share with".localized
        title.font = .systemFont(ofSize: 12, weight: .semibold)
        title.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)
        clientNameLabel.font = .systemFont(ofSize: 16, weight: .bold)
        clientNameLabel.textColor = .darkThemeColor
        clientDetailLabel.font = .systemFont(ofSize: 13, weight: .regular)
        clientDetailLabel.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)
        clientDetailLabel.numberOfLines = 2
        let change = UIButton(type: .system)
        change.setTitle("Change".localized, for: .normal)
        change.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        change.setTitleColor(.darkThemeColor, for: .normal)
        change.addTarget(self, action: #selector(pickClient), for: .touchUpInside)
        changeClientButton = change
        let text = UIStackView(arrangedSubviews: [title, clientNameLabel, clientDetailLabel])
        text.axis = .vertical
        text.spacing = 2
        let row = UIStackView(arrangedSubviews: [text, change])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false
        let card = UIControl()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        card.addTarget(self, action: #selector(pickClient), for: .touchUpInside)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
        CommonMethods.styleFormCard(card)
        view.addSubview(card)
        clientBanner = card
        clientCardControl = card

        guard let scroll = reportCardView.superview as? UIScrollView else { return }
        view.constraints.filter { constraint in
            (constraint.firstItem === scroll && constraint.firstAttribute == .top)
                || (constraint.secondItem === scroll && constraint.secondAttribute == .top)
        }.forEach { $0.isActive = false }
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            card.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            scroll.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 16)
        ])
        view.bringSubviewToFront(shareButton)
        view.bringSubviewToFront(spinner)
    }

    private func updateClientBanner() {
        let selected = selectedClient ?? matchingClient()
        let name = selected?.name ?? clientField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        clientNameLabel.text = name.isEmpty ? "Choose a client".localized : name
        let extras = [selected?.email, selected?.phone].compactMap { $0 }.filter { !$0.isEmpty }
        clientDetailLabel.text = extras.isEmpty ? nil : extras.joined(separator: " · ")
        clientDetailLabel.isHidden = extras.isEmpty
        changeClientButton?.isHidden = false
        clientCardControl?.isUserInteractionEnabled = true
    }

    private var resolvedLeadId: String {
        let explicit = lockedLeadId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if explicit.isEmpty == false { return explicit }
        return RealtorDesk.shared.activeLeadId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func isApprovedLeadStatus(_ status: String) -> Bool {
        status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "approved"
    }

    private func clientForActiveLead() -> ReportClient? {
        let leadId = resolvedLeadId
        guard leadId.isEmpty == false else { return nil }
        if let lead = AgentStore.shared.leads.first(where: { $0.id == leadId }),
           isApprovedLeadStatus(lead.apiStatus) {
            return ReportClient(id: lead.id, name: lead.clientName, email: lead.email, phone: lead.phone, message: lead.message)
        }
        if let lead = RealtorDesk.shared.leads.first(where: { $0.id == leadId }),
           isApprovedLeadStatus(lead.apiStatus) {
            return ReportClient(id: lead.id, name: lead.buyerName, email: lead.buyerEmail, phone: lead.buyerPhone, message: lead.requirements)
        }
        if let lead = RealtorDesk.shared.leads.first(where: { $0.assistanceRequestId == leadId }),
           isApprovedLeadStatus(lead.apiStatus) {
            return ReportClient(id: lead.id, name: lead.buyerName, email: lead.buyerEmail, phone: lead.buyerPhone, message: lead.requirements)
        }
        return nil
    }

    private func matchingClient() -> ReportClient? {
        if let selectedClient { return selectedClient }
        let name = clientField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard name.isEmpty == false else { return clients.first }
        return clients.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    private func latestClient() -> ReportClient? {
        if let lead = AgentStore.shared.leads.first(where: { isApprovedLeadStatus($0.apiStatus) }) {
            return ReportClient(id: lead.id, name: lead.clientName, email: lead.email, phone: lead.phone, message: lead.message)
        }
        if let lead = RealtorDesk.shared.leads.first(where: { isApprovedLeadStatus($0.apiStatus) }) {
            return ReportClient(id: lead.id, name: lead.buyerName, email: lead.buyerEmail, phone: lead.buyerPhone, message: lead.requirements)
        }
        return clients.first
    }

    private func loadClients() {
        applyClients([])
        let token = UUID()
        loadToken = token
        Task {
            let remote = (try? await AgentViewModels.agentLeadsAPI(status: "approved", page: 1, limit: 50)) ?? []
            await MainActor.run {
                guard self.loadToken == token else { return }
                self.applyClients(remote)
            }
        }
    }

    private func applyClients(_ remote: [PlatformLead]) {
        var seen = Set<String>()
        var list: [ReportClient] = []
        for lead in remote where isApprovedLeadStatus(lead.apiStatus) {
            let leadId = lead.id.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedName = lead.buyerName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedEmail = lead.buyerEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedPhone = lead.buyerPhone.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedMessage = lead.requirements.trimmingCharacters(in: .whitespacesAndNewlines)
            let displayName = trimmedName.isEmpty
                ? (trimmedEmail.isEmpty ? trimmedPhone : trimmedEmail)
                : trimmedName
            guard displayName.isEmpty == false
                    || trimmedEmail.isEmpty == false
                    || trimmedPhone.isEmpty == false
                    || trimmedMessage.isEmpty == false else { continue }
            let key = leadId.isEmpty == false
                ? leadId
                : [trimmedEmail.lowercased(), trimmedPhone, displayName.lowercased()]
                    .filter { !$0.isEmpty }
                    .joined(separator: "|")
            guard seen.insert(key).inserted else { continue }
            list.append(
                ReportClient(
                    id: leadId,
                    name: displayName,
                    email: trimmedEmail,
                    phone: trimmedPhone,
                    message: trimmedMessage
                )
            )
        }
        clients = list
        if let locked = clientForActiveLead(),
           let match = list.first(where: { $0.id == locked.id && locked.id.isEmpty == false })
            ?? list.first(where: { $0.name.caseInsensitiveCompare(locked.name) == .orderedSame }) {
            selectClient(match)
            return
        }
        if let selectedClient,
           let match = clients.first(where: { $0.id == selectedClient.id && selectedClient.id.isEmpty == false })
            ?? clients.first(where: { $0.name.caseInsensitiveCompare(selectedClient.name) == .orderedSame }) {
            selectClient(match)
        } else if let first = clients.first {
            selectClient(first)
        } else {
            selectedClient = nil
            clientName = nil
            clientField.text = nil
            updateClientBanner()
            refresh()
        }
    }

    @objc private func pickClient() {
        clientField.resignFirstResponder()
        let sheet = ClientListSheetVC(
            clients: clients,
            selectedId: selectedClient?.id,
            selectedName: clientField.text
        ) { [weak self] client in
            self?.selectClient(client)
        }
        present(sheet, animated: true)
    }

    private func enterClientName() {
        let alert = UIAlertController(title: "Client name".localized, message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Client name".localized
            field.text = self.clientField.text
            field.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "Done".localized, style: .default) { [weak self, weak alert] _ in
            self?.selectClient(named: alert?.textFields?.first?.text ?? "")
        })
        present(alert, animated: true)
    }

    private func selectClient(_ client: ReportClient) {
        selectedClient = client
        clientName = client.name.isEmpty ? nil : client.name
        clientField.text = clientName
        updateClientBanner()
        refresh()
    }

    private func selectClient(named name: String, detail: String? = nil) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = clients.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            selectClient(match)
            return
        }
        selectClient(ReportClient(id: "", name: trimmed, email: "", phone: ""))
        if let detail, clientDetailLabel.text == nil || (clientDetailLabel.text ?? "").isEmpty {
            clientDetailLabel.text = detail
            clientDetailLabel.isHidden = detail.isEmpty
        }
    }

    @objc func refresh() {
        let name = selectedClient?.name ?? clientField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        bodyLabel.text = AgentMarketingCopy.clientReport(
            for: properties,
            client: (name?.isEmpty == false) ? name! : "Select a client".localized
        )
    }

    @IBAction func shareTapped(_ sender: Any) {
        if selectedClient == nil {
            selectClient(named: clientField.text ?? "")
        }
        let name = selectedClient?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else {
            pickClient()
            return
        }
        refresh()
        shareReportPDF()
    }

    private func markSelectedLeadQualifiedAndGoHome() {
        var leadId = selectedClient?.id.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if leadId.isEmpty {
            leadId = matchingClient()?.id.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        guard leadId.isEmpty == false else {
            goToAgentHome()
            return
        }
        spinner.startAnimating()
        shareButton.isEnabled = false
        view.isUserInteractionEnabled = false
        Task {
            do {
                try await AgentViewModels.updateLeadStatusAPI(id: leadId, status: "qualified")
                await MainActor.run {
                    self.spinner.stopAnimating()
                    self.goToAgentHome()
                }
            } catch {
                await MainActor.run {
                    self.spinner.stopAnimating()
                    self.shareButton.isEnabled = true
                    self.view.isUserInteractionEnabled = true
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

    private func goToAgentHome() {
        let tab = tabBarController
        navigationController?.popToRootViewController(animated: false)
        tab?.selectedIndex = 0
        (tab?.viewControllers?[0] as? UINavigationController)?.popToRootViewController(animated: false)
    }

    private func shareReportPDF() {
        spinner.startAnimating()
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            defer {
                self.spinner.stopAnimating()
                self.view.isUserInteractionEnabled = true
            }
            guard let fileURL = self.writeReportPDF() else {
                CommonMethods.showAlert(message: "Could not create report PDF.".localized, from: self)
                return
            }
            let activity = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            if let popover = activity.popoverPresentationController {
                popover.sourceView = self.shareButton
                popover.sourceRect = self.shareButton?.bounds ?? CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY - 80, width: 1, height: 1)
            }
            activity.completionWithItemsHandler = { [weak self] _, completed, _, error in
                guard completed, error == nil else { return }
                DispatchQueue.main.async {
                    self?.showShareSuccessAlert()
                }
            }
            self.present(activity, animated: true)
        }
    }

    private func showShareSuccessAlert() {
        CommonMethods.showAlert(
            message: "Report sent successfully.".localized,
            from: self
        ) { [weak self] in
            self?.markSelectedLeadQualifiedAndGoHome()
        }
    }

    private func writeReportPDF() -> URL? {
        view.layoutIfNeeded()
        guard let card = reportCardView else { return nil }
        let width = max(card.bounds.width, view.bounds.width - 40, 320)
        let fitting = card.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        let contentHeight = max(fitting.height, card.bounds.height, 1)
        let contentSize = CGSize(width: width, height: contentHeight)

        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 24
        let drawableWidth = pageWidth - (margin * 2)
        let scale = drawableWidth / contentSize.width
        let scaledHeight = contentSize.height * scale
        let pageContentHeight = pageHeight - (margin * 2)

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        let data = renderer.pdfData { context in
            var offset: CGFloat = 0
            while offset < scaledHeight {
                context.beginPage()
                let cg = context.cgContext
                cg.saveGState()
                cg.translateBy(x: margin, y: margin - offset)
                cg.scaleBy(x: scale, y: scale)
                card.layer.render(in: cg)
                cg.restoreGState()
                offset += pageContentHeight
            }
        }

        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Reports", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let safeName = (clientField.text ?? "Client")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: " ", with: "-")
        let fileURL = folder.appendingPathComponent("Client-Report-\(safeName)-\(formatter.string(from: Date())).pdf")
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return nil
        }
    }

    private func sendToBuyer() {
        guard persistSharedReport() else { return }
        let alert = UIAlertController(title: "Sent to buyer".localized, message: "The client-facing report is now available in the buyer's app.".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
        present(alert, animated: true)
    }

    @discardableResult
    private func persistSharedReport() -> Bool {
        let request = RealtorDesk.shared.activeRequest ?? RealtorDesk.shared.inboundRequests().first
        guard let request else {
            let alert = UIAlertController(title: "No client request".localized, message: "Open a client request first, then approve the AI ranking before sending.".localized, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
            present(alert, animated: true)
            return false
        }
        var report = RealtorDesk.shared.draftReport(request: request, properties: properties)
        report.matches = report.matches.map { match in
            var next = match
            next.approved = true
            return next
        }
        RealtorDesk.shared.shareReport(report)
        if let lead = RealtorDesk.shared.leads.first(where: { $0.assistanceRequestId == request.id }) {
            RealtorDesk.shared.updateLeadStatus(id: lead.id, status: .viewing)
        }
        return true
    }

    private func shareWhatsApp() {
        guard persistSharedReport() else { return }
        let text = bodyLabel.text ?? ""
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "whatsapp://send?text=\(encoded)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return
        }
        present(UIActivityViewController(activityItems: [text], applicationActivities: nil), animated: true)
    }

    private func shareEmail() {
        guard persistSharedReport() else { return }
        let text = bodyLabel.text ?? ""
        let subject = "Property recommendations".localized.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:?subject=\(subject)&body=\(body)") {
            UIApplication.shared.open(url)
        }
    }
}

private final class ClientListSheetVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let clients: [AgentReportVC.ReportClient]
    private let selectedId: String
    private let selectedName: String
    private let onSelect: (AgentReportVC.ReportClient) -> Void
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let subtitleLabel = UILabel()

    init(
        clients: [AgentReportVC.ReportClient],
        selectedId: String?,
        selectedName: String?,
        onSelect: @escaping (AgentReportVC.ReportClient) -> Void
    ) {
        self.clients = clients
        self.selectedId = selectedId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.selectedName = selectedName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            if #available(iOS 16.0, *) {
                sheet.prefersEdgeAttachedInCompactHeight = true
                sheet.preferredCornerRadius = 20
                sheet.selectedDetentIdentifier = .medium
            }
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .screenBackgroundColor
        installHeader()
        installTable()
    }

    private func installHeader() {
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = "Select a client".localized
        title.font = .systemFont(ofSize: 18, weight: .bold)
        title.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
        view.addSubview(title)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "The report will be prepared for the client you choose.".localized
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)
        subtitleLabel.numberOfLines = 0
        view.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            title.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            subtitleLabel.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: title.trailingAnchor)
        ])
    }

    private func installTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 108
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        tableView.register(ClientListSheetCell.self, forCellReuseIdentifier: ClientListSheetCell.identifier)
        view.addSubview(tableView)

        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = "No data found".localized
        emptyLabel.textAlignment = .center
        emptyLabel.font = .systemFont(ofSize: 15, weight: .medium)
        emptyLabel.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)
        emptyLabel.isHidden = !clients.isEmpty
        view.addSubview(emptyLabel)

        let subtitle = subtitleLabel
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
        tableView.isHidden = clients.isEmpty
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        clients.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ClientListSheetCell.identifier,
            for: indexPath
        ) as? ClientListSheetCell else {
            return UITableViewCell()
        }
        let client = clients[indexPath.row]
        let isSelected: Bool
        if selectedId.isEmpty == false, client.id.isEmpty == false {
            isSelected = client.id == selectedId
        } else {
            isSelected = client.name.caseInsensitiveCompare(selectedName) == .orderedSame
        }
        cell.configure(
            name: client.name,
            message: client.message,
            email: client.email,
            phone: client.phone,
            selected: isSelected
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let client = clients[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.onSelect(client)
        }
    }
}

private final class ClientListSheetCell: UITableViewCell {

    static let identifier = "ClientListSheetCell"

    private let cardView = UIView()
    private let nameLabel = UILabel()
    private let messageLabel = UILabel()
    private let detailLabel = UILabel()
    private let checkView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 14
        CommonMethods.styleFormCard(cardView)
        contentView.addSubview(cardView)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
        nameLabel.numberOfLines = 2
        cardView.addSubview(nameLabel)

        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = .systemFont(ofSize: 13, weight: .regular)
        messageLabel.textColor = UIColor(red: 73/255, green: 80/255, blue: 87/255, alpha: 1)
        messageLabel.numberOfLines = 3
        cardView.addSubview(messageLabel)

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = .systemFont(ofSize: 13, weight: .regular)
        detailLabel.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)
        detailLabel.numberOfLines = 2
        cardView.addSubview(detailLabel)

        checkView.translatesAutoresizingMaskIntoConstraints = false
        checkView.image = UIImage(systemName: "checkmark.circle.fill")
        checkView.tintColor = .darkThemeColor
        checkView.contentMode = .scaleAspectFit
        cardView.addSubview(checkView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            checkView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            checkView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            checkView.widthAnchor.constraint(equalToConstant: 22),
            checkView.heightAnchor.constraint(equalToConstant: 22),

            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: checkView.leadingAnchor, constant: -10),

            messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            detailLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 4),
            detailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            detailLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(name: String, message: String, email: String, phone: String, selected: Bool) {
        nameLabel.text = name
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        messageLabel.text = trimmedMessage
        messageLabel.isHidden = trimmedMessage.isEmpty
        let contact = [email, phone]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
        detailLabel.text = contact
        detailLabel.isHidden = contact.isEmpty
        checkView.isHidden = !selected
    }
}
