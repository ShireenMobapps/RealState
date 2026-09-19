//
//  ChooseLanguageVC.swift
//  AIPoweredRealEstate
//

import UIKit

class ChooseLanguageVC: UIViewController {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var logoContainerView: CustomView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var englishCardView: CustomView!
    @IBOutlet weak var spanishCardView: CustomView!
    @IBOutlet weak var englishCheckView: UIImageView!
    @IBOutlet weak var spanishCheckView: UIImageView!
    @IBOutlet weak var continueButton: CustomButton!

    private var selectedCode: String = LanguageManager.shared.currentLanguage == "es" ? "es" : "en"

    override func viewDidLoad() {
        super.viewDidLoad()
        applyStyle()
        refreshSelection()
        refreshCopy()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CommonMethods.updateGradientFrame(for: headerView)
        CommonMethods.updateGradientFrame(for: continueButton)
    }

    private func applyStyle() {
        view.backgroundColor = .screenBackgroundColor
        CommonMethods.applyHeaderGradient(on: headerView, cornerRadius: 32)
        CommonMethods.styleLogoContainer(logoContainerView)
        CommonMethods.stylePrimaryButton(continueButton)
        style(card: englishCardView)
        style(card: spanishCardView)
    }

    private func style(card: CustomView) {
        card.backgroundColor = .white
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 1.5
        card.layer.shadowColor = UIColor.darkThemeColor.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowRadius = 12
        card.layer.shadowOffset = CGSize(width: 0, height: 6)
    }

    private func refreshCopy() {
        titleLabel.text = LanguageManager.shared.localisedstr(key: "choose_language")
        subtitleLabel.text = LanguageManager.shared.localisedstr(key: "choose_language_subtitle")
        continueButton.setTitle(LanguageManager.shared.localisedstr(key: "continue"), for: .normal)
    }

    private func refreshSelection() {
        let englishOn = selectedCode == "en"
        highlight(card: englishCardView, check: englishCheckView, selected: englishOn)
        highlight(card: spanishCardView, check: spanishCheckView, selected: !englishOn)
    }

    private func highlight(card: CustomView, check: UIImageView, selected: Bool) {
        card.layer.borderColor = (selected ? UIColor.accentThemeColor : UIColor.cardBorderColor).cgColor
        check.image = UIImage(systemName: selected ? "checkmark.circle.fill" : "circle")
        check.tintColor = selected ? .accentThemeColor : UIColor(white: 0.75, alpha: 1)
    }

    @IBAction func englishTapped(_ sender: Any) {
        select("en")
    }

    @IBAction func spanishTapped(_ sender: Any) {
        select("es")
    }

    @IBAction func continueTapped(_ sender: Any) {
        LanguageManager.shared.currentLanguage = selectedCode
        TenantAccount.shared.language = selectedCode == "es" ? "Español" : "English"
        guard let welcomeVC = storyboard?.instantiateViewController(withIdentifier: "WelcomeVC") as? WelcomeVC else {
            return
        }
        navigationController?.pushViewController(welcomeVC, animated: true)
    }

    private func select(_ code: String) {
        selectedCode = code
        LanguageManager.shared.currentLanguage = code
        refreshSelection()
        refreshCopy()
    }
}
