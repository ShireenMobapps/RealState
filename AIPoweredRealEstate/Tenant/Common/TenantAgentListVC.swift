//
//  TenantAgentListVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class TenantAgentListVC: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentStack: UIStackView!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!

    var property: PropertyItem?

    private var agents: [PlatformRealtor] = []
    private var loadToken = UUID()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Agent List".localized
        view.backgroundColor = .screenBackgroundColor
        navigationController?.navigationBar.tintColor = .darkThemeColor
        contentStack.axis = .vertical
        contentStack.spacing = 14
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.text = "No agent found".localized
        emptyLabel.isHidden = true
        spinner.hidesWhenStopped = true
        loadAgents()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func loadAgents() {
        let token = UUID()
        loadToken = token
        spinner.startAnimating()
        emptyLabel.isHidden = true
        scrollView.isHidden = true
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        Task {
            do {
                let remote = try await TenantViewModels.agentsAPI()
                await MainActor.run {
                    guard self.loadToken == token else { return }
                    self.applyAgents(remote)
                }
            } catch {
                await MainActor.run {
                    guard self.loadToken == token else { return }
                    self.applyAgents([])
                }
            }
        }
    }

    private func applyAgents(_ remote: [PlatformRealtor]) {
        spinner.stopAnimating()
        agents = remote
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        emptyLabel.text = "No agent found".localized
        emptyLabel.isHidden = !agents.isEmpty
        scrollView.isHidden = agents.isEmpty

        guard !agents.isEmpty else { return }

        let intro = UILabel()
        intro.text = "Select an agent to contact".localized
        intro.font = .systemFont(ofSize: 15, weight: .regular)
        intro.textColor = UIColor(red: 73/255, green: 80/255, blue: 87/255, alpha: 1)
        intro.numberOfLines = 0
        contentStack.addArrangedSubview(intro)

        for (index, agent) in agents.enumerated() {
            contentStack.addArrangedSubview(agentCard(agent, index: index))
        }
    }

    private func agentCard(_ agent: PlatformRealtor, index: Int) -> UIView {
        let avatarWrap = circularAvatar(size: 44, urlString: agent.profileImageURL)

        let nameLabel = UILabel()
        nameLabel.text = agent.name
        nameLabel.font = .systemFont(ofSize: 17, weight: .bold)
        nameLabel.textColor = .darkThemeColor
        nameLabel.numberOfLines = 0

        var detailLines: [String] = []
        if !agent.agency.isEmpty {
            detailLines.append(agent.agency)
        }
        let statusText = agent.displayStatus
        if !statusText.isEmpty {
            detailLines.append(statusText)
        }

        let detailLabel = UILabel()
        detailLabel.text = detailLines.joined(separator: "\n")
        detailLabel.font = .systemFont(ofSize: 14, weight: .regular)
        detailLabel.textColor = UIColor(red: 73/255, green: 80/255, blue: 87/255, alpha: 1)
        detailLabel.numberOfLines = 0
        detailLabel.isHidden = detailLines.isEmpty

        let textStack = UIStackView(arrangedSubviews: [nameLabel, detailLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let header = UIStackView(arrangedSubviews: [avatarWrap, textStack])
        header.axis = .horizontal
        header.alignment = .top
        header.spacing = 12

        let selectButton = actionButton(
            title: "Select Agent".localized,
            filled: true,
            index: index,
            action: #selector(selectAgentTapped(_:))
        )
        let viewButton = actionButton(
            title: "View".localized,
            filled: false,
            index: index,
            action: #selector(viewAgentTapped(_:))
        )
        let buttons = UIStackView(arrangedSubviews: [selectButton, viewButton])
        buttons.axis = .horizontal
        buttons.spacing = 10
        buttons.distribution = .fillEqually

        let inner = UIStackView(arrangedSubviews: [header, buttons])
        inner.axis = .vertical
        inner.spacing = 14
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

    private func circularAvatar(size: CGFloat, urlString: String?) -> UIView {
        let avatar = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        avatar.tintColor = .darkThemeColor
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.backgroundColor = UIColor.darkThemeColor.withAlphaComponent(0.06)
        avatar.layer.cornerRadius = size / 2
        avatar.layer.borderWidth = 1
        avatar.layer.borderColor = UIColor.white.cgColor
        avatar.translatesAutoresizingMaskIntoConstraints = false
        if let urlString, let url = URL(string: urlString) {
            avatar.sd_setImage(
                with: url,
                placeholderImage: UIImage(systemName: "person.crop.circle.fill")
            )
        }

        let wrap = UIView()
        wrap.translatesAutoresizingMaskIntoConstraints = false
        wrap.backgroundColor = .clear
        wrap.clipsToBounds = false
        wrap.layer.shadowColor = UIColor.black.cgColor
        wrap.layer.shadowOpacity = 0.22
        wrap.layer.shadowRadius = 5
        wrap.layer.shadowOffset = CGSize(width: 0, height: 3)
        wrap.layer.shadowPath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size)).cgPath
        wrap.addSubview(avatar)
        NSLayoutConstraint.activate([
            wrap.widthAnchor.constraint(equalToConstant: size),
            wrap.heightAnchor.constraint(equalToConstant: size),
            avatar.topAnchor.constraint(equalTo: wrap.topAnchor),
            avatar.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            avatar.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            avatar.bottomAnchor.constraint(equalTo: wrap.bottomAnchor)
        ])
        return wrap
    }

    private func actionButton(title: String, filled: Bool, index: Int, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 14
        button.heightAnchor.constraint(equalToConstant: 46).isActive = true
        button.tag = index
        button.addTarget(self, action: action, for: .touchUpInside)
        if filled {
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = .darkThemeColor
        } else {
            button.setTitleColor(.darkThemeColor, for: .normal)
            button.backgroundColor = .white
            button.layer.borderWidth = 1.5
            button.layer.borderColor = UIColor.darkThemeColor.cgColor
        }
        return button
    }

    @objc private func selectAgentTapped(_ sender: UIButton) {
        openContact(for: sender.tag)
    }

    @objc private func viewAgentTapped(_ sender: UIButton) {
        openDetails(for: sender.tag)
    }

    private func openContact(for index: Int) {
        guard agents.indices.contains(index) else { return }
        let contactVC: TenantContactAgentVC = TenantStoryboard.load("TenantContactAgentVC")
        contactVC.property = property
        contactVC.selectedRealtor = agents[index]
        contactVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(contactVC, animated: true)
    }

    private func openDetails(for index: Int) {
        guard agents.indices.contains(index) else { return }
        let detailVC: TenantAgentDetailVC = TenantStoryboard.load("TenantAgentDetailVC")
        detailVC.agent = agents[index]
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
