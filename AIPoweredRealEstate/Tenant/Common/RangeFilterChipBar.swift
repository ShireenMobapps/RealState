//
//  RangeFilterChipBar.swift
//  AIPoweredRealEstate
//

import UIKit

struct PropertyRangeFilters {
    var bedrooms: Int?
    var bathrooms: Int?
    var minPrice: Int?
    var maxPrice: Int?
    var minSize: Int?
    var maxSize: Int?
}

enum RangeFilterField {
    case bedrooms, bathrooms, price, size

    var apiKey: String {
        switch self {
        case .bedrooms: return "bedrooms"
        case .bathrooms: return "bathrooms"
        case .price: return "minPrice"
        case .size: return "minSize"
        }
    }

    var displayTitle: String { apiKey.localizedAPIKey }
}

final class RangeFilterChipBar: UIView {

    var values = PropertyRangeFilters() {
        didSet { refreshTitles() }
    }
    var onChanged: ((PropertyRangeFilters) -> Void)?
    weak var host: UIViewController?

    var horizontalInset: CGFloat = 0 {
        didSet {
            leadingInsetConstraint?.constant = horizontalInset
            trailingInsetConstraint?.constant = -horizontalInset
        }
    }

    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private let bedroomsButton = UIButton(type: .system)
    private let bathroomsButton = UIButton(type: .system)
    private let priceButton = UIButton(type: .system)
    private let sizeButton = UIButton(type: .system)
    private var leadingInsetConstraint: NSLayoutConstraint?
    private var trailingInsetConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsHorizontalScrollIndicator = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        addSubview(scroll)
        scroll.addSubview(stack)

        let leading = stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor)
        let trailing = stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor)
        leadingInsetConstraint = leading
        trailingInsetConstraint = trailing

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: topAnchor),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: 36),
            leading,
            trailing,
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
        ])

        [(bedroomsButton, RangeFilterField.bedrooms),
         (bathroomsButton, .bathrooms),
         (priceButton, .price),
         (sizeButton, .size)].forEach { button, field in
            button.tag = field.tag
            button.heightAnchor.constraint(equalToConstant: 36).isActive = true
            button.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
        refreshTitles()
    }

    @objc private func chipTapped(_ sender: UIButton) {
        guard let field = RangeFilterField(tag: sender.tag),
              let host else { return }
        RangeFilterInputVC.present(from: host, field: field, current: values) { [weak self] next in
            self?.values = next
            self?.onChanged?(next)
        }
    }

    private func refreshTitles() {
        style(bedroomsButton, title: values.bedrooms.map(String.init) ?? RangeFilterField.bedrooms.displayTitle)
        style(bathroomsButton, title: values.bathrooms.map(String.init) ?? RangeFilterField.bathrooms.displayTitle)
        style(priceButton, title: rangeTitle(min: values.minPrice, max: values.maxPrice, empty: RangeFilterField.price.displayTitle))
        style(sizeButton, title: rangeTitle(min: values.minSize, max: values.maxSize, empty: RangeFilterField.size.displayTitle))
    }

    private func rangeTitle(min: Int?, max: Int?, empty: String) -> String {
        switch (min, max) {
        case let (min?, max?): return "\(min)-\(max)"
        case let (min?, nil): return "\(min)+"
        case let (nil, max?): return "≤\(max)"
        default: return empty
        }
    }

    private func style(_ button: UIButton, title: String) {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: "chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 12)
        config.baseForegroundColor = .darkThemeColor
        config.background.backgroundColor = .white
        config.background.strokeColor = UIColor.accentThemeColor
        config.background.strokeWidth = 1
        config.background.cornerRadius = 18
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var next = incoming
            next.font = .systemFont(ofSize: 13, weight: .semibold)
            return next
        }
        config.imageColorTransformer = UIConfigurationColorTransformer { _ in .darkThemeColor }
        button.configuration = config
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
    }
}

private extension RangeFilterField {
    var tag: Int {
        switch self {
        case .bedrooms: return 0
        case .bathrooms: return 1
        case .price: return 2
        case .size: return 3
        }
    }

    init?(tag: Int) {
        switch tag {
        case 0: self = .bedrooms
        case 1: self = .bathrooms
        case 2: self = .price
        case 3: self = .size
        default: return nil
        }
    }
}

final class RangeFilterInputVC: UIViewController, UITextFieldDelegate {

    private let field: RangeFilterField
    private var current: PropertyRangeFilters
    private let onSubmit: (PropertyRangeFilters) -> Void

    private let dimView = UIView()
    private let card = CustomView()
    private let titleLabel = UILabel()
    private let firstField = CustomTextField()
    private let secondField = CustomTextField()
    private let submitButton = CustomButton(type: .system)
    private let anyButton = CustomButton(type: .system)
    private let closeButton = UIButton(type: .system)

    static func present(
        from host: UIViewController,
        field: RangeFilterField,
        current: PropertyRangeFilters,
        onSubmit: @escaping (PropertyRangeFilters) -> Void
    ) {
        let vc = RangeFilterInputVC(field: field, current: current, onSubmit: onSubmit)
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        host.present(vc, animated: true)
    }

