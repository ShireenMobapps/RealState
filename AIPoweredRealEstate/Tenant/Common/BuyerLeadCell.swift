//
//  BuyerLeadCell.swift
//  AIPoweredRealEstate
//

import UIKit

final class BuyerLeadCell: UITableViewCell {
    static let identifier = "BuyerLeadCell"

    private let cardView = UIView()
    private let codeLabel = UILabel()
    private let statusBadge = UIView()
    private let statusLabel = UILabel()
    private let statusButton = UIButton(type: .system)
    private let agentLabel = UILabel()
    private let detailLabel = UILabel()
    private var statusWidthConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        installLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        installLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if cardView.bounds.width > 1 {
            cardView.layer.shadowPath = UIBezierPath(
                roundedRect: cardView.bounds,
                cornerRadius: cardView.layer.cornerRadius
            ).cgPath
        }
        if statusBadge.bounds.width > 1 {
            CommonMethods.updateGradientFrame(for: statusBadge)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(false, animated: false)
        cardView.backgroundColor = .white
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(false, animated: false)
        cardView.backgroundColor = .white
    }

    func configure(_ lead: PlatformLead) {
        let raw = lead.apiStatus.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let title: String
        if raw.contains("cancel") {
            title = "Cancelled".localized
        } else {
            title = lead.status.displayName
        }
        applyStatusTitle(title)
        applyStatusColor(lead: lead, rawStatus: raw)
        statusButton.menu = nil
        statusButton.showsMenuAsPrimaryAction = false
        statusButton.isUserInteractionEnabled = false
        let agentText: String
        if let agentName = lead.displayAgentName {
            agentText = "Sent to %@".localized(agentName)
        } else {
            agentText = "Request submitted".localized
        }
        applyHeader(title: lead.displayLeadCode, subtitle: agentText)
        let propertyLine = lead.property.map { "\($0.title) · \($0.location)" }
        detailLabel.text = [propertyLine, lead.requirementsSummary, Self.dateText(lead.createdAt)]
            .compactMap { $0 }
            .joined(separator: "\n")
    }

    private func applyStatusColor(lead: PlatformLead, rawStatus: String) {
        statusBadge.layer.sublayers?
            .compactMap { $0 as? CAGradientLayer }
            .forEach { $0.removeFromSuperlayer() }
        statusBadge.isHidden = false

        let isCancelled = rawStatus.contains("cancel")
            || rawStatus.contains("reject")
            || lead.status == .lost
        let isContacted = rawStatus.contains("contact")
            || rawStatus == "approved"
            || lead.status == .contacted
        let isClosed = rawStatus.contains("close")
            || rawStatus.contains("complete")
            || rawStatus.contains("qualified")
            || lead.status == .closed

        if isCancelled == false, isContacted {
            statusBadge.backgroundColor = .accentThemeColor
            CommonMethods.applyYellowGradient(on: statusBadge)
            CommonMethods.updateGradientFrame(for: statusBadge)
            statusLabel.textColor = .white
            return
        }

        if isCancelled {
            statusBadge.backgroundColor = UIColor(red: 220 / 255, green: 38 / 255, blue: 38 / 255, alpha: 1)
        } else if isClosed {
            statusBadge.backgroundColor = UIColor(red: 22 / 255, green: 163 / 255, blue: 74 / 255, alpha: 1)
        } else {
            statusBadge.backgroundColor = .darkThemeColor
        }
        statusLabel.textColor = .white
    }

    func configureForAgent(_ lead: PlatformLead, onStatusChange: ((String) -> Void)? = nil) {
        let raw = lead.apiStatus.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = raw.lowercased()
        let title: String
        switch key {
        case "pending": title = "Pending".localized
        case "approved": title = "Approved".localized
        case "rejected": title = "Rejected".localized
        case "completed": title = "Completed".localized
        default:
            title = raw.isEmpty
                ? "Pending".localized
                : raw.prefix(1).uppercased() + raw.dropFirst()
        }
        applyStatusTitle(title)
        applyStatusColor(lead: lead, rawStatus: key)
        let canChangeStatus = key == "pending"
        if canChangeStatus {
            statusButton.isEnabled = true
            statusButton.isUserInteractionEnabled = true
            statusButton.showsMenuAsPrimaryAction = true
            statusButton.menu = UIMenu(children: [
                UIAction(title: "Approved".localized, state: .off) { _ in
                    onStatusChange?("approved")
                },
                UIAction(title: "Reject".localized, state: .off) { _ in
                    onStatusChange?("rejected")
                }
            ])
        } else {
            statusButton.menu = nil
            statusButton.showsMenuAsPrimaryAction = false
            statusButton.isUserInteractionEnabled = false
            statusButton.isEnabled = true
        }
        let buyer = lead.buyerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let contact = [lead.buyerEmail, lead.buyerPhone]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
        applyHeader(title: buyer.isEmpty ? lead.displayLeadCode : buyer, subtitle: contact)
        let propertyLine = lead.property.map { "\($0.title) · \($0.location)" }
        detailLabel.text = [propertyLine, lead.requirementsSummary, Self.dateText(lead.createdAt)]
            .compactMap { $0 }
            .joined(separator: "\n")
    }

