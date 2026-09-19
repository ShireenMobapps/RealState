//
//  WelcomeVC.swift
//  AIPoweredRealEstate
//
//  Created by Shireen on 18/08/26.
//

import UIKit

enum UserRole:String{
    case tenant = "buyer"
    case agent = "agent"
}

class WelcomeVC: UIViewController {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var logoContainerView: CustomView!
    @IBOutlet weak var tenantCardView: CustomView!
    @IBOutlet weak var agentCardView: CustomView!
    @IBOutlet weak var tenantIconView: CustomView!
    @IBOutlet weak var agentIconView: CustomView!
    @IBOutlet weak var selectLanguageButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        applyWelcomeStyle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        refreshLocalizedCopy()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CommonMethods.updateGradientFrame(for: headerView)
        CommonMethods.updateGradientFrame(for: tenantIconView)
        CommonMethods.updateGradientFrame(for: agentIconView)
    }

    private func applyWelcomeStyle() {
        view.backgroundColor = .screenBackgroundColor
        CommonMethods.applyHeaderGradient(on: headerView, cornerRadius: 36)
        styleLogoContainer()
        style(card: tenantCardView)
        style(card: agentCardView)
        style(iconView: tenantIconView)
        style(iconView: agentIconView)
        selectLanguageButton.setTitleColor(.darkThemeColor, for: .normal)
        selectLanguageButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        selectLanguageButton.backgroundColor = .clear
        refreshLocalizedCopy()
    }

    private func refreshLocalizedCopy() {
        selectLanguageButton.setTitle("Select Language".localized, for: .normal)
    }

    private func styleLogoContainer() {
        logoContainerView.backgroundColor = .white
        logoContainerView.layer.cornerRadius = 22
        logoContainerView.layer.shadowColor = UIColor.black.cgColor
        logoContainerView.layer.shadowOpacity = 0.14
        logoContainerView.layer.shadowRadius = 12
        logoContainerView.layer.shadowOffset = CGSize(width: 0, height: 6)
    }

    private func style(card: CustomView) {
        card.backgroundColor = .white
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.cardBorderColor.cgColor
        card.layer.shadowColor = UIColor.darkThemeColor.cgColor
        card.layer.shadowOpacity = 0.10
        card.layer.shadowRadius = 14
        card.layer.shadowOffset = CGSize(width: 0, height: 8)
    }

    private func style(iconView: CustomView) {
        iconView.backgroundColor = .darkThemeColor
        iconView.layer.cornerRadius = 16
        CommonMethods.gradientOverView(view: iconView)
        iconView.clipsToBounds = true
    }

    @IBAction func selectLanguageTapped(_ sender: UIButton) {
        let languageVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "ChooseLanguageVC")
        let nav = UINavigationController(rootViewController: languageVC)
        nav.setNavigationBarHidden(true, animated: false)
        CommonMethods.setRootViewController(nav)
    }

    @IBAction func tenantTapped(_ sender: UIButton) {
        openLogin(for: .tenant)
    }

    @IBAction func agentTapped(_ sender: UIButton) {
        openLogin(for: .agent)
    }

    private func openLogin(for role: UserRole) {
        guard let loginVC = storyboard?.instantiateViewController(withIdentifier: "LoginVC") as? LoginVC else {
            return
        }
        loginVC.selectedRole = role.rawValue
        navigationController?.pushViewController(loginVC, animated: true)
    }
}
