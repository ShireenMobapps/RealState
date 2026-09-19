//
//  TenantSavedSearchVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class TenantSavedSearchVC: UIViewController {

    var search = SavedSearch(
        id: UUID().uuidString,
        location: nil,
        listingType: nil,
        minPrice: nil,
        maxPrice: nil,
        minBedrooms: nil,
        amenities: [],
        alertOn: true
    )
    var isNew = true

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentStack: UIStackView!

    private let alertSwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .screenBackgroundColor
        title = "Search Preference".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save".localized, style: .done, target: self, action: #selector(saveTapped))
        navigationController?.navigationBar.tintColor = .darkThemeColor
        reloadChips()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func reloadChips() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        addSection("Location", options: ["Any"] + PropertyStore.locations, selected: search.location ?? "Any", action: #selector(locationTapped(_:)))
        addSection("Buy / Rent", options: ["Any", "Buy", "Rent"], selected: search.listingType ?? "Any", action: #selector(listingTapped(_:)))
        addSection("Price", options: ["Any", "Up to $1,500", "Up to $5,000", "Up to $300k", "Up to $500k", "$500k+"], selected: priceTitle(), action: #selector(priceTapped(_:)))
        addSection("Bedrooms", options: ["Any", "1+", "2+", "3+", "4+"], selected: bedsTitle(), action: #selector(bedsTapped(_:)))
        addSection("Amenities", options: PropertyStore.amenityOptions, selected: nil, action: #selector(amenityTapped(_:)), multi: true)
        addAlertRow()
        addActionButtons()
    }

    private func addSection(_ title: String, options: [String], selected: String?, action: Selector, multi: Bool = false) {
        let label = UILabel()
        label.text = title.localized
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)

        let row = UIScrollView()
        row.showsHorizontalScrollIndicator = false
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: row.topAnchor),
            stack.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -4),
            stack.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            stack.heightAnchor.constraint(equalToConstant: 36),
            row.heightAnchor.constraint(equalToConstant: 36)
        ])

        for option in options {
            let isOn = multi ? search.amenities.contains(option) : option == selected
            let button = CommonMethods.makeFilterChip(title: option, selected: isOn)
            button.addTarget(self, action: action, for: .touchUpInside)
            stack.addArrangedSubview(button)
        }

        let section = UIStackView(arrangedSubviews: [label, row])
        section.axis = .vertical
        section.spacing = 10
        contentStack.addArrangedSubview(section)
    }

    private func addAlertRow() {
        let label = UILabel()
        label.text = "Alert".localized
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
        let detail = UILabel()
        detail.text = "Notify me about new matching properties".localized
        detail.font = .systemFont(ofSize: 13, weight: .regular)
        detail.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)
        detail.numberOfLines = 0
        let text = UIStackView(arrangedSubviews: [label, detail])
        text.axis = .vertical
        text.spacing = 4
        alertSwitch.onTintColor = .darkThemeColor
        alertSwitch.isOn = search.alertOn
        alertSwitch.removeTarget(nil, action: nil, for: .valueChanged)
        alertSwitch.addTarget(self, action: #selector(alertChanged), for: .valueChanged)
        let row = UIStackView(arrangedSubviews: [text, alertSwitch])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        contentStack.addArrangedSubview(row)
    }

    private func addActionButtons() {
        let results = UIButton(type: .system)
        results.setTitle("View Results".localized, for: .normal)
        results.setTitleColor(.darkThemeColor, for: .normal)
        results.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        results.layer.cornerRadius = 14
        results.layer.borderWidth = 1
        results.layer.borderColor = UIColor.darkThemeColor.cgColor
        results.backgroundColor = .white
        results.heightAnchor.constraint(equalToConstant: 50).isActive = true
        results.addTarget(self, action: #selector(viewResultsTapped), for: .touchUpInside)

        let save = UIButton(type: .system)
        save.setTitle("Save Preference".localized, for: .normal)
        save.setTitleColor(.white, for: .normal)
        save.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        CommonMethods.stylePrimaryButton(save)
        save.heightAnchor.constraint(equalToConstant: 50).isActive = true
        save.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        contentStack.addArrangedSubview(results)
        contentStack.addArrangedSubview(save)
    }

    @objc private func locationTapped(_ sender: UIButton) {
        let title = sender.chipValue
        search.location = title == "Any" ? nil : title
        reloadChips()
    }

    @objc private func listingTapped(_ sender: UIButton) {
        let title = sender.chipValue
        search.listingType = title == "Any" ? nil : title
        reloadChips()
    }

    @objc private func priceTapped(_ sender: UIButton) {
        switch sender.chipValue {
        case "Up to $1,500": search.minPrice = nil; search.maxPrice = 1_500
        case "Up to $5,000": search.minPrice = nil; search.maxPrice = 5_000
        case "Up to $300k": search.minPrice = nil; search.maxPrice = 300_000
        case "Up to $500k": search.minPrice = nil; search.maxPrice = 500_000
        case "$500k+": search.minPrice = 500_000; search.maxPrice = nil
        default: search.minPrice = nil; search.maxPrice = nil
        }
        reloadChips()
    }

    @objc private func bedsTapped(_ sender: UIButton) {
        let title = sender.chipValue
        search.minBedrooms = title == "Any" ? nil : Int(title.replacingOccurrences(of: "+", with: ""))
        reloadChips()
    }

    @objc private func amenityTapped(_ sender: UIButton) {
        let title = sender.chipValue
        if search.amenities.contains(title) {
            search.amenities.remove(title)
        } else {
            search.amenities.insert(title)
        }
        reloadChips()
    }

    @objc private func alertChanged() {
        search.alertOn = alertSwitch.isOn
    }

    @objc private func saveTapped() {
        PropertyStore.shared.upsertSearch(search)
        navigationController?.popViewController(animated: true)
    }

    @objc private func viewResultsTapped() {
        PropertyStore.shared.upsertSearch(search)
        PropertyStore.shared.applySavedSearch(search)
        tabBarController?.selectedIndex = 1
        navigationController?.popToRootViewController(animated: false)
    }

    private func priceTitle() -> String {
        if search.minPrice == 500_000 { return "$500k+" }
        switch search.maxPrice {
        case 1_500: return "Up to $1,500"
        case 5_000: return "Up to $5,000"
        case 300_000: return "Up to $300k"
        case 500_000: return "Up to $500k"
        default: return "Any"
        }
    }

    private func bedsTitle() -> String {
        guard let value = search.minBedrooms else { return "Any" }
        return "\(value)+"
    }
}
