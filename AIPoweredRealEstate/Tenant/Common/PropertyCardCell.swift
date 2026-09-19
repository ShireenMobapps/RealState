//
//  PropertyCardCell.swift
//  AIPoweredRealEstate
//

import UIKit

final class PropertyCardCell: UICollectionViewCell, UIGestureRecognizerDelegate {

    static let identifier = "PropertyCardCell"
    static var nib: UINib { UINib(nibName: identifier, bundle: nil) }
    static let imageHeight: CGFloat = 148
    static let bottomPadding: CGFloat = 25
    static let preferredHeight: CGFloat = height(forTitle: "Title\nTitle", width: 220)

    static func height(forTitle title: String, width: CGFloat) -> CGFloat {
        let textWidth = max(width - 32, 1)
        let font = UIFont.systemFont(ofSize: 15, weight: .bold)
        let maxTitle = ceil(font.lineHeight * 2)
        let raw = ceil((title as NSString).boundingRect(
            with: CGSize(width: textWidth, height: maxTitle),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).height)
        let titleHeight = min(max(raw, ceil(font.lineHeight)), maxTitle)
        return 4 + imageHeight + 10 + titleHeight + 2 + 18 + 6 + 17 + 6 + 20 + bottomPadding + 4
    }

    var onFavorite: (() -> Void)?
    var onTap: (() -> Void)?
    var onDelete: (() -> Void)?
    private var showsDeleteButton = false

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var typeBadge: UILabel!
    @IBOutlet weak var favoriteCircle: UIView!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var specsLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        applyChrome()
        configureTitleLabel()
        favoriteButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
        let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        contentView.addGestureRecognizer(tap)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let radius = favoriteCircle.bounds.height / 2
        favoriteCircle.layer.cornerRadius = radius
        favoriteCircle.layer.shadowPath = UIBezierPath(
            roundedRect: favoriteCircle.bounds,
            cornerRadius: radius
        ).cgPath
        CommonMethods.updateListingTypeBadgeShape(typeBadge)
    }

    func configure(with property: PropertyItem, isFavorite: Bool, showsSource: Bool = false, showsDelete: Bool = false) {
        titleLabel.text = property.title
        locationLabel.text = showsSource ? "\(property.location)  ·  \(property.source)" : property.location
        priceLabel.text = property.priceText
        specsLabel.text = property.specsText
        typeBadge.text = "  \(property.listingType.localized) · \(property.propertyType.localized)  "
        if let url = URL(string: property.imageName), property.imageName.lowercased().hasPrefix("http") {
            photoImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "propertyCityApartment"))
        } else {
            photoImageView.image = UIImage(named: property.imageName)
        }
        showsDeleteButton = showsDelete
        if showsDelete {
            applyDeleteStyle()
        } else {
            applyFavoriteStyle(isFavorite: isFavorite)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTap = nil
        onFavorite = nil
        onDelete = nil
        showsDeleteButton = false
    }

    func applyFavoriteStyle(isFavorite: Bool) {
        let heartRed = UIColor(red: 220/255, green: 38/255, blue: 38/255, alpha: 1)
        favoriteCircle.backgroundColor = .white
        favoriteCircle.layer.borderWidth = 0.5
        favoriteCircle.layer.borderColor = UIColor.black.withAlphaComponent(0.10).cgColor
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        favoriteButton.setImage(
            UIImage(systemName: isFavorite ? "heart.fill" : "heart", withConfiguration: config)?
                .withTintColor(heartRed, renderingMode: .alwaysOriginal),
            for: .normal
        )
    }

    private func applyDeleteStyle() {
        favoriteCircle.backgroundColor = .white
        favoriteCircle.layer.borderWidth = 0.5
        favoriteCircle.layer.borderColor = UIColor.black.withAlphaComponent(0.10).cgColor
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        favoriteButton.setImage(
            UIImage(systemName: "trash", withConfiguration: config)?
                .withTintColor(UIColor(red: 220/255, green: 38/255, blue: 38/255, alpha: 1), renderingMode: .alwaysOriginal),
            for: .normal
        )
    }

    private func configureTitleLabel() {
        titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
        titleLabel.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontSizeToFitWidth = false
        titleLabel.minimumScaleFactor = 1
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        locationLabel.font = .systemFont(ofSize: 15, weight: .medium)
        specsLabel.font = .systemFont(ofSize: 14, weight: .regular)
    }

    private func applyChrome() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        clipsToBounds = false
        contentView.clipsToBounds = false

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 18
        cardView.layer.shadowColor = UIColor.darkThemeColor.cgColor
        cardView.layer.shadowOpacity = 0.10
        cardView.layer.shadowRadius = 12
        cardView.layer.shadowOffset = CGSize(width: 0, height: 6)
        cardView.layer.masksToBounds = false

        imageContainer.layer.cornerRadius = 18
        imageContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        imageContainer.clipsToBounds = false
        photoImageView.layer.cornerRadius = 18
        photoImageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        photoImageView.clipsToBounds = true

        CommonMethods.styleListingTypeBadge(typeBadge)

        favoriteCircle.backgroundColor = .white
        favoriteCircle.clipsToBounds = false
        favoriteCircle.layer.shadowColor = UIColor.black.cgColor
        favoriteCircle.layer.shadowOpacity = 0.22
        favoriteCircle.layer.shadowRadius = 5
        favoriteCircle.layer.shadowOffset = CGSize(width: 0, height: 2)
        favoriteCircle.layer.borderWidth = 0.5
        favoriteCircle.layer.borderColor = UIColor.black.withAlphaComponent(0.10).cgColor
    }

    @objc private func favoriteTapped() {
        if showsDeleteButton {
            onDelete?()
        } else {
            onFavorite?()
        }
    }

    @objc private func cardTapped() {
        onTap?()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let current = view {
            if current is UIControl { return false }
            view = current.superview
        }
        return true
    }
}
