//
//  ProfileMenuCell.swift
//  AIPoweredRealEstate
//

import UIKit

final class ProfileMenuCell: UITableViewCell {
    static let identifier = "ProfileMenuCell"
    static var nib: UINib { UINib(nibName: identifier, bundle: Bundle(for: ProfileMenuCell.self)) }

    static func register(on tableView: UITableView) {
        let bundle = Bundle(for: ProfileMenuCell.self)
        if bundle.path(forResource: identifier, ofType: "nib") != nil {
            tableView.register(nib, forCellReuseIdentifier: identifier)
        } else {
            tableView.register(ProfileMenuCell.self, forCellReuseIdentifier: identifier)
        }
    }

    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var chevronView: UIImageView!

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

    func configure(icon: String, title: String, subtitle: String?, isDestructive: Bool) {
        configure(icon: UIImage(systemName: icon), title: title, subtitle: subtitle, isDestructive: isDestructive)
    }

    func configure(icon: UIImage?, title: String, subtitle: String?, isDestructive: Bool) {
        buildLayoutIfNeeded()
        iconView.image = icon
        titleLabel.text = title
        let subtitleText = subtitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        subtitleLabel.text = subtitleText
        subtitleLabel.isHidden = subtitleText?.isEmpty != false
        chevronView.isHidden = isDestructive
        let color: UIColor = isDestructive ? .darkThemeColor : UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
        titleLabel.textColor = color
        iconView.tintColor = .darkThemeColor
    }

    private func applyStyle() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        iconView?.contentMode = .scaleAspectFit
        chevronView?.contentMode = .scaleAspectFit
        chevronView?.image = UIImage(
            systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        )
    }

    private func buildLayoutIfNeeded() {
        guard iconView == nil || titleLabel == nil else { return }

        let icon = UIImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        icon.tintColor = .darkThemeColor

        let title = UILabel()
        title.font = .systemFont(ofSize: 16, weight: .medium)
        title.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)

        let subtitle = UILabel()
        subtitle.font = .systemFont(ofSize: 13, weight: .regular)
        subtitle.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)

        let chevron = UIImageView()
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.contentMode = .scaleAspectFit
        chevron.tintColor = UIColor(white: 0.72, alpha: 1)

        let text = UIStackView(arrangedSubviews: [title, subtitle])
        text.axis = .vertical
        text.spacing = 2

        let row = UIStackView(arrangedSubviews: [icon, text, chevron])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 16),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])

        iconView = icon
        titleLabel = title
        subtitleLabel = subtitle
        chevronView = chevron
    }
}
