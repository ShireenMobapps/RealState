//
//  TenantLeadDetailVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class TenantLeadDetailVC: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentStack: UIStackView!

    var leadId: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Lead details".localized
        view.backgroundColor = .screenBackgroundColor
        navigationController?.navigationBar.tintColor = .darkThemeColor
        contentStack.axis = .vertical
        contentStack.spacing = 16
        NotificationCenter.default.addObserver(self, selector: #selector(rebuild), name: .realtorDeskDidChange, object: nil)
        rebuild()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        rebuild()
    }

    @objc private func rebuild() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let lead = RealtorDesk.shared.lead(id: leadId) else {
            contentStack.addArrangedSubview(sectionCard(title: "Lead details".localized, body: "This lead is no longer available.".localized))
            return
        }
        contentStack.addArrangedSubview(statusCard(lead))
        if let property = lead.property {
            contentStack.addArrangedSubview(sectionCard(
                title: "Property".localized,
                body: "\(property.title)\n\(property.location) · \(property.priceText)\n\(property.bedrooms) BR · \(property.propertyType)"
            ))
        }
        contentStack.addArrangedSubview(sectionCard(title: "Requirements".localized, body: lead.requirementsSummary))
        if lead.status.showsAssignedRealtor, let realtor = lead.assignedRealtor {
            contentStack.addArrangedSubview(sectionCard(
                title: "Your agent".localized,
                body: "\("Sent to %@".localized(realtor.name))\n\(realtor.agency)"
            ))
            contentStack.addArrangedSubview(realtorCard(realtor, lead: lead))
            contentStack.addArrangedSubview(contactButtons())
        } else if let agentName = lead.displayAgentName {
            contentStack.addArrangedSubview(sectionCard(
                title: "Your agent".localized,
                body: "Sent to %@".localized(agentName)
            ))
        }
        contentStack.addArrangedSubview(historyCard(lead))
    }

    private func statusCard(_ lead: PlatformLead) -> UIView {
        let date = BuyerLeadCell.dateText(lead.createdAt)
        return sectionCard(
            title: lead.displayLeadCode.isEmpty ? "Lead details".localized : lead.displayLeadCode,
            body: """
            \("Status".localized): \(lead.status.displayName)
            \(lead.status.buyerExplanation)
            \("Created".localized): \(date)
            """
        )
    }

    private func realtorCard(_ realtor: PlatformRealtor, lead: PlatformLead) -> UIView {
        let photo = UIImageView()
        photo.translatesAutoresizingMaskIntoConstraints = false
        photo.contentMode = .scaleAspectFill
        photo.clipsToBounds = true
        photo.tintColor = .darkThemeColor
        photo.backgroundColor = UIColor.darkThemeColor.withAlphaComponent(0.08)
        photo.image = UIImage(systemName: "person.crop.circle.fill")
        if let urlString = realtor.profileImageURL, let url = URL(string: urlString) {
            photo.sd_setImage(with: url, placeholderImage: UIImage(systemName: "person.crop.circle.fill"))
        }
        NSLayoutConstraint.activate([
            photo.widthAnchor.constraint(equalToConstant: 64),
            photo.heightAnchor.constraint(equalToConstant: 64)
        ])
        photo.layer.cornerRadius = 32

        let name = UILabel()
        name.text = realtor.name
        name.font = .systemFont(ofSize: 18, weight: .bold)
        name.textColor = .darkThemeColor
        name.numberOfLines = 0

        let meta = UILabel()
        meta.numberOfLines = 0
        meta.font = .systemFont(ofSize: 14, weight: .regular)
        meta.textColor = UIColor(red: 73/255, green: 80/255, blue: 87/255, alpha: 1)
        let why = lead.assignmentMetadata?.assignmentReason
        meta.text = [
            realtor.agency,
            String(format: "★ %.1f · %d deals", realtor.rating, realtor.totalDeals),
            "\("Specialization".localized): \(realtor.specialization.joined(separator: ", "))",
            "\("Location expertise".localized): \(realtor.locationExpertise.joined(separator: ", "))",
            "\("Languages".localized): \(realtor.languages.joined(separator: ", "))",
            "\(realtor.phone) · \(realtor.email)",
            "\("Response time".localized): \(realtor.responseTimeHours)h",
            why.map { "\("Why this realtor?".localized) \($0)" }
        ].compactMap { $0 }.joined(separator: "\n")

        let text = UIStackView(arrangedSubviews: [name, meta])
        text.axis = .vertical
        text.spacing = 6
        let header = UIStackView(arrangedSubviews: [photo, text])
        header.axis = .horizontal
        header.alignment = .top
        header.spacing = 12
        return wrap(header)
    }

    private func contactButtons() -> UIView {
        let row1 = UIStackView(arrangedSubviews: [
            actionButton("Call".localized, #selector(callTapped)),
            actionButton("WhatsApp".localized, #selector(whatsAppTapped))
        ])
        let row2 = UIStackView(arrangedSubviews: [
            actionButton("Email".localized, #selector(emailTapped)),
            actionButton("Message".localized, #selector(messageTapped))
        ])
        [row1, row2].forEach {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.distribution = .fillEqually
        }
        let column = UIStackView(arrangedSubviews: [row1, row2])
        column.axis = .vertical
        column.spacing = 8
        return column
    }

    private func historyCard(_ lead: PlatformLead) -> UIView {
        if lead.contactHistory.isEmpty {
            return sectionCard(title: "Contact history".localized, body: "No contact yet.".localized)
        }
        let body = lead.contactHistory.map { entry in
            """
            \(BuyerLeadCell.dateText(entry.date))
            \(entry.methodDisplayName) · \(entry.performedBy)
            \(entry.message)
            """
        }.joined(separator: "\n\n")
        return sectionCard(title: "Contact history".localized, body: body)
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
        return wrap(inner)
    }

    private func wrap(_ content: UIView) -> UIView {
        let card = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        CommonMethods.styleFormCard(card)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
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

    private func currentLead() -> PlatformLead? { RealtorDesk.shared.lead(id: leadId) }

    @objc private func callTapped() {
        guard let lead = currentLead(), let realtor = lead.assignedRealtor else { return }
        let digits = realtor.phone.filter(\.isNumber)
        if let url = URL(string: "tel://\(digits)") {
            UIApplication.shared.open(url)
        }
        logContact(.phone, message: "Called \(realtor.name)", notes: "Buyer called assigned realtor")
    }

    @objc private func whatsAppTapped() {
        guard let lead = currentLead(), let realtor = lead.assignedRealtor else { return }
        let digits = realtor.whatsapp.filter(\.isNumber)
        let text = "Hi \(realtor.name), this is \(TenantAccount.shared.name). I submitted \(lead.leadCode) on SpeddyProp."
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/\(digits)?text=\(encoded)") {
            UIApplication.shared.open(url)
        }
        logContact(.whatsapp, message: text, notes: "Buyer messaged realtor on WhatsApp")
    }

    @objc private func emailTapped() {
        guard let lead = currentLead(), let realtor = lead.assignedRealtor else { return }
        let subject = "SpeddyProp \(lead.leadCode)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = "Hi \(realtor.name),\n\nI submitted \(lead.leadCode) and would like to continue this search.\n\n\(lead.requirements)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(realtor.email)?subject=\(subject)&body=\(body)") {
            UIApplication.shared.open(url)
        }
        logContact(.email, message: lead.requirements, notes: "Buyer emailed assigned realtor")
    }

    @objc private func messageTapped() {
        guard let lead = currentLead() else { return }
        let alert = UIAlertController(
            title: "Message".localized,
            message: "Continue communicating with your assigned realtor.".localized,
            preferredStyle: .alert
        )
        alert.addTextField { $0.placeholder = "Message".localized }
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "Send".localized, style: .default) { [weak self] _ in
            let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !text.isEmpty, let self else { return }
            if let requestId = lead.assistanceRequestId {
                RealtorDesk.shared.addMessage(requestId: requestId, fromBuyer: true, text: text)
                if let request = RealtorDesk.shared.requests.first(where: { $0.id == requestId }) {
                    AgentStore.shared.recordBuyerMessage(request: request, text: text)
                }
            }
            self.logContact(.inApp, message: text, notes: "In-app message")
            let done = UIAlertController(title: "Message sent".localized, message: "Your realtor will follow up.".localized, preferredStyle: .alert)
            done.addAction(UIAlertAction(title: "OK".localized, style: .default))
            self.present(done, animated: true)
        })
        present(alert, animated: true)
    }

    private func logContact(_ method: PreferredContactMethod, message: String, notes: String) {
        RealtorDesk.shared.addContact(leadId: leadId, method: method, message: message, notes: notes, fromBuyer: true)
    }
}
