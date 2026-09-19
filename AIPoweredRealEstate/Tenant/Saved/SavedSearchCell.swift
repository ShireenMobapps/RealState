//
//  SavedSearchCell.swift
//  AIPoweredRealEstate
//

import UIKit

final class SavedSearchCell: UITableViewCell {
    static let identifier = "SavedSearchCell"
    static var nib: UINib { UINib(nibName: identifier, bundle: nil) }

    var onAlertChange: ((Bool) -> Void)?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var alertSwitch: UISwitch!
    @IBOutlet weak var bellView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        alertSwitch.onTintColor = .darkThemeColor
        bellView.tintColor = .darkThemeColor
        alertSwitch.addTarget(self, action: #selector(alertChanged), for: .valueChanged)
    }

    func configure(_ search: SavedSearch) {
        titleLabel.text = search.title
        subtitleLabel.text = search.subtitle
        alertSwitch.isOn = search.alertOn
        bellView.image = UIImage(systemName: search.alertOn ? "bell.fill" : "bell.slash")
    }

    @objc private func alertChanged() {
        bellView.image = UIImage(systemName: alertSwitch.isOn ? "bell.fill" : "bell.slash")
        onAlertChange?(alertSwitch.isOn)
    }
}
