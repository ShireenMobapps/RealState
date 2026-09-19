//
//  TenantPreferencesVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class TenantPreferencesVC: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentStack: UIStackView!

    private var types: Set<String> = []
    private var locations: Set<String> = []
    private var budgetMax: Int? = 0
    private var minBedrooms: Int? = 0
    private var amenities: Set<String> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        TenantProfileStyle.applyPushed(self, title: "My Preferences")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save".localized, style: .done, target: self, action: #selector(saveTapped))
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func reload() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        addSection("Property Type", options: PropertyStore.propertyTypes, selected: types, action: #selector(typeTapped(_:)))
        addSection("Preferred Locations", options: PropertyStore.locations, selected: locations, action: #selector(locationTapped(_:)))
        addSection("Budget", options: ["Any", "Up to $1,500", "Up to $5,000", "Up to $300k", "Up to $500k", "$500k+"], selected: budgetTitle(), action: #selector(budgetTapped(_:)), multi: false)
        addSection("Bedrooms", options: ["Any", "1+", "2+", "3+", "4+"], selected: bedsTitle(), action: #selector(bedsTapped(_:)), multi: false)
        addSection("Amenities", options: PropertyStore.amenityOptions, selected: amenities, action: #selector(amenityTapped(_:)))
    }

    private func addSection(_ title: String, options: [String], selected: Set<String>, action: Selector) {
        addSection(title, options: options, selected: nil, action: action, multi: true, selectedSet: selected)
    }

    private func addSection(_ title: String, options: [String], selected: String, action: Selector, multi: Bool) {
        addSection(title, options: options, selected: selected, action: action, multi: false, selectedSet: [])
    }

    private func addSection(_ title: String, options: [String], selected: String?, action: Selector, multi: Bool, selectedSet: Set<String>) {
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
            let isOn = multi ? selectedSet.contains(option) : option == selected
            let button = CommonMethods.makeFilterChip(title: option, selected: isOn)
            button.addTarget(self, action: action, for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
        let section = UIStackView(arrangedSubviews: [label, row])
        section.axis = .vertical
        section.spacing = 10
        contentStack.addArrangedSubview(section)
    }

    @objc private func typeTapped(_ sender: UIButton) {
        types = toggled(types, chipTitle(sender))
        reload()
    }

    @objc private func locationTapped(_ sender: UIButton) {
        locations = toggled(locations, chipTitle(sender))
        reload()
    }

    @objc private func amenityTapped(_ sender: UIButton) {
        amenities = toggled(amenities, chipTitle(sender))
        reload()
    }

    private func chipTitle(_ sender: UIButton) -> String? {
        sender.chipValue
    }

    @objc private func budgetTapped(_ sender: UIButton) {
        switch sender.chipValue {
        case "Up to $1,500": budgetMax = 1_500
        case "Up to $5,000": budgetMax = 5_000
        case "Up to $300k": budgetMax = 300_000
        case "Up to $500k": budgetMax = 500_000
        case "$500k+": budgetMax = 900_000
        default: budgetMax = nil
        }
        reload()
    }

    @objc private func bedsTapped(_ sender: UIButton) {
        let title = sender.chipValue
        minBedrooms = title == "Any" ? nil : Int(title.replacingOccurrences(of: "+", with: ""))
        reload()
    }

    @objc private func saveTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func toggled(_ current: Set<String>, _ value: String?) -> Set<String> {
        guard let value, !value.isEmpty else { return current }
        var next = current
        if next.contains(value) {
            next.remove(value)
        } else {
            next.insert(value)
        }
        return next
    }

    private func budgetTitle() -> String {
        switch budgetMax {
        case 1_500: return "Up to $1,500"
        case 5_000: return "Up to $5,000"
        case 300_000: return "Up to $300k"
        case 500_000: return "Up to $500k"
        case 900_000: return "$500k+"
        default: return "Any"
        }
    }

    private func bedsTitle() -> String {
        guard let minBedrooms else { return "Any" }
        return "\(minBedrooms)+"
    }
}
