//
//  TenantAgentDetailVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class TenantAgentDetailVC: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentStack: UIStackView!

    var agent: PlatformRealtor?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Agent details".localized
        view.backgroundColor = .screenBackgroundColor
        navigationController?.navigationBar.tintColor = .darkThemeColor
        contentStack.axis = .vertical
        contentStack.spacing = 16
        render()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func render() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let agent else { return }

        contentStack.addArrangedSubview(profileCard(agent))
        contentStack.addArrangedSubview(detailsCard(agent))
        if let documentURL = agent.documentURL, !documentURL.isEmpty {
            contentStack.addArrangedSubview(documentCard(urlString: documentURL))
        }
    }

    private func profileCard(_ agent: PlatformRealtor) -> UIView {
        let avatar = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        avatar.tintColor = .darkThemeColor
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.backgroundColor = UIColor.darkThemeColor.withAlphaComponent(0.08)
        avatar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 72),
            avatar.heightAnchor.constraint(equalToConstant: 72)
        ])
        avatar.layer.cornerRadius = 36
        if let urlString = agent.profileImageURL, let url = URL(string: urlString) {
            avatar.sd_setImage(
                with: url,
                placeholderImage: UIImage(systemName: "person.crop.circle.fill")
            )
        }

        let nameLabel = UILabel()
        nameLabel.text = agent.name
        nameLabel.font = .systemFont(ofSize: 20, weight: .bold)
        nameLabel.textColor = .darkThemeColor
        nameLabel.numberOfLines = 0

        let statusLabel = UILabel()
        statusLabel.text = agent.displayStatus
        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.textColor = UIColor(red: 73/255, green: 80/255, blue: 87/255, alpha: 1)
        statusLabel.numberOfLines = 0
        statusLabel.isHidden = agent.displayStatus.isEmpty

        let text = UIStackView(arrangedSubviews: [nameLabel, statusLabel])
        text.axis = .vertical
        text.spacing = 4

        let header = UIStackView(arrangedSubviews: [avatar, text])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 14
        return wrap(header)
    }

    private func detailsCard(_ agent: PlatformRealtor) -> UIView {
        let rows: [(String, String)] = [
            ("Email".localized, agent.email),
            ("Phone".localized, agent.phone),
            ("Agency name".localized, agent.agency),
            ("License number".localized, agent.licenseNumber),
            ("Status".localized, agent.displayStatus),
            ("Active".localized, agent.isActive ? "Yes".localized : "No".localized)
        ].filter { !$0.1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        for (index, row) in rows.enumerated() {
            stack.addArrangedSubview(detailRow(title: row.0, value: row.1))
            if index < rows.count - 1 {
                stack.addArrangedSubview(divider())
            }
        }
        return wrap(stack)
    }

    private func documentCard(urlString: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = "Document".localized
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = UIColor(red: 73/255, green: 80/255, blue: 87/255, alpha: 1)

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        imageView.layer.cornerRadius = 12
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: 180).isActive = true
        if let url = URL(string: urlString) {
            imageView.sd_setImage(with: url)
        }

        let stack = UIStackView(arrangedSubviews: [titleLabel, imageView])
        stack.axis = .vertical
        stack.spacing = 10
        return wrap(stack)
    }

    private func detailRow(title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        valueLabel.textColor = .darkThemeColor
        valueLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }

    private func divider() -> UIView {
        let line = UIView()
        line.backgroundColor = UIColor(white: 0.9, alpha: 1)
        line.translatesAutoresizingMaskIntoConstraints = false
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return line
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
}
