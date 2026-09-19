//
//  TenantCompareVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class TenantCompareVC: UIViewController {

    var properties: [PropertyItem] = []
    private var selectedClient: ShareClient?
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var loadToken = UUID()

    private struct ShareClient {
        let name: String
        let detail: String
        let requestId: String?
    }

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentStack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .screenBackgroundColor
        title = "Compare".localized
        navigationController?.navigationBar.tintColor = .darkThemeColor
        if selectedClient == nil, isAgentFlow {
            selectedClient = availableClients().first
        }
        setupSpinner()
        populate()
        loadComparison()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupSpinner() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        spinner.color = .darkThemeColor
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadComparison() {
        let ids = properties.map(\.id).filter { !$0.isEmpty }
        guard ids.count >= 2 else { return }

        let token = UUID()
        loadToken = token
        spinner.startAnimating()
        scrollView?.alpha = 0.35

        Task {
            do {
                let remote = try await TenantViewModels.comparePropertiesAPI(ids: ids)
                await MainActor.run {
                    guard self.loadToken == token else { return }
                    self.spinner.stopAnimating()
                    self.scrollView?.alpha = 1
                    if remote.count >= 2 {
                        self.properties = remote
                        self.populate()
                    }
                }
            } catch {
                await MainActor.run {
                    guard self.loadToken == token else { return }
                    self.spinner.stopAnimating()
                    self.scrollView?.alpha = 1
                }
            }
        }
    }

    private func populate() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        contentStack.addArrangedSubview(headerRow())
        rows().forEach { title, values in
            contentStack.addArrangedSubview(divider())
            contentStack.addArrangedSubview(valueRow(title: title.localized, values: values.map { $0.localized }))
        }
        contentStack.addArrangedSubview(spacer(16))
        contentStack.addArrangedSubview(summaryCard())
        contentStack.addArrangedSubview(spacer(12))
        if isAgentFlow {
            contentStack.addArrangedSubview(primaryActionButton(
                title: "Create client report".localized,
                action: #selector(openClientReport)
            ))
        } else {
            contentStack.addArrangedSubview(shareButton())
        }
        contentStack.addArrangedSubview(spacer(24))
    }

    private func headerRow() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        row.addArrangedSubview(columnLabel(" ", bold: true))
        properties.forEach { property in
            let photo = UIImageView()
            photo.contentMode = .scaleAspectFill
            photo.clipsToBounds = true
            photo.layer.cornerRadius = 10
            photo.heightAnchor.constraint(equalToConstant: 72).isActive = true
            let placeholder = UIImage(named: "propertyCityApartment")
            if property.imageName.lowercased().hasPrefix("http"),
               let url = URL(string: property.imageName) {
                photo.sd_setImage(with: url, placeholderImage: placeholder)
            } else {
                photo.image = UIImage(named: property.imageName) ?? placeholder
            }
            let name = UILabel()
            name.text = property.title
            name.font = .systemFont(ofSize: 12, weight: .semibold)
            name.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
            name.textAlignment = .center
            name.numberOfLines = 2
            let column = UIStackView(arrangedSubviews: [photo, name])
            column.axis = .vertical
            column.spacing = 6
            row.addArrangedSubview(column)
        }
        let padded = UIStackView(arrangedSubviews: [row])
        padded.isLayoutMarginsRelativeArrangement = true
        padded.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 12, right: 0)
        return padded
    }

    private func rows() -> [(String, [String])] {
        var items: [(String, [String])] = [
            ("Price", properties.map(\.priceText)),
            ("Location", properties.map(\.location)),
            ("Bedrooms", properties.map { "\($0.bedrooms)" }),
            ("Bathrooms", properties.map { "\($0.bathrooms)" }),
            ("Area", properties.map(\.area)),
            ("Cost / m²", properties.map(\.costPerSquareMeterText)),
            ("Furnished", properties.map(furnishedDisplayValue(for:)))
        ]
        amenityNamesFromAPI().forEach { name in
            items.append((name, properties.map { property in
                property.amenities.contains { $0.caseInsensitiveCompare(name) == .orderedSame } ? "Yes" : "No"
            }))
        }
        return items
    }

    /// Per-property text from that listing's API data only (no merge / no upgrade).
    private func furnishedDisplayValue(for property: PropertyItem) -> String {
        for amenity in property.amenities {
            let label = Self.furnishedLabel(from: amenity)
            if label != "No" { return label }
        }
        return Self.furnishedLabel(from: property.furnishedStatus)
    }

    private static func furnishedLabel(from raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "No" }
        let key = trimmed.lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        if key.contains("unfurnish") { return "No" }
        if key == "fully_furnished" || key == "fullyfurnished" { return "Fully Furnished" }
        if key == "semi_furnished" || key == "semifurnished" { return "Semi Furnished" }
        if key == "furnished" { return "Furnished" }
        if key.contains("fully") && key.contains("furnish") { return "Fully Furnished" }
        if key.contains("semi") && key.contains("furnish") { return "Semi Furnished" }
        if key.contains("furnish") { return "Furnished" }
        return "No"
    }

    /// Union of amenity names from the compare API (common + unique). Furnished variants go in the Furnished row.
    private func amenityNamesFromAPI() -> [String] {
        var seen = Set<String>()
        var names: [String] = []
        for property in properties {
            for amenity in property.amenities {
                let trimmed = amenity.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                guard Self.furnishedLabel(from: trimmed) == "No",
                      !trimmed.lowercased().contains("unfurnish") else { continue }
                if seen.insert(trimmed.lowercased()).inserted {
                    names.append(trimmed)
                }
            }
        }
        return names
    }

    private func valueRow(title: String, values: [String]) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        row.alignment = .top
        row.addArrangedSubview(columnLabel(title, bold: true))
        values.forEach { row.addArrangedSubview(columnLabel($0, bold: false)) }
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        return row
    }

    private func columnLabel(_ text: String, bold: Bool) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: bold ? .semibold : .regular)
        label.textColor = bold
            ? UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
            : UIColor(red: 73/255, green: 80/255, blue: 87/255, alpha: 1)
        label.numberOfLines = 0
        return label
    }

    private func divider() -> UIView {
        let line = UIView()
        line.backgroundColor = UIColor.cardBorderColor
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return line
    }

    private func spacer(_ height: CGFloat) -> UIView {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }

    private func summaryCard() -> UIView {
        let icon = UIImageView(image: UIImage(systemName: "sparkles"))
        icon.tintColor = .darkThemeColor
        let title = UILabel()
        title.text = "AI Summary".localized
        title.font = .systemFont(ofSize: 16, weight: .bold)
        title.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
        let header = UIStackView(arrangedSubviews: [icon, title, UIView()])
        header.axis = .horizontal
        header.spacing = 8
        header.alignment = .center

        let body = UILabel()
        body.text = PropertyStore.shared.comparisonSummary(for: properties)
        body.font = .systemFont(ofSize: 15, weight: .regular)
        body.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
        body.numberOfLines = 0

        let inner = UIStackView(arrangedSubviews: [header, body])
        inner.axis = .vertical
        inner.spacing = 10
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

    private func clientBanner() -> UIView {
        let title = UILabel()
        title.text = "Share with".localized
        title.font = .systemFont(ofSize: 12, weight: .semibold)
        title.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)
        let name = UILabel()
        name.text = selectedClient?.name ?? "Choose a client".localized
        name.font = .systemFont(ofSize: 16, weight: .bold)
        name.textColor = .darkThemeColor
        let detail = UILabel()
        detail.text = selectedClient?.detail
        detail.font = .systemFont(ofSize: 13, weight: .regular)
        detail.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)
        detail.numberOfLines = 2
        let change = UIButton(type: .system)
        change.setTitle("Change".localized, for: .normal)
        change.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        change.setTitleColor(.darkThemeColor, for: .normal)
        change.addTarget(self, action: #selector(changeClientTapped), for: .touchUpInside)
        let text = UIStackView(arrangedSubviews: [title, name, detail])
        text.axis = .vertical
        text.spacing = 2
        let row = UIStackView(arrangedSubviews: [text, change])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false
        let card = UIControl()
        card.addSubview(row)
        card.addTarget(self, action: #selector(changeClientTapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
        CommonMethods.styleFormCard(card)
        return card
    }

    private func availableClients() -> [ShareClient] {
        var items: [ShareClient] = []
        var seen = Set<String>()
        func add(_ client: ShareClient) {
            let key = client.name.lowercased()
            guard seen.insert(key).inserted else { return }
            items.append(client)
        }
        if let active = RealtorDesk.shared.activeRequest {
            add(ShareClient(
                name: active.buyerName,
                detail: "\("Active request".localized) · \(active.requirement.oneLine)",
                requestId: active.id
            ))
        }
        RealtorDesk.shared.inboundRequests().forEach { request in
            add(ShareClient(
                name: request.buyerName,
                detail: "\(request.status.rawValue.localized) · \(request.requirement.oneLine)",
                requestId: request.id
            ))
        }
        AgentStore.shared.leads.filter { $0.kind == .assistanceRequest || $0.status != .closed }.forEach { lead in
            add(ShareClient(name: lead.clientName, detail: lead.propertyTitle, requestId: lead.requestId))
        }
        AgentStore.shared.clientSearches.forEach { search in
            add(ShareClient(name: search.client, detail: search.query, requestId: nil))
        }
        return items
    }

    @objc private func changeClientTapped() {
        pickClient { [weak self] client in
            self?.selectedClient = client
            self?.populate()
        }
    }

    private func pickClient(then: @escaping (ShareClient) -> Void) {
        let sheet = UIAlertController(title: "Choose a client".localized, message: "Select who should receive this comparison.".localized, preferredStyle: .actionSheet)
        availableClients().forEach { client in
            let title = client.detail.isEmpty ? client.name : "\(client.name) — \(client.detail)"
            sheet.addAction(UIAlertAction(title: title, style: .default) { _ in
                then(client)
            })
        }
        sheet.addAction(UIAlertAction(title: "New client".localized, style: .default) { [weak self] _ in
            self?.promptNewClient(then: then)
        })
        sheet.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
        attachPopover(sheet)
        present(sheet, animated: true)
    }

    private func promptNewClient(then: @escaping (ShareClient) -> Void) {
        let alert = UIAlertController(title: "New client".localized, message: "Enter the client name.".localized, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Client name".localized }
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "Save".localized, style: .default) { [weak self] _ in
            let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !name.isEmpty else { return }
            AgentStore.shared.addClientSearch(client: name, query: "Comparison report".localized)
            then(ShareClient(name: name, detail: "Comparison report".localized, requestId: nil))
            self?.populate()
        })
        present(alert, animated: true)
    }

    private func shareButton() -> UIButton {
        primaryActionButton(
            title: isAgentFlow ? "Share with client".localized : "Save".localized,
            action: #selector(bottomActionTapped)
        )
    }

    private func primaryActionButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .darkThemeColor
        button.layer.cornerRadius = 14
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func openClientReport() {
        let vc: AgentReportVC = AgentStoryboard.load("AgentReportVC")
        vc.properties = properties
        vc.clientName = selectedClient?.name
        vc.lockedLeadId = RealtorDesk.shared.activeLeadId
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func bottomActionTapped() {
        if isAgentFlow {
            shareTapped()
        } else {
            saveComparisonToPhone()
        }
    }

    @objc private func shareTapped() {
        if isAgentFlow {
            if selectedClient == nil {
                pickClient { [weak self] client in
                    self?.selectedClient = client
                    self?.populate()
                    self?.showShareChannels()
                }
                return
            }
            showShareChannels()
            return
        }
        shareExternally()
    }

    private func saveComparisonToPhone() {
        spinner.startAnimating()
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            defer {
                self.spinner.stopAnimating()
                self.view.isUserInteractionEnabled = true
            }
            guard let fileURL = self.writeComparisonPDF() else {
                let alert = UIAlertController(
                    title: "Save".localized,
                    message: "Could not save comparison.".localized,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
                self.present(alert, animated: true)
                return
            }
            let activity = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            activity.completionWithItemsHandler = { [weak self] _, completed, _, _ in
                guard completed else { return }
                let alert = UIAlertController(
                    title: "Success".localized,
                    message: "Comparison saved to your phone.".localized,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
                self?.present(alert, animated: true)
            }
            if let popover = activity.popoverPresentationController {
                popover.sourceView = self.view
                popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY - 80, width: 1, height: 1)
            }
            self.present(activity, animated: true)
        }
    }

    private func writeComparisonPDF() -> URL? {
        view.layoutIfNeeded()
        guard let stack = contentStack else { return nil }

        let hiddenButtons = stack.arrangedSubviews.compactMap { $0 as? UIButton }
        hiddenButtons.forEach { $0.isHidden = true }
        defer { hiddenButtons.forEach { $0.isHidden = false } }
        stack.layoutIfNeeded()

        let width = max(stack.bounds.width, view.bounds.width - 40, 320)
        let fitting = stack.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        let contentHeight = max(fitting.height, stack.bounds.height, 1)
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
                stack.layer.render(in: cg)
                cg.restoreGState()
                offset += pageContentHeight
            }
        }

        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Comparisons", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let fileURL = folder.appendingPathComponent("Property-Compare-\(formatter.string(from: Date())).pdf")
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return nil
        }
    }

    private func showShareChannels() {
        let name = selectedClient?.name ?? "Client".localized
        let sheet = UIAlertController(
            title: "Share with %@".localized(name),
            message: "This comparison will be sent to this client.".localized,
            preferredStyle: .actionSheet
        )
        sheet.addAction(UIAlertAction(title: "Send to buyer".localized, style: .default) { [weak self] _ in
            self?.sendToBuyer()
        })
        sheet.addAction(UIAlertAction(title: "WhatsApp".localized, style: .default) { [weak self] _ in
            self?.shareWhatsApp()
        })
        sheet.addAction(UIAlertAction(title: "Email".localized, style: .default) { [weak self] _ in
            self?.shareEmail()
        })
        sheet.addAction(UIAlertAction(title: "Share".localized, style: .default) { [weak self] _ in
            self?.shareExternally()
        })
        sheet.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
        attachPopover(sheet)
        present(sheet, animated: true)
    }

    private func attachPopover(_ sheet: UIAlertController) {
        guard let popover = sheet.popoverPresentationController else { return }
        popover.sourceView = view
        popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 80, width: 1, height: 1)
    }

    private func clientName() -> String {
        selectedClient?.name
            ?? RealtorDesk.shared.activeRequest?.buyerName
            ?? "Client".localized
    }

    private func reportText() -> String {
        AgentMarketingCopy.comparisonReport(for: properties, client: clientName())
    }

    private func sendToBuyer() {
        if let requestId = selectedClient?.requestId {
            RealtorDesk.shared.setActiveRequest(requestId)
        }
        RealtorDesk.shared.shareCompare(properties: properties, clientName: clientName())
        let alert = UIAlertController(
            title: "Sent to buyer".localized,
            message: "Shared with %@.".localized(clientName()),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
        present(alert, animated: true)
    }

    private func shareWhatsApp() {
        let text = reportText()
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&+")
        guard let encoded = text.addingPercentEncoding(withAllowedCharacters: allowed),
              let url = URL(string: "whatsapp://send?text=\(encoded)") else {
            shareExternally()
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            shareExternally()
        }
    }

    private func shareEmail() {
        let subject = "\(clientName())'s Property Comparison".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Compare"
        let body = reportText().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:?subject=\(subject)&body=\(body)") {
            UIApplication.shared.open(url)
        } else {
            shareExternally()
        }
    }

    private func shareExternally() {
        present(UIActivityViewController(activityItems: [reportText()], applicationActivities: nil), animated: true)
    }
}
