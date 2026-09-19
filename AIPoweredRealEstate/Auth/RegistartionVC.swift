//
//  RegistartionVC.swift
//  AIPoweredRealEstate
//
//  Created by Shireen on 18/08/26.
//

import UIKit
import PhotosUI

class RegistartionVC: UIViewController, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var logoContainerView: CustomView!
    @IBOutlet weak var formCardView: CustomView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var firstNameTextField: CustomTextField!
    @IBOutlet weak var lastNameTextField: CustomTextField!
    @IBOutlet weak var emailTextField: CustomTextField!
    @IBOutlet weak var phoneTextField: CustomTextField!
    @IBOutlet weak var agencyTextField: CustomTextField!
    @IBOutlet weak var licenseTextField: CustomTextField!
    @IBOutlet weak var documentButton: UIButton!
    @IBOutlet weak var passwordTextField: CustomTextField!
    @IBOutlet weak var confirmPasswordTextField: CustomTextField!
    @IBOutlet weak var termsSwitch: UISwitch!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var createAccountButton: CustomButton!
    @IBOutlet weak var loginPromptLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!

    var selectedRole: String = "buyer"
    private var selectedDocumentImage: UIImage?
    private var agencies: [AgencyItem] = []
    private var selectedAgency: AgencyItem?
    private var isLoadingAgencies = false
    private let agencyMenuButton = UIButton(type: .custom)

    private var isAgent: Bool { selectedRole == "agent" }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyStyle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        addKeyboardObservers()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CommonMethods.updateGradientFrame(for: headerView)
        CommonMethods.updateGradientFrame(for: createAccountButton)
    }

    private func applyStyle() {
        view.backgroundColor = .screenBackgroundColor
        CommonMethods.applyHeaderGradient(on: headerView, cornerRadius: 32)
        CommonMethods.styleLogoContainer(logoContainerView)
        CommonMethods.styleFormCard(formCardView)
        CommonMethods.stylePrimaryButton(createAccountButton)

        [firstNameTextField, lastNameTextField, emailTextField, phoneTextField, agencyTextField, licenseTextField, passwordTextField, confirmPasswordTextField].forEach {
            if let field = $0 {
                CommonMethods.styleTextField(field)
            }
        }

        emailTextField.keyboardType = .emailAddress
        emailTextField.textContentType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        disableSystemPasswordSuggestions(on: passwordTextField)
        disableSystemPasswordSuggestions(on: confirmPasswordTextField)
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        termsSwitch.onTintColor = .darkThemeColor
        errorLabel.text = nil

        let roleTitle = (isAgent ? "Agent" : "Tenant").localized
        titleLabel.text = "Create Account".localized
        subtitleLabel.text = "Register to continue as %@".localized(roleTitle)
        agencyTextField.placeholder = "Agency / Company name".localized
        licenseTextField.placeholder = "License number".localized
        agencyTextField.isHidden = !isAgent
        licenseTextField.isHidden = !isAgent
        documentButton.isHidden = !isAgent
        if isAgent {
            setupAgencyPickerField()
        }
        loginPromptLabel.textColor = .darkThemeColor
        loginButton.setTitleColor(.darkThemeColor, for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        styleDocumentButton()
    }

    private func setupAgencyPickerField() {
        let wrap = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
        let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevron.tintColor = .darkThemeColor
        chevron.contentMode = .scaleAspectFit
        chevron.frame = CGRect(x: 9, y: 9, width: 18, height: 18)
        wrap.addSubview(chevron)
        agencyTextField.rightView = wrap
        agencyTextField.rightViewMode = .always
        agencyTextField.isUserInteractionEnabled = false

        agencyMenuButton.translatesAutoresizingMaskIntoConstraints = false
        agencyMenuButton.backgroundColor = .clear
        agencyMenuButton.showsMenuAsPrimaryAction = true
        agencyMenuButton.changesSelectionAsPrimaryAction = false
        if agencyMenuButton.superview == nil {
            formCardView.addSubview(agencyMenuButton)
            NSLayoutConstraint.activate([
                agencyMenuButton.topAnchor.constraint(equalTo: agencyTextField.topAnchor),
                agencyMenuButton.leadingAnchor.constraint(equalTo: agencyTextField.leadingAnchor),
                agencyMenuButton.trailingAnchor.constraint(equalTo: agencyTextField.trailingAnchor),
                agencyMenuButton.bottomAnchor.constraint(equalTo: agencyTextField.bottomAnchor)
            ])
        }
        formCardView.bringSubviewToFront(agencyMenuButton)
        refreshAgencyMenu()
    }

    private func refreshAgencyMenu() {
        agencyMenuButton.menu = UIMenu(children: [
            UIDeferredMenuElement.uncached { [weak self] completion in
                guard let self else {
                    completion([])
                    return
                }
                Task {
                    await self.ensureAgenciesLoaded()
                    await MainActor.run {
                        completion(self.agencyMenuActions())
                    }
                }
            }
        ])
    }

    private func agencyMenuActions() -> [UIMenuElement] {
        let options = agencies.filter { $0.name.isEmpty == false }
        if options.isEmpty {
            return [
                UIAction(title: "No agency found".localized, attributes: .disabled, handler: { _ in })
            ]
        }
        return options.map { item in
            UIAction(
                title: item.name,
                state: item.id == selectedAgency?.id && item.id.isEmpty == false ? .on : .off
            ) { [weak self] _ in
                self?.selectedAgency = item
                self?.agencyTextField.text = item.name
            }
        }
    }

    private func ensureAgenciesLoaded() async {
        if await MainActor.run(body: { agencies.isEmpty == false }) { return }
        let alreadyLoading = await MainActor.run { () -> Bool in
            if isLoadingAgencies { return true }
            isLoadingAgencies = true
            return false
        }
        if alreadyLoading {
            while await MainActor.run(body: { isLoadingAgencies }) {
                try? await Task.sleep(nanoseconds: 40_000_000)
            }
            return
        }
        do {
            let items = try await AuthViewModel.agenciesAPI()
            await MainActor.run {
                self.agencies = items.filter { $0.name.isEmpty == false }
                self.isLoadingAgencies = false
            }
        } catch {
            await MainActor.run {
                self.isLoadingAgencies = false
            }
        }
    }

    private func disableSystemPasswordSuggestions(on field: CustomTextField) {
        field.isSecureTextEntry = true
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.spellCheckingType = .no
        field.smartDashesType = .no
        field.smartQuotesType = .no
        field.textContentType = .oneTimeCode
    }

    private func addKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardFrameWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @objc private func keyboardFrameWillChange(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let curve = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt)
            ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let keyboard = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - keyboard.minY)
        let extra = max(0, overlap - view.safeAreaInsets.bottom)

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curve << 16)
        ) {
            self.scrollView.contentInset.bottom = extra
            self.scrollView.verticalScrollIndicatorInsets.bottom = extra
            self.scrollActiveFieldAboveKeyboard()
        }
    }

    private func scrollActiveFieldAboveKeyboard() {
        let fields: [UIView?] = [
            firstNameTextField,
            lastNameTextField,
            emailTextField,
            phoneTextField,
            agencyTextField,
            licenseTextField,
            passwordTextField,
            confirmPasswordTextField
        ]
        guard let field = fields.compactMap({ $0 }).first(where: { $0.isFirstResponder }) else { return }
        let rect = field.convert(field.bounds, to: scrollView).insetBy(dx: 0, dy: -24)
        scrollView.scrollRectToVisible(rect, animated: false)
    }

    private func styleDocumentButton() {
        documentButton.backgroundColor = .screenBackgroundColor
        documentButton.layer.cornerRadius = 12
        documentButton.clipsToBounds = true
        documentButton.layer.borderWidth = 1
        documentButton.layer.borderColor = UIColor.cardBorderColor.cgColor
        documentButton.contentHorizontalAlignment = .left
        documentButton.titleLabel?.lineBreakMode = .byTruncatingMiddle
        refreshDocumentButtonTitle()
    }

    private func refreshDocumentButtonTitle() {
        if let image = selectedDocumentImage {
            let thumbSize = CGSize(width: 36, height: 36)
            let thumb = image.preparingThumbnail(of: thumbSize) ?? image
            documentButton.setImage(thumb.withRenderingMode(.alwaysOriginal), for: .normal)
            documentButton.imageView?.contentMode = .scaleAspectFill
            documentButton.imageView?.clipsToBounds = true
            documentButton.imageView?.layer.cornerRadius = 6
            documentButton.setTitle("  " + "Document image selected".localized, for: .normal)
            documentButton.setTitleColor(.black, for: .normal)
        } else {
            documentButton.setImage(nil, for: .normal)
            documentButton.setTitle("Upload license document".localized, for: .normal)
            documentButton.setTitleColor(UIColor(red: 0.66, green: 0.68, blue: 0.70, alpha: 1), for: .normal)
        }
    }

    @IBAction func backTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func pickDocumentTapped(_ sender: UIButton) {
        let sheet = UIAlertController(title: "Upload license document".localized, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Choose Photo".localized, style: .default) { [weak self] _ in
            self?.openLibrary()
        })
        sheet.addAction(UIAlertAction(title: "Take Photo".localized, style: .default) { [weak self] _ in
            self?.openCamera()
        })
        sheet.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = documentButton
            popover.sourceRect = documentButton.bounds
        }
        present(sheet, animated: true)
    }

    private func openLibrary() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func openCamera() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self?.applyDocumentImage(image)
            }
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage {
            applyDocumentImage(image)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    private func applyDocumentImage(_ image: UIImage) {
        selectedDocumentImage = normalizedImage(image)
        errorLabel.text = nil
        refreshDocumentButtonTitle()
    }

    private func normalizedImage(_ image: UIImage) -> UIImage {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale == 0 ? 1 : image.scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    @IBAction func createAccountTapped(_ sender: UIButton) {
        errorLabel.text = nil

        let firstName = firstNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lastName = lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let phone = phoneTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordTextField.text ?? ""
        let confirmPassword = confirmPasswordTextField.text ?? ""
        let agency = selectedAgency?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let agencyId = selectedAgency?.id.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let license = licenseTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !name.isEmpty else {
            errorLabel.text = "Please enter first and last name.".localized
            return
        }
        guard !email.isEmpty else {
            errorLabel.text = "Please enter your email address.".localized
            return
        }
        guard !phone.isEmpty else {
            errorLabel.text = "Please enter your phone number.".localized
            return
        }
        guard !password.isEmpty, password == confirmPassword else {
            errorLabel.text = "Passwords do not match.".localized
            return
        }
        if isAgent {
            guard !agency.isEmpty, !agencyId.isEmpty else {
                errorLabel.text = "Please select your agency.".localized
                return
            }
            guard !license.isEmpty else {
                errorLabel.text = "Please enter your license number.".localized
                return
            }
            guard selectedDocumentImage != nil else {
                errorLabel.text = "Please upload your license document.".localized
                return
            }
        }

        createAccountButton.isEnabled = false
        Task {
            do {
                if isAgent {
                    let param: [String: Any] = [
                        "name": name,
                        "email": email,
                        "password": password,
                        "phone": phone,
                        "agency": agencyId,
                        "licenseNumber": license,
                        "document": selectedDocumentImage!,
                        "preferredLanguage": LanguageManager.shared.currentLanguage
                    ]
                    let response = try await AuthViewModel.registerAgentAPI(param: param)
                    await MainActor.run {
                        createAccountButton.isEnabled = true
                        print(response.message ?? "")
                        KeyChainManager.shared.saveValue(value: selectedRole, key: "UserRole")
                        CommonMethods.showAlert(message: "Please verify your email".localized, from: self) {
                            self.goToLoginRoot(role: self.selectedRole)
                        }
                    }
                } else {
                    let param: [String: Any] = [
                        "name": name,
                        "email": email,
                        "password": password,
                        "phone": phone,
                        "role": selectedRole,
                        "preferredLanguage": LanguageManager.shared.currentLanguage
                    ]
                    let response = try await AuthViewModel.registerTenantAPI(param: param)
                    await MainActor.run {
                        createAccountButton.isEnabled = true
                        print(response.message ?? "")
                        KeyChainManager.shared.saveValue(value: selectedRole, key: "UserRole")
                        CommonMethods.showAlert(message: response.message ?? "", from: self) {
                            self.goToLoginRoot(role: self.selectedRole)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    createAccountButton.isEnabled = true
                    print(error)
                    errorLabel.text = "Unable to create account. Please try again.".localized
                }
            }
        }
    }

    @IBAction func backToLoginTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}
