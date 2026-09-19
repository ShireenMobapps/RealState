//
//  NotificationCell.swift
//  AIPoweredRealEstate
//

import UIKit

final class NotificationCell: UITableViewCell {
    static let identifier = "NotificationCell"
    static var nib: UINib { UINib(nibName: identifier, bundle: Bundle(for: NotificationCell.self)) }

    static func register(on tableView: UITableView) {
        let bundle = Bundle(for: NotificationCell.self)
        if bundle.path(forResource: identifier, ofType: "nib") != nil {
            tableView.register(nib, forCellReuseIdentifier: identifier)
        } else {
            tableView.register(NotificationCell.self, forCellReuseIdentifier: identifier)
        }
    }

    @IBOutlet weak var cardView: UIView?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!

    var onDelete: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        buildLayoutIfNeeded()
        applyStyle()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyle()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let cardView else { return }
        cardView.layer.shadowPath = UIBezierPath(
            roundedRect: cardView.bounds,
            cornerRadius: cardView.layer.cornerRadius
        ).cgPath
    }

    func configure(_ item: NotificationItemModel) {
        buildLayoutIfNeeded()
        titleLabel.text = item.displayTitle
        titleLabel.font = .systemFont(ofSize: 16, weight: (item.isRead == false) ? .semibold : .medium)
        bodyLabel.text = item.displayMessage
        bodyLabel.isHidden = item.displayMessage.isEmpty
        dateLabel.text = item.displayDate
        dateLabel.isHidden = item.displayDate.isEmpty
    }

    @IBAction func closeTapped(_ sender: Any) {
        onDelete?()
    }

    private func applyStyle() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        clipsToBounds = false
        contentView.clipsToBounds = false
        selectionStyle = .none
        if let cardView {
            CommonMethods.styleFormCard(cardView)
            cardView.layer.cornerRadius = 16
            cardView.layer.shadowRadius = 10
            cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        }
        closeButton?.setImage(
            UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)),
            for: .normal
        )
        closeButton?.tintColor = UIColor(white: 0.55, alpha: 1)
        closeButton?.isExclusiveTouch = true
    }

    private func buildLayoutIfNeeded() {
        guard titleLabel == nil || closeButton == nil || cardView == nil else { return }

        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.font = .systemFont(ofSize: 16, weight: .semibold)
        title.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
        title.numberOfLines = 2

        let body = UILabel()
        body.font = .systemFont(ofSize: 14, weight: .regular)
        body.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)
        body.numberOfLines = 3

        let date = UILabel()
        date.font = .systemFont(ofSize: 12, weight: .regular)
        date.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)

        let close = UIButton(type: .system)
        close.translatesAutoresizingMaskIntoConstraints = false

        let text = UIStackView(arrangedSubviews: [title, body, date])
        text.axis = .vertical
        text.spacing = 4

        let row = UIStackView(arrangedSubviews: [text, close])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(card)
        card.addSubview(row)

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            close.widthAnchor.constraint(equalToConstant: 28),
            close.heightAnchor.constraint(equalToConstant: 28),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        cardView = card
        titleLabel = title
        bodyLabel = body
        dateLabel = date
        closeButton = close
        close.addTarget(self, action: #selector(closeTapped(_:)), for: .touchUpInside)
    }
}