    private init(
        field: RangeFilterField,
        current: PropertyRangeFilters,
        onSubmit: @escaping (PropertyRangeFilters) -> Void
    ) {
        self.field = field
        self.current = current
        self.onSubmit = onSubmit
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        buildLayout()
        fill()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CommonMethods.updateGradientFrame(for: submitButton)
        CommonMethods.updateGradientFrame(for: anyButton)
    }

    private func buildLayout() {
        dimView.translatesAutoresizingMaskIntoConstraints = false
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeTapped)))
        view.addSubview(dimView)

        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .white
        card.cornerRadious = 16
        card.clipsToBounds = true
        view.addSubview(card)

        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .darkThemeColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = field.displayTitle

        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .darkThemeColor
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        styleField(firstField, placeholder: firstPlaceholder)
        styleField(secondField, placeholder: secondPlaceholder)
        if field == .size {
            let border = UIColor(red: 160 / 255, green: 168 / 255, blue: 178 / 255, alpha: 1)
            firstField.borderWidth = 1.5
            secondField.borderWidth = 1.5
            firstField.borderColor = border
            secondField.borderColor = border
        }
        secondField.isHidden = field == .bedrooms || field == .bathrooms

        anyButton.setTitle("Any".localized, for: .normal)
        anyButton.setTitleColor(.white, for: .normal)
        anyButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        anyButton.translatesAutoresizingMaskIntoConstraints = false
        anyButton.addTarget(self, action: #selector(anyTapped), for: .touchUpInside)
        CommonMethods.styleYellowGradientButton(anyButton)

        submitButton.setTitle("Submit".localized, for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        CommonMethods.stylePrimaryButton(submitButton)

        let actions = UIStackView(arrangedSubviews: [anyButton, submitButton])
        actions.axis = .horizontal
        actions.spacing = 10
        actions.distribution = .fillEqually
        actions.translatesAutoresizingMaskIntoConstraints = false

        let fields = UIStackView(arrangedSubviews: [firstField, secondField])
        fields.axis = .horizontal
        fields.spacing = 10
        fields.distribution = .fillEqually
        fields.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(titleLabel)
        card.addSubview(closeButton)
        card.addSubview(fields)
        card.addSubview(actions)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            fields.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            fields.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            fields.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            firstField.heightAnchor.constraint(equalToConstant: 44),
            secondField.heightAnchor.constraint(equalToConstant: 44),
            actions.topAnchor.constraint(equalTo: fields.bottomAnchor, constant: 16),
            actions.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            actions.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            actions.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
            submitButton.heightAnchor.constraint(equalToConstant: 48),
            anyButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private var firstPlaceholder: String {
        switch field {
        case .bedrooms: return "No. of Bedrooms".localized
        case .bathrooms: return "No. of Bathrooms".localized
        case .price: return "Min Price".localized
        case .size: return "Min Size".localized
        }
    }

    private var secondPlaceholder: String {
        switch field {
        case .price: return "Max Price".localized
        case .size: return "Max Size".localized
        default: return ""
        }
    }

    private func styleField(_ field: CustomTextField, placeholder: String) {
        field.placeholder = placeholder
        field.keyboardType = .numberPad
        field.borderStyle = .none
        field.backgroundColor = .white
        field.cornerRadious = 12
        field.borderWidth = 1
        field.borderColor = .darkThemeColor
        field.font = .systemFont(ofSize: 15)
        field.textColor = .darkThemeColor
        field.leftPadding = 12
        field.clipsToBounds = true
        field.delegate = self
        field.inputAccessoryView = makeToolbar()
    }

    private func makeToolbar() -> UIToolbar {
        let bar = UIToolbar()
        bar.sizeToFit()
        bar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done".localized, style: .done, target: self, action: #selector(endEditingTapped))
        ]
        return bar
    }

    private func fill() {
        switch field {
        case .bedrooms:
            firstField.text = current.bedrooms.map(String.init)
        case .bathrooms:
            firstField.text = current.bathrooms.map(String.init)
        case .price:
            firstField.text = current.minPrice.map(String.init)
            secondField.text = current.maxPrice.map(String.init)
        case .size:
            firstField.text = current.minSize.map(String.init)
            secondField.text = current.maxSize.map(String.init)
        }
    }

    @objc private func endEditingTapped() { view.endEditing(true) }
    @objc private func closeTapped() { dismiss(animated: true) }

    @objc private func anyTapped() {
        var next = current
        switch field {
        case .bedrooms: next.bedrooms = nil
        case .bathrooms: next.bathrooms = nil
        case .price: next.minPrice = nil; next.maxPrice = nil
        case .size: next.minSize = nil; next.maxSize = nil
        }
        onSubmit(next)
        dismiss(animated: true)
    }

    @objc private func submitTapped() {
        view.endEditing(true)
        var next = current
        switch field {
        case .bedrooms:
            next.bedrooms = intValue(firstField)
        case .bathrooms:
            next.bathrooms = intValue(firstField)
        case .price:
            next.minPrice = intValue(firstField)
            next.maxPrice = intValue(secondField)
        case .size:
            next.minSize = intValue(firstField)
            next.maxSize = intValue(secondField)
        }
        onSubmit(next)
        dismiss(animated: true)
    }

    private func intValue(_ field: UITextField) -> Int? {
        let text = field.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard text.isEmpty == false else { return nil }
        return Int(text)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty { return true }
        return string.allSatisfy(\.isNumber)
    }
}