    private func applyStatusTitle(_ title: String) {
        let font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        statusLabel.font = font
        statusLabel.text = title
        statusLabel.textColor = .white
        let textWidth = ceil((title as NSString).size(withAttributes: [.font: font]).width)
        statusWidthConstraint?.constant = max(86, textWidth + 24)
    }

    private func applyHeader(title: String, subtitle: String) {
        let hasTitle = !title.isEmpty
        codeLabel.text = hasTitle ? title : subtitle
        codeLabel.numberOfLines = 2
        agentLabel.text = subtitle
        agentLabel.isHidden = !hasTitle || subtitle.isEmpty
    }

    static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func installLayout() {
        guard cardView.superview == nil else { return }

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        clipsToBounds = false
        contentView.clipsToBounds = false
        accessoryType = .none
        selectionStyle = .none

        let titleColor = UIColor(red: 33 / 255, green: 37 / 255, blue: 41 / 255, alpha: 1)
        let mutedColor = UIColor(red: 108 / 255, green: 117 / 255, blue: 125 / 255, alpha: 1)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .white
        CommonMethods.styleFormCard(cardView)
        cardView.layer.masksToBounds = false
        cardView.clipsToBounds = false
        cardView.layer.shadowOpacity = 0.16
        cardView.layer.shadowRadius = 14
        cardView.layer.shadowOffset = CGSize(width: 0, height: 6)
        contentView.addSubview(cardView)

        codeLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        codeLabel.textColor = titleColor
        codeLabel.numberOfLines = 2
        codeLabel.lineBreakMode = .byTruncatingTail
        codeLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        codeLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        statusBadge.layer.cornerRadius = 8
        statusBadge.clipsToBounds = true
        statusBadge.layer.masksToBounds = true

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 1
        statusLabel.lineBreakMode = .byClipping
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        statusButton.translatesAutoresizingMaskIntoConstraints = false
        statusButton.backgroundColor = .clear
        statusButton.setTitle(nil, for: .normal)
        statusButton.configuration = nil

        agentLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        agentLabel.textColor = .darkThemeColor
        agentLabel.numberOfLines = 1

        detailLabel.font = .systemFont(ofSize: 15)
        detailLabel.textColor = mutedColor
        detailLabel.numberOfLines = 3
        detailLabel.lineBreakMode = .byWordWrapping

        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(codeLabel)
        header.addSubview(statusBadge)
        statusBadge.addSubview(statusLabel)
        header.addSubview(statusButton)
        codeLabel.translatesAutoresizingMaskIntoConstraints = false

        let column = UIStackView(arrangedSubviews: [header, agentLabel, detailLabel])
        column.axis = .vertical
        column.spacing = 8
        column.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(column)

        let width = statusBadge.widthAnchor.constraint(equalToConstant: 96)
        width.priority = .required
        statusWidthConstraint = width
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            column.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            column.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            column.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            column.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),

            header.heightAnchor.constraint(greaterThanOrEqualToConstant: 28),

            statusBadge.topAnchor.constraint(equalTo: header.topAnchor),
            statusBadge.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            statusBadge.heightAnchor.constraint(equalToConstant: 28),
            width,

            statusLabel.leadingAnchor.constraint(equalTo: statusBadge.leadingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: statusBadge.trailingAnchor, constant: -12),
            statusLabel.centerYAnchor.constraint(equalTo: statusBadge.centerYAnchor),

            statusButton.topAnchor.constraint(equalTo: statusBadge.topAnchor),
            statusButton.leadingAnchor.constraint(equalTo: statusBadge.leadingAnchor),
            statusButton.trailingAnchor.constraint(equalTo: statusBadge.trailingAnchor),
            statusButton.bottomAnchor.constraint(equalTo: statusBadge.bottomAnchor),

            codeLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            codeLabel.topAnchor.constraint(equalTo: header.topAnchor),
            codeLabel.bottomAnchor.constraint(equalTo: header.bottomAnchor),
            codeLabel.trailingAnchor.constraint(equalTo: statusBadge.leadingAnchor, constant: -8)
        ])
    }
}
