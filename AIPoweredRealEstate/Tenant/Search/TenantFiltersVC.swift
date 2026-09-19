//
//  TenantFiltersVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class TenantFiltersVC: UIViewController {

    var criteria = PropertySearchCriteria()
    var onApply: ((PropertySearchCriteria) -> Void)?

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentStack: UIStackView!
    @IBOutlet weak var applyButton: CustomButton!

    @IBOutlet var locationButtons: [UIButton]!
    @IBOutlet var typeButtons: [UIButton]!
    @IBOutlet var priceButtons: [UIButton]!
    @IBOutlet var bedroomButtons: [UIButton]!
    @IBOutlet var bathroomButtons: [UIButton]!
    @IBOutlet var sizeButtons: [UIButton]!
    @IBOutlet var furnishedButtons: [UIButton]!
    @IBOutlet var amenityButtons: [UIButton]!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .screenBackgroundColor
        title = "Filters".localized
        navigationItem.leftBarButtonItem?.title = "Reset".localized
        navigationItem.rightBarButtonItem?.title = "Done".localized
        navigationController?.navigationBar.tintColor = .darkThemeColor
        applyButton.setTitle("Apply Filters".localized, for: .normal)
        CommonMethods.stylePrimaryButton(applyButton)
        refreshSelection()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CommonMethods.updateGradientFrame(for: applyButton)
    }

    private func refreshSelection() {
        style(locationButtons, selected: criteria.location ?? "Any")
        style(typeButtons, selected: criteria.propertyType ?? "Any")
        style(priceButtons, selected: priceTitle())
        style(bedroomButtons, selected: bedsTitle())
        style(bathroomButtons, selected: bathsTitle())
        style(sizeButtons, selected: areaTitle())
        style(furnishedButtons, selected: furnishedTitle())
        for button in amenityButtons ?? [] {
            let value = button.chipValue
            CommonMethods.styleFilterChip(button, title: value, selected: criteria.amenities.contains(value))
        }
    }

    private func style(_ buttons: [UIButton]?, selected: String) {
        buttons?.forEach { button in
            let value = button.chipValue
            CommonMethods.styleFilterChip(button, title: value, selected: value == selected)
        }
    }

    @IBAction func locationTapped(_ sender: UIButton) {
        let title = sender.chipValue
        criteria.location = title == "Any" ? nil : title
        refreshSelection()
    }

    @IBAction func typeTapped(_ sender: UIButton) {
        let title = sender.chipValue
        criteria.propertyType = title == "Any" ? nil : title
        refreshSelection()
    }

    @IBAction func priceTapped(_ sender: UIButton) {
        switch sender.chipValue {
        case "Up to $1,500":
            criteria.minPrice = nil
            criteria.maxPrice = 1_500
        case "Up to $5,000":
            criteria.minPrice = nil
            criteria.maxPrice = 5_000
        case "Up to $300k":
            criteria.minPrice = nil
            criteria.maxPrice = 300_000
        case "Up to $500k":
            criteria.minPrice = nil
            criteria.maxPrice = 500_000
        case "$500k+":
            criteria.minPrice = 500_000
            criteria.maxPrice = nil
        default:
            criteria.minPrice = nil
            criteria.maxPrice = nil
        }
        refreshSelection()
    }

    @IBAction func bedsTapped(_ sender: UIButton) {
        criteria.minBedrooms = intPrefix(sender.chipValue)
        refreshSelection()
    }

    @IBAction func bathsTapped(_ sender: UIButton) {
        criteria.minBathrooms = intPrefix(sender.chipValue)
        refreshSelection()
    }

    @IBAction func areaTapped(_ sender: UIButton) {
        switch sender.chipValue {
        case "80+ m²": criteria.minArea = 80; criteria.maxArea = nil
        case "150+ m²": criteria.minArea = 150; criteria.maxArea = nil
        case "300+ m²": criteria.minArea = 300; criteria.maxArea = nil
        default: criteria.minArea = nil; criteria.maxArea = nil
        }
        refreshSelection()
    }

    @IBAction func furnishedTapped(_ sender: UIButton) {
        switch sender.chipValue {
        case "Yes": criteria.furnished = true
        case "No": criteria.furnished = false
        default: criteria.furnished = nil
        }
        refreshSelection()
    }

    @IBAction func amenityTapped(_ sender: UIButton) {
        let title = sender.chipValue
        if criteria.amenities.contains(title) {
            criteria.amenities.remove(title)
        } else {
            criteria.amenities.insert(title)
        }
        refreshSelection()
    }

    @IBAction func resetTapped(_ sender: Any) {
        criteria.resetFilters()
        refreshSelection()
    }

    @IBAction func applyTapped(_ sender: Any) {
        onApply?(criteria)
        dismiss(animated: true)
    }

    private func intPrefix(_ title: String?) -> Int? {
        guard let title, title != "Any" else { return nil }
        return Int(title.replacingOccurrences(of: "+", with: ""))
    }

    private func priceTitle() -> String {
        if criteria.minPrice == 500_000 { return "$500k+" }
        switch criteria.maxPrice {
        case 1_500: return "Up to $1,500"
        case 5_000: return "Up to $5,000"
        case 300_000: return "Up to $300k"
        case 500_000: return "Up to $500k"
        default: return "Any"
        }
    }

    private func bedsTitle() -> String {
        guard let value = criteria.minBedrooms else { return "Any" }
        return "\(value)+"
    }

    private func bathsTitle() -> String {
        guard let value = criteria.minBathrooms else { return "Any" }
        return "\(value)+"
    }

    private func areaTitle() -> String {
        switch criteria.minArea {
        case 80: return "80+ m²"
        case 150: return "150+ m²"
        case 300: return "300+ m²"
        default: return "Any"
        }
    }

    private func furnishedTitle() -> String {
        switch criteria.furnished {
        case true: return "Yes"
        case false: return "No"
        default: return "Any"
        }
    }
}
