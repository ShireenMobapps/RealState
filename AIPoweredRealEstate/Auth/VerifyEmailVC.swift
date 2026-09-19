//
//  VerifyEmailVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class VerifyEmailVC: UIViewController {

    var selectedRole: String = "agent"
    var prefilledEmail: String = ""
    var pendingLoginResponse: LoginResponse?
    var onApproved: ((LoginResponse) -> Void)?

    private let headerView = UIView()
    private let logoContainerView = CustomView()
    private let logoImageView = UIImageView(image: UIImage(named: "appLogo"))
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let formCardView = CustomView()
    private let emailTextField = CustomTextField()
    private let errorLabel = UILabel()
    private let verifyButton = CustomButton(type: .system)
    private let backButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
        applyStyle()
        emailTextField.text = prefilledEmail
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

    private func applyStyle() {
        view.backgroundColor = .screenBackgroundColor
        CommonMethods.applyHeaderGradient(on: headerView, cornerRadius: 32)
        CommonMethods.styleLogoContainer(logoContainerView)
        CommonMethods.styleFormCard(formCardView)
        CommonMethods.styleTextField(emailTextField)
        CommonMethods.stylePrimaryButton(verifyButton)

        titleLabel.text = "Verify Email"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        subtitleLabel.text = "Enter your email to verify your account"
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2

        emailTextField.placeholder = "Email"
        emailTextField.keyboardType = .emailAddress
        emailTextField.textContentType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.leftPadding = 14
        emailTextField.cornerRadious = 12

        errorLabel.font = .systemFont(ofSize: 13)
        errorLabel.textColor = UIColor(red: 0.835, green: 0.263, blue: 0.259, alpha: 1)
        errorLabel.numberOfLines = 0
        errorLabel.text = nil

        verifyButton.setTitle("Verify Email", for: .normal)
        verifyButton.setTitleColor(.white, for: .normal)
        verifyButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        verifyButton.cornerRadious = 14

        CommonMethods.stylePageBackButton(backButton, tint: .white)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        verifyButton.addTarget(self, action: #selector(verifyTapped), for: .touchUpInside)
    }

    private func buildLayout() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        logoContainerView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        formCardView.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        verifyButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false

        logoImageView.contentMode = .scaleAspectFit
        logoContainerView.cornerRadious = 18

        view.addSubview(headerView)
        view.addSubview(formCardView)
        headerView.addSubview(backButton)
        headerView.addSubview(logoContainerView)
        logoContainerView.addSubview(logoImageView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(subtitleLabel)
        formCardView.addSubview(emailTextField)
        formCardView.addSubview(errorLabel)
        formCardView.addSubview(verifyButton)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 270),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 28),
            backButton.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 62),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),

            logoContainerView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            logoContainerView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 68),
            logoContainerView.widthAnchor.constraint(equalToConstant: 64),
            logoContainerView.heightAnchor.constraint(equalToConstant: 64),

            logoImageView.topAnchor.constraint(equalTo: logoContainerView.topAnchor, constant: 8),
            logoImageView.leadingAnchor.constraint(equalTo: logoContainerView.leadingAnchor, constant: 8),
            logoImageView.trailingAnchor.constraint(equalTo: logoContainerView.trailingAnchor, constant: -8),
            logoImageView.bottomAnchor.constraint(equalTo: logoContainerView.bottomAnchor, constant: -8),

            titleLabel.topAnchor.constraint(equalTo: logoContainerView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            formCardView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -24),
            formCardView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            formCardView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),

            emailTextField.topAnchor.constraint(equalTo: formCardView.topAnchor, constant: 24),
            emailTextField.leadingAnchor.constraint(equalTo: formCardView.leadingAnchor, constant: 18),
            emailTextField.trailingAnchor.constraint(equalTo: formCardView.trailingAnchor, constant: -18),
            emailTextField.heightAnchor.constraint(equalToConstant: 52),

            errorLabel.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 8),
            errorLabel.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),

            verifyButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 16),
            verifyButton.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            verifyButton.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),
            verifyButton.heightAnchor.constraint(equalToConstant: 52),
            verifyButton.bottomAnchor.constraint(equalTo: formCardView.bottomAnchor, constant: -24)
        ])
    }

    @objc private func backTapped() {
        if let navigationController, navigationController.viewControllers.first !== self {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func verifyTapped() {
        errorLabel.text = nil
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard email.isEmpty == false else {
            errorLabel.text = "Please enter your email address.".localized
            return
        }

        setLoading(true)
        Task {
            do {
                let response = try await AuthViewModel.resendVerificationAPI(param: ["email": email])
                await MainActor.run {
                    self.setLoading(false)
                    self.handleVerifyResponse(response)
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.errorLabel.text = (error as? APIError)?.errorDescription
                        ?? "Unable to verify email. Please try again.".localized
                }
            }
        }
    }

    private func handleVerifyResponse(_ response: VerifyEmailResponse) {
        if response.success == false {
            errorLabel.text = response.message ?? "Unable to verify email. Please try again.".localized
            return
        }

        CommonMethods.showToast(
            message: response.message ?? "Please verify your email".localized,
            from: self
        )
    }

    private func setLoading(_ loading: Bool) {
        verifyButton.isEnabled = !loading
        verifyButton.alpha = loading ? 0.6 : 1
        view.isUserInteractionEnabled = !loading
    }
}
