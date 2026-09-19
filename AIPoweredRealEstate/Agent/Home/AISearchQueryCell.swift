//
//  AISearchQueryCell.swift
//  AIPoweredRealEstate
//

import UIKit

final class AISearchQueryCell: UITableViewCell {

    static let identifier = "AISearchQueryCell"
    static let rowHeight: CGFloat = 76

    var onDelete: (() -> Void)?

    private let cardView = UIView()
    private let queryLabel = UILabel()
    private let deleteButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        installLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onDelete = nil
        queryLabel.text = nil
    }

    func configure(query: String) {
        queryLabel.text = query
    }

    private func installLayout() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 14
        CommonMethods.styleFormCard(cardView)
        contentView.addSubview(cardView)

        queryLabel.translatesAutoresizingMaskIntoConstraints = false
        queryLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        queryLabel.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
        queryLabel.numberOfLines = 2
        cardView.addSubview(queryLabel)

        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        deleteButton.setImage(
            UIImage(systemName: "xmark", withConfiguration: config),
            for: .normal
        )
        deleteButton.tintColor = .darkThemeColor
        deleteButton.backgroundColor = UIColor(red: 245/255, green: 246/255, blue: 248/255, alpha: 1)
        deleteButton.layer.cornerRadius = 16
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        cardView.addSubview(deleteButton)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            deleteButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            deleteButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 32),
            deleteButton.heightAnchor.constraint(equalToConstant: 32),

            queryLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            queryLabel.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -12),
            queryLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            queryLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14)
        ])
    }

    @objc private func deleteTapped() {
        onDelete?()
    }
}
