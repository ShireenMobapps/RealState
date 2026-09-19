//
//  TenantRealtorHelpVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class TenantRealtorHelpVC: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentStack: UIStackView!
    @IBOutlet weak var errorLabel: UILabel!

    var requirement = ClientRequirement(query: "", amenities: [])
    private var matches: [RealtorRecommendation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Get Help From a Realtor".localized
        view.backgroundColor = .screenBackgroundColor
        navigationController?.navigationBar.tintColor = .darkThemeColor
        contentStack.axis = .vertical
        contentStack.spacing = 16
        errorLabel.textColor = .systemRed
        errorLabel.font = .systemFont(ofSize: 13, weight: .regular)
        errorLabel.numberOfLines = 0
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        reload()
    }

    private func reload() {
        errorLabel.text = nil
        errorLabel.isHidden = true
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        contentStack.addArrangedSubview(card(
            title: "Search Myself".localized,
            body: "Keep browsing the centralized inventory with AI search or filters.".localized,
            button: "Continue searching".localized,
            action: #selector(searchMyself)
        ))
        contentStack.addArrangedSubview(card(
            title: "Your requirement".localized,
            body: requirement.summaryText,
            button: nil,
            action: nil
        ))

        if let request = RealtorDesk.shared.buyerActiveRequest,
           let realtor = RealtorDesk.shared.assignedRealtor(for: request) {
            contentStack.addArrangedSubview(card(
                title: "Your SpeddyProp realtor".localized,
                body: """
                \(realtor.name)
                \(realtor.agency)
                \(realtor.phone)
                \(realtor.email)

                \("Status".localized): \(request.status.rawValue.localized)
                """,
                button: RealtorDesk.shared.latestSharedReport() == nil ? "Message realtor".localized : "View recommendations".localized,
                action: RealtorDesk.shared.latestSharedReport() == nil ? #selector(messageRealtor) : #selector(openRecommendations)
            ))
        } else {
            matches = LeadWorkflowService.shared.recommendations(for: requirement)
            contentStack.addArrangedSubview(card(
                title: "Available realtors".localized,
                body: "Choose a verified SpeddyProp realtor for this search. Saving a listing never makes a realtor the owner of that property.".localized,
                button: nil,
                action: nil
            ))
            if matches.isEmpty {
                errorLabel.text = "No verified realtors are available right now.".localized
                errorLabel.isHidden = false
            } else {
                for (index, item) in matches.enumerated() {
                    contentStack.addArrangedSubview(realtorCard(item, index: index))
                }
            }
        }
    }

    @objc private func searchMyself() {
        if let nav = navigationController {
            for controller in nav.viewControllers where controller is TenantSearchVC {
                nav.popToViewController(controller, animated: true)
                return
            }
        }
        tabBarController?.selectedIndex = 1
        navigationController?.popToRootViewController(animated: true)
    }

    @objc private func chooseRealtor(_ sender: UIButton) {
        errorLabel.text = nil
        errorLabel.isHidden = true
        guard matches.indices.contains(sender.tag) else {
            errorLabel.text = "A realtor could not be assigned right now.".localized
            errorLabel.isHidden = false
            return
        }
        let item = matches[sender.tag]
        let result = LeadWorkflowService.shared.processContactAgentFlow(
            LeadCreateRequest(
                buyerId: TenantAccount.shared.email,
                buyerName: TenantAccount.shared.name,
                buyerEmail: TenantAccount.shared.email,
                buyerPhone: TenantAccount.shared.phone,
                propertyId: nil,
                requirements: requirement.summaryText,
                budgetMin: nil,
                budgetMax: requirement.budgetMax.map(Double.init),
                preferredLanguage: TenantAccount.shared.language,
                preferredContactMethod: .whatsapp,
                source: .aiSearch
            ),
            assignmentMode: .buyerChoice,
            selectedRealtorId: item.realtor.id
        )
        guard result.assignedRealtor != nil else {
            errorLabel.text = "A realtor could not be assigned right now.".localized
            errorLabel.isHidden = false
            return
        }
        reload()
        let realtor = item.realtor
        let alert = UIAlertController(
            title: "Realtor assigned".localized,
            message: "%@ from %@ will handle this search.".localized(realtor.name, realtor.agency),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
        present(alert, animated: true)
    }

    @objc private func messageRealtor() {
        guard let request = RealtorDesk.shared.buyerActiveRequest else { return }
        let alert = UIAlertController(title: "Message realtor".localized, message: "Continue communicating with your assigned realtor.".localized, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Message".localized }
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "Send".localized, style: .default) { [weak self] _ in
            let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !text.isEmpty else { return }
            RealtorDesk.shared.addMessage(requestId: request.id, fromBuyer: true, text: text)
            AgentStore.shared.recordBuyerMessage(request: request, text: text)
            self?.presentSimpleOK("Message sent".localized, "Your realtor will follow up.".localized)
        })
        present(alert, animated: true)
    }

    @objc private func openRecommendations() {
        let vc: TenantRealtorRecommendationsVC = TenantStoryboard.load("TenantRealtorRecommendationsVC")
        navigationController?.pushViewController(vc, animated: true)
    }

    private func presentSimpleOK(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
        present(alert, animated: true)
    }

    private func realtorCard(_ item: RealtorRecommendation, index: Int) -> UIView {
        let realtor = item.realtor
        let titleLabel = UILabel()
        titleLabel.text = "\(realtor.name)  ·  \(Int(item.score.totalScore))"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .darkThemeColor
        titleLabel.numberOfLines = 0

        let bodyLabel = UILabel()
        bodyLabel.text = """
        \(realtor.agency)
        \(item.assignmentReason)
        \("Verified".localized) · \(String(format: "%.1f", realtor.rating))/5 · \(realtor.responseTimeHours)h
        \(realtor.phone)
        \(realtor.email)
        """
        bodyLabel.font = .systemFont(ofSize: 15, weight: .regular)
        bodyLabel.textColor = UIColor(red: 73/255, green: 80/255, blue: 87/255, alpha: 1)
        bodyLabel.numberOfLines = 0

        let actionButton = UIButton(type: .system)
        actionButton.setTitle("Choose this realtor".localized, for: .normal)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        actionButton.backgroundColor = .darkThemeColor
        actionButton.layer.cornerRadius = 14
        actionButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        actionButton.tag = index
        actionButton.addTarget(self, action: #selector(chooseRealtor(_:)), for: .touchUpInside)

        let inner = UIStackView(arrangedSubviews: [titleLabel, bodyLabel, actionButton])
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

    private func card(title: String, body: String, button: String?, action: Selector?) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .darkThemeColor
        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.font = .systemFont(ofSize: 15, weight: .regular)
        bodyLabel.textColor = UIColor(red: 73/255, green: 80/255, blue: 87/255, alpha: 1)
        bodyLabel.numberOfLines = 0
        let inner = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        inner.axis = .vertical
        inner.spacing = 8
        if let button, let action {
            let actionButton = UIButton(type: .system)
            actionButton.setTitle(button, for: .normal)
            actionButton.setTitleColor(.white, for: .normal)
            actionButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            actionButton.backgroundColor = .darkThemeColor
            actionButton.layer.cornerRadius = 14
            actionButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
            actionButton.addTarget(self, action: action, for: .touchUpInside)
            inner.addArrangedSubview(actionButton)
        }
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
}
