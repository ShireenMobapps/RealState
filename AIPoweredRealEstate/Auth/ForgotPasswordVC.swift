//
//  ForgotPasswordVC.swift
//  AIPoweredRealEstate
//

import UIKit

class ForgotPasswordVC: UIViewController {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var logoContainerView: CustomView!
    @IBOutlet weak var formCardView: CustomView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var emailTextField: CustomTextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var sendButton: CustomButton!

    var selectedRole: String = "buyer"

    override func viewDidLoad() {
        super.viewDidLoad()
        applyStyle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CommonMethods.updateGradientFrame(for: headerView)
        CommonMethods.updateGradientFrame(for: sendButton)
    }

    private func applyStyle() {
        view.backgroundColor = .screenBackgroundColor
        CommonMethods.applyHeaderGradient(on: headerView, cornerRadius: 32)
        CommonMethods.styleLogoContainer(logoContainerView)
        CommonMethods.styleFormCard(formCardView)
        CommonMethods.styleTextField(emailTextField)
        CommonMethods.stylePrimaryButton(sendButton)

        titleLabel.text = "Forgot Password".localized
        subtitleLabel.text = "Enter your email to receive a reset link".localized
        sendButton.setTitle("Send OTP".localized, for: .normal)
        errorLabel.text = nil
        if let loginButton = formCardView.subviews.compactMap({ $0 as? UIButton }).first(where: {
            ($0.currentTitle ?? "").localizedCaseInsensitiveContains("login")
        }) {
            loginButton.setImage(nil, for: .normal)
            loginButton.configuration?.image = nil
        }
    }

    @IBAction func backTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func sendResetTapped(_ sender: UIButton) {
        errorLabel.text = nil
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !email.isEmpty else {
            errorLabel.text = "Please enter your email address.".localized
            return
        }

        sendButton.isEnabled = false
        Task {
            do {
                let response = try await AuthViewModel.forgotPasswordSendOTPAPI(param: [
                    "email": email,
                    "language": LanguageManager.shared.currentLanguage
                ])
                await MainActor.run {
                    let message = response.message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    CommonMethods.showAlert(
                        message: message.isEmpty ? "OTP sent successfully.".localized : message,
                        from: self
                    ) {
                        self.sendButton.isEnabled = true
                        self.openOTP(email: email)
                    }
                }
            } catch {
                await MainActor.run {
                    self.sendButton.isEnabled = true
                    let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.errorLabel.text = message.isEmpty
                        ? "Unable to send OTP. Please try again.".localized
                        : message
                }
            }
        }
    }

    private func openOTP(email: String) {
        guard let otpVC = storyboard?.instantiateViewController(withIdentifier: "OTPVerificationVC") as? OTPVerificationVC else {
            return
        }
        otpVC.selectedRole = selectedRole
        otpVC.email = email
        otpVC.purpose = .passwordReset
        navigationController?.pushViewController(otpVC, animated: true)
    }

    @IBAction func backToLoginTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    
}
