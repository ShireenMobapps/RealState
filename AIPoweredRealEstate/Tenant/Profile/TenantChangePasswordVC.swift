//
//  TenantChangePasswordVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class TenantChangePasswordVC: UIViewController {

    private let headerView = UIView()
    private let logoContainerView = CustomView()
    private let logoImageView = UIImageView(image: UIImage(named: "appLogo"))
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let formCardView = CustomView()
    private let oldPasswordTextField = CustomTextField()
    private let newPasswordTextField = CustomTextField()
    private let confirmPasswordTextField = CustomTextField()
    private let updateButton = CustomButton(type: .system)
    private let backButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
        applyStyle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CommonMethods.updateGradientFrame(for: headerView)
        CommonMethods.updateGradientFrame(for: updateButton)
    }

    private func applyStyle() {
        view.backgroundColor = .screenBackgroundColor
        CommonMethods.applyHeaderGradient(on: headerView, cornerRadius: 32)
        CommonMethods.styleLogoContainer(logoContainerView)
        CommonMethods.styleFormCard(formCardView)
        CommonMethods.stylePrimaryButton(updateButton)

        titleLabel.text = "Change Password".localized
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        subtitleLabel.text = "Enter your current password and choose a new one".localized
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2

        stylePasswordField(oldPasswordTextField, placeholder: "Old password".localized)
        stylePasswordField(newPasswordTextField, placeholder: "New password".localized)
        stylePasswordField(confirmPasswordTextField, placeholder: "Confirm password".localized)

        updateButton.setTitle("Change Password".localized, for: .normal)
        updateButton.setTitleColor(.white, for: .normal)
        updateButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        updateButton.cornerRadious = 14
        updateButton.addTarget(self, action: #selector(changeTapped), for: .touchUpInside)

        CommonMethods.stylePageBackButton(backButton, tint: .white)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    private func stylePasswordField(_ field: CustomTextField, placeholder: String) {
        CommonMethods.styleTextField(field)
        field.placeholder = placeholder
        field.isSecureTextEntry = true
        field.textContentType = .password
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.leftPadding = 14
        field.cornerRadious = 12
        addEyeToggle(to: field)
    }

    private func addEyeToggle(to field: CustomTextField) {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        button.tintColor = .darkThemeColor
        button.setImage(UIImage(systemName: "eye"), for: .normal)
        button.addAction(UIAction { [weak field, weak button] _ in
            guard let field, let button else { return }
            field.isSecureTextEntry.toggle()
            let name = field.isSecureTextEntry ? "eye" : "eye.slash"
            button.setImage(UIImage(systemName: name), for: .normal)
        }, for: .touchUpInside)
        field.rightView = button
        field.rightViewMode = .always
    }

    private func buildLayout() {
        [
            headerView, logoContainerView, logoImageView, titleLabel, subtitleLabel,
            formCardView, oldPasswordTextField, newPasswordTextField, confirmPasswordTextField,
            updateButton, backButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        logoImageView.contentMode = .scaleAspectFit
        logoContainerView.cornerRadious = 18

        view.addSubview(headerView)
        view.addSubview(formCardView)
        headerView.addSubview(backButton)
        headerView.addSubview(logoContainerView)
        logoContainerView.addSubview(logoImageView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(subtitleLabel)
        formCardView.addSubview(oldPasswordTextField)
        formCardView.addSubview(newPasswordTextField)
        formCardView.addSubview(confirmPasswordTextField)
        formCardView.addSubview(updateButton)

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

            oldPasswordTextField.topAnchor.constraint(equalTo: formCardView.topAnchor, constant: 24),
            oldPasswordTextField.leadingAnchor.constraint(equalTo: formCardView.leadingAnchor, constant: 18),
            oldPasswordTextField.trailingAnchor.constraint(equalTo: formCardView.trailingAnchor, constant: -18),
            oldPasswordTextField.heightAnchor.constraint(equalToConstant: 52),

            newPasswordTextField.topAnchor.constraint(equalTo: oldPasswordTextField.bottomAnchor, constant: 12),
            newPasswordTextField.leadingAnchor.constraint(equalTo: oldPasswordTextField.leadingAnchor),
            newPasswordTextField.trailingAnchor.constraint(equalTo: oldPasswordTextField.trailingAnchor),
            newPasswordTextField.heightAnchor.constraint(equalToConstant: 52),

            confirmPasswordTextField.topAnchor.constraint(equalTo: newPasswordTextField.bottomAnchor, constant: 12),
            confirmPasswordTextField.leadingAnchor.constraint(equalTo: oldPasswordTextField.leadingAnchor),
            confirmPasswordTextField.trailingAnchor.constraint(equalTo: oldPasswordTextField.trailingAnchor),
            confirmPasswordTextField.heightAnchor.constraint(equalToConstant: 52),

            updateButton.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor, constant: 20),
            updateButton.leadingAnchor.constraint(equalTo: oldPasswordTextField.leadingAnchor),
            updateButton.trailingAnchor.constraint(equalTo: oldPasswordTextField.trailingAnchor),
            updateButton.heightAnchor.constraint(equalToConstant: 52),
            updateButton.bottomAnchor.constraint(equalTo: formCardView.bottomAnchor, constant: -24)
        ])
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func changeTapped() {
        view.endEditing(true)
        let oldPassword = oldPasswordTextField.text ?? ""
        let newPassword = newPasswordTextField.text ?? ""
        let confirmPassword = confirmPasswordTextField.text ?? ""

        guard oldPassword.isEmpty == false else {
            CommonMethods.showAlert(message: "Please enter your current password.".localized, from: self)
            return
        }
        guard newPassword.isEmpty == false else {
            CommonMethods.showAlert(message: "Please enter a new password.".localized, from: self)
            return
        }
        guard newPassword.count >= 8 else {
            CommonMethods.showAlert(message: "Password must be at least 8 characters.".localized, from: self)
            return
        }
        guard newPassword == confirmPassword else {
            CommonMethods.showAlert(message: "Passwords do not match.".localized, from: self)
            return
        }

        let param: [String: Any] = [
            "oldPassword": oldPassword,
            "newPassword": newPassword,
            "confirmPassword": confirmPassword
        ]
        setLoading(true)
        Task {
            do {
                let response = try await AuthViewModel.changePasswordAPI(param: param)
                await MainActor.run {
                    self.setLoading(false)
                    if response.success == false {
                        let message = (response.message ?? "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        CommonMethods.showAlert(
                            message: message.isEmpty ? "Unable to change password. Please try again.".localized : message,
                            from: self
                        )
                        return
                    }
                    let message = (response.message ?? "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    CommonMethods.showAlert(
                        message: message.isEmpty ? "Password changed successfully.".localized : message,
                        from: self
                    ) {
                        let _ = KeyChainManager.shared.deleteValue(key: "token")
                        NotificationUnreadStore.shared.reset()
                        self.goToLoginRoot()
                    }
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    let message = ((error as? APIError)?.errorDescription ?? error.localizedDescription)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    CommonMethods.showAlert(
                        message: message.isEmpty ? "Unable to change password. Please try again.".localized : message,
                        from: self
                    )
                }
            }
        }
    }

    private func setLoading(_ loading: Bool) {
        updateButton.isEnabled = !loading
        updateButton.alpha = loading ? 0.6 : 1
        view.isUserInteractionEnabled = !loading
    }
}
