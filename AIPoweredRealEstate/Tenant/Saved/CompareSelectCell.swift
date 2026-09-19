//
//  CompareSelectCell.swift
//  AIPoweredRealEstate
//

import UIKit

final class CompareSelectCell: UITableViewCell {
    static let identifier = "CompareSelectCell"
    static var nib: UINib { UINib(nibName: identifier, bundle: nil) }
    static let rowHeight: CGFloat = 96
    private static let titleHeight: CGFloat = 40

    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var checkView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        photoView.contentMode = .scaleAspectFill
        photoView.clipsToBounds = true
        photoView.layer.cornerRadius = 10
        applyTitleStyle()
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.numberOfLines = 1
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private func applyTitleStyle() {
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontSizeToFitWidth = false
        titleLabel.minimumScaleFactor = 1
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        if titleLabel.constraints.contains(where: { $0.firstAttribute == .height && $0.secondItem == nil }) == false {
            titleLabel.heightAnchor.constraint(equalToConstant: Self.titleHeight).isActive = true
        }
    }

    func configure(_ property: PropertyItem, selected: Bool) {
        if property.imageName.lowercased().hasPrefix("http"),
           let url = URL(string: property.imageName) {
            photoView.sd_setImage(with: url, placeholderImage: UIImage(named: "propertyCityApartment"))
        } else {
            photoView.image = UIImage(named: property.imageName) ?? UIImage(named: "propertyCityApartment")
        }
        titleLabel.text = property.title
        subtitleLabel.text = "\(property.location)  ·  \(property.priceText)"
        checkView.image = UIImage(systemName: selected ? "checkmark.circle.fill" : "circle")
        checkView.tintColor = selected ? .darkThemeColor : UIColor(white: 0.75, alpha: 1)
    }
}
