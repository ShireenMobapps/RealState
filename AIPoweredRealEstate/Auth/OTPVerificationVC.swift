//
//  OTPVerificationVC.swift
//  AIPoweredRealEstate
//

import UIKit

enum OTPPurpose {
    case accountVerification
    case passwordReset
}

class OTPVerificationVC: UIViewController {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var logoContainerView: CustomView!
    @IBOutlet weak var formCardView: CustomView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var otpTextField: CustomTextField!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var verifyButton: CustomButton!
    @IBOutlet weak var resendButton: UIButton?

    var selectedRole: String = "buyer"
    var email: String = ""
    var purpose: OTPPurpose = .accountVerification

    private var secondsRemaining = 60
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        applyStyle()
        startTimer()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CommonMethods.updateGradientFrame(for: headerView)
        CommonMethods.updateGradientFrame(for: verifyButton)
    }

    deinit {
        timer?.invalidate()
    }

    private func applyStyle() {
        view.backgroundColor = .screenBackgroundColor
        CommonMethods.applyHeaderGradient(on: headerView, cornerRadius: 32)
        CommonMethods.styleLogoContainer(logoContainerView)
        CommonMethods.styleFormCard(formCardView)
        CommonMethods.styleTextField(otpTextField)
        CommonMethods.stylePrimaryButton(verifyButton)

        titleLabel.text = "Verify OTP".localized
        subtitleLabel.text = email.isEmpty
            ? "Enter the OTP sent to your email".localized
            : "Enter the OTP sent to %@".localized(email)
        subtitleLabel.numberOfLines = 3
        subtitleLabel.lineBreakMode = .byWordWrapping
        errorLabel.text = nil
        otpTextField.keyboardType = .numberPad
        if resendButton == nil {
            resendButton = formCardView.subviews.compactMap { $0 as? UIButton }.first {
                ($0.actions(forTarget: self, forControlEvent: .touchUpInside) ?? []).contains("resendTapped:")
            }
        }
    }

    @IBAction func backTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func verifyTapped(_ sender: UIButton) {
        errorLabel.text = nil
        let otp = otpTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard otp.count >= 4 else {
            errorLabel.text = "Please enter a valid OTP.".localized
            return
        }

        switch purpose {
        case .accountVerification:
            popToLogin()
        case .passwordReset:
            verifyForgotPasswordOTP(otp)
        }
    }

    @IBAction func resendTapped(_ sender: UIButton) {
        errorLabel.text = nil
        guard purpose == .passwordReset else {
            secondsRemaining = 60
            startTimer()
            return
        }
        sender.isEnabled = false
        Task {
            do {
                let response = try await AuthViewModel.forgotPasswordSendOTPAPI(param: [
                    "email": email,
                    "language": LanguageManager.shared.currentLanguage
                ])
                await MainActor.run {
                    sender.isEnabled = true
                    self.secondsRemaining = 60
                    self.startTimer()
                    let message = response.message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    CommonMethods.showToast(
                        message: message.isEmpty ? "OTP sent successfully.".localized : message,
                        from: self,
                        below: self.resendButton ?? sender,
                        textColor: .darkThemeColor
                    )
                }
            } catch {
                await MainActor.run {
                    sender.isEnabled = true
                    let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.errorLabel.text = message.isEmpty
                        ? "Unable to send OTP. Please try again.".localized
                        : message
                }
            }
        }
    }

    private func verifyForgotPasswordOTP(_ otp: String) {
        verifyButton.isEnabled = false
        Task {
            do {
                let response = try await AuthViewModel.forgotPasswordVerifyOTPAPI(param: [
                    "email": email,
                    "otp": otp,
                    "language": LanguageManager.shared.currentLanguage
                ])
                await MainActor.run {
                    let message = response.message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    CommonMethods.showAlert(
                        message: message.isEmpty ? "OTP verified successfully.".localized : message,
                        from: self
                    ) {
                        self.verifyButton.isEnabled = true
                        self.openResetPassword(otp: otp)
                    }
                }
            } catch {
                await MainActor.run {
                    self.verifyButton.isEnabled = true
                    let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.errorLabel.text = message.isEmpty
                        ? "Unable to verify OTP. Please try again.".localized
                        : message
                }
            }
        }
    }

    private func openResetPassword(otp: String) {
        guard let resetVC = storyboard?.instantiateViewController(withIdentifier: "ResetPasswordVC") as? ResetPasswordVC else {
            return
        }
        resetVC.selectedRole = selectedRole
        resetVC.email = email
        resetVC.otp = otp
        navigationController?.pushViewController(resetVC, animated: true)
    }

    private func popToLogin() {
        if let loginVC = navigationController?.viewControllers.first(where: { $0 is LoginVC }) {
            navigationController?.popToViewController(loginVC, animated: true)
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
    }

    private func startTimer() {
        timer?.invalidate()
        countdownLabel.text = "Resend in %ds".localized(secondsRemaining)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { return }
            self.secondsRemaining = max(self.secondsRemaining - 1, 0)
            self.countdownLabel.text = self.secondsRemaining > 0
                ? "Resend in %ds".localized(self.secondsRemaining)
                : "You can resend now.".localized
            if self.secondsRemaining == 0 {
                timer.invalidate()
            }
        }
    }
}
