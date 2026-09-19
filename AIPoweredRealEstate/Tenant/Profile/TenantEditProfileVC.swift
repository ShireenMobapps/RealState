//
//  TenantEditProfileVC.swift
//  AIPoweredRealEstate
//

import UIKit
import PhotosUI

final class TenantEditProfileVC: UIViewController, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var cameraButton: UIButton?
    @IBOutlet weak var nameField: CustomTextField!
    @IBOutlet weak var emailField: CustomTextField!
    @IBOutlet weak var phoneField: CustomTextField!
    @IBOutlet weak var addressField: CustomTextField?
    @IBOutlet weak var agencyField: CustomTextField?
    @IBOutlet weak var licenseField: CustomTextField?
    @IBOutlet weak var documentButton: UIButton?
    @IBOutlet weak var documentTitleLabel: UILabel?
    @IBOutlet weak var saveButton: CustomButton!
    @IBOutlet weak var formCardView: CustomView!
    @IBOutlet weak var errorLabel: UILabel?

    private var pendingPhoto: UIImage?
    private var pendingDocument: UIImage?
    private var pickingDocument = false
    private var existingDocumentURL: String?
    private var profileModel: GetProfileResponseModel?
    private let documentPreview = UIImageView()
    private let documentBadge = UIImageView()
    private var documentHeightConstraint: NSLayoutConstraint?
    
    var agencyId: String = ""

    private var isAgent: Bool {
        let role = (KeyChainManager.shared.getValue(key: "UserRole") ?? "").lowercased()
        return role == "agent" || role == "realtor" || role == "broker" || isAgentFlow
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        TenantProfileStyle.applyPushed(self, title: "Edit Profile")
        photoView.contentMode = .scaleAspectFill
        photoView.clipsToBounds = true
        photoView.isUserInteractionEnabled = true
        photoView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(changePhotoTapped)))
        installCameraButtonIfNeeded()
        cameraButton?.clipsToBounds = true
        cameraButton?.backgroundColor = .accentThemeColor
        cameraButton?.tintColor = .white
        [nameField, emailField, phoneField, addressField, agencyField, licenseField].compactMap { $0 }.forEach {
            CommonMethods.styleTextField($0)
        }
        CommonMethods.styleFormCard(formCardView)
        CommonMethods.stylePrimaryButton(saveButton)
        addressField?.isHidden = true
        applyRoleFields()
        errorLabel?.text = nil
        errorLabel?.textColor = .systemRed
        errorLabel?.font = .systemFont(ofSize: 13, weight: .regular)
        errorLabel?.numberOfLines = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        loadProfile()
    }

    private func installCameraButtonIfNeeded() {
        guard cameraButton == nil else { return }
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .accentThemeColor
        button.tintColor = .white
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        button.setImage(UIImage(systemName: "camera.fill", withConfiguration: config), for: .normal)
        button.addTarget(self, action: #selector(changePhotoTapped(_:)), for: .touchUpInside)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 38),
            button.heightAnchor.constraint(equalToConstant: 38),
            button.trailingAnchor.constraint(equalTo: photoView.trailingAnchor, constant: 4),
            button.bottomAnchor.constraint(equalTo: photoView.bottomAnchor, constant: 4)
        ])
        cameraButton = button
        view.bringSubviewToFront(button)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        photoView.layer.cornerRadius = photoView.bounds.width / 2
        cameraButton?.layer.cornerRadius = (cameraButton?.bounds.width ?? 0) / 2
        CommonMethods.styleProfilePhotoCircle(photoView)
        CommonMethods.updateGradientFrame(for: saveButton)
    }

    private func applyRoleFields() {
        agencyField?.placeholder = "Agency / Company name".localized
        licenseField?.placeholder = "License number".localized
        agencyField?.isHidden = !isAgent
        licenseField?.isHidden = !isAgent
        documentButton?.isHidden = !isAgent
        documentTitleLabel?.isHidden = !isAgent
        documentTitleLabel?.text = "Document".localized
        if isAgent {
            styleDocumentButton()
            lockAgencyFieldReadOnly()
        }
    }

    private func lockAgencyFieldReadOnly() {
        guard let agencyField else { return }
        agencyField.rightView = nil
        agencyField.rightViewMode = .never
        agencyField.isEnabled = true
        agencyField.isUserInteractionEnabled = false
        agencyField.isExclusiveTouch = true
        agencyField.tintColor = .clear
    }

    private func styleDocumentButton() {
        guard let documentButton else { return }
        documentButton.backgroundColor = .screenBackgroundColor
        documentButton.layer.cornerRadius = 12
        documentButton.clipsToBounds = true
        documentButton.layer.borderWidth = 1
        documentButton.layer.borderColor = UIColor.cardBorderColor.cgColor
        documentButton.contentHorizontalAlignment = .left
        documentButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        documentButton.titleLabel?.lineBreakMode = .byTruncatingMiddle
        documentHeightConstraint = documentButton.constraints.first {
            $0.firstAttribute == .height && $0.secondItem == nil
        }
        installDocumentPreview()
        refreshDocumentButtonTitle()
    }

    private func installDocumentPreview() {
        guard let documentButton, documentPreview.superview == nil else { return }
        documentPreview.translatesAutoresizingMaskIntoConstraints = false
        documentPreview.contentMode = .scaleAspectFill
        documentPreview.clipsToBounds = true
        documentPreview.layer.cornerRadius = 10
        documentPreview.backgroundColor = UIColor(white: 0.94, alpha: 1)
        documentPreview.isUserInteractionEnabled = true
        documentPreview.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(previewDocumentTapped)))
        documentButton.insertSubview(documentPreview, at: 0)

        documentBadge.translatesAutoresizingMaskIntoConstraints = false
        documentBadge.image = UIImage(systemName: "camera.fill")
        documentBadge.tintColor = .white
        documentBadge.contentMode = .center
        documentBadge.backgroundColor = .darkThemeColor
        documentBadge.layer.cornerRadius = 16
        documentBadge.clipsToBounds = true
        documentBadge.isUserInteractionEnabled = true
        documentBadge.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(changeDocumentTapped)))
        documentButton.addSubview(documentBadge)

        NSLayoutConstraint.activate([
            documentPreview.topAnchor.constraint(equalTo: documentButton.topAnchor, constant: 8),
            documentPreview.leadingAnchor.constraint(equalTo: documentButton.leadingAnchor, constant: 8),
            documentPreview.trailingAnchor.constraint(equalTo: documentButton.trailingAnchor, constant: -8),
            documentPreview.bottomAnchor.constraint(equalTo: documentButton.bottomAnchor, constant: -8),
            documentBadge.trailingAnchor.constraint(equalTo: documentButton.trailingAnchor, constant: -14),
            documentBadge.bottomAnchor.constraint(equalTo: documentButton.bottomAnchor, constant: -14),
            documentBadge.widthAnchor.constraint(equalToConstant: 32),
            documentBadge.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    private func refreshDocumentButtonTitle() {
        guard let documentButton else { return }
        let hasImage = pendingDocument != nil || !(existingDocumentURL ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        documentHeightConstraint?.constant = hasImage ? 148 : 52
        documentPreview.isHidden = !hasImage
        documentBadge.isHidden = false
        documentButton.setImage(nil, for: .normal)
        if let image = pendingDocument {
            documentPreview.sd_cancelCurrentImageLoad()
            documentPreview.image = image
            documentButton.setTitle(nil, for: .normal)
        } else if let raw = existingDocumentURL?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
            documentPreview.sd_setImage(
                with: Constant.mediaImageURL(raw),
                placeholderImage: UIImage(named: "propertyCityApartment")
            )
            documentButton.setTitle(nil, for: .normal)
        } else {
            documentPreview.image = nil
            documentButton.setTitle("Upload license document".localized, for: .normal)
            documentButton.setTitleColor(UIColor(red: 0.66, green: 0.68, blue: 0.70, alpha: 1), for: .normal)
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @IBAction func changePhotoTapped(_ sender: Any) {
        pickingDocument = false
        presentImageSheet(title: "Profile Photo".localized)
    }

    @IBAction func pickDocumentTapped(_ sender: Any, forEvent event: UIEvent) {
        if let button = documentButton, let touch = event.touches(for: button)?.first {
            let point = touch.location(in: button)
            if documentBadge.frame.insetBy(dx: -8, dy: -8).contains(point) {
                changeDocumentTapped()
                return
            }
        }
        let hasImage = pendingDocument != nil
            || documentPreview.image != nil
            || !(existingDocumentURL ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if hasImage {
            previewDocumentTapped()
            return
        }
        changeDocumentTapped()
    }

    @objc private func changeDocumentTapped() {
        pickingDocument = true
        presentImageSheet(title: "Upload license document".localized)
    }

    @objc private func previewDocumentTapped() {
        let hasImage = pendingDocument != nil
            || documentPreview.image != nil
            || !(existingDocumentURL ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard hasImage else {
            changeDocumentTapped()
            return
        }
        let viewer = DocumentFullScreenVC()
        viewer.image = pendingDocument ?? documentPreview.image
        viewer.imagePath = existingDocumentURL
        viewer.modalPresentationStyle = .fullScreen
        viewer.modalTransitionStyle = .crossDissolve
        present(viewer, animated: true)
    }

    private func presentImageSheet(title: String) {
        let sheet = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Choose Photo".localized, style: .default) { [weak self] _ in
            self?.openLibrary()
        })
        sheet.addAction(UIAlertAction(title: "Take Photo".localized, style: .default) { [weak self] _ in
            self?.openCamera()
        })
        sheet.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = pickingDocument ? documentButton : (cameraButton ?? photoView)
            popover.sourceRect = (pickingDocument ? documentButton?.bounds : cameraButton?.bounds) ?? photoView.bounds
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
                self?.applyPicked(image)
            }
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage {
            applyPicked(image)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    private func applyPicked(_ image: UIImage) {
        let normalized = normalizedImage(image)
        if pickingDocument {
            pendingDocument = normalized
            errorLabel?.text = nil
            refreshDocumentButtonTitle()
        } else {
            pendingPhoto = normalized
            photoView.image = normalized
        }
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

    private func showSaveError(_ message: String) {
        errorLabel?.text = message
        if errorLabel == nil {
            CommonMethods.showAlert(message: message, from: self)
        }
    }

    @IBAction func saveTapped(_ sender: Any) {
        errorLabel?.text = nil
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let phone = phoneField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else {
            showSaveError("Please enter your name.".localized)
            return
        }
        guard !email.isEmpty else {
            showSaveError("Please enter your email address.".localized)
            return
        }
        guard !phone.isEmpty else {
            showSaveError("Please enter your phone number.".localized)
            return
        }

        var param: [String: Any] = [
            "name": name,
            "email": email,
            "phone": phone
        ]
        if let pendingPhoto {
            param["profileImage"] = pendingPhoto
        }

        if isAgent {
            let license = licenseField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                ?? profileModel?.resolvedUser?.licenseNumber?.trimmingCharacters(in: .whitespacesAndNewlines)
                ?? ""
            if licenseField != nil {
                guard !license.isEmpty else {
                    showSaveError("Please enter your license number.".localized)
                    return
                }
            }
            if !license.isEmpty {
                param["licenseNumber"] = license
            }

            if let documentImage = pendingDocument {
                param["document"] = documentImage
            }
            else if documentButton != nil,
                      (existingDocumentURL ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showSaveError("Please upload your license document.".localized)
                return
            }
        }

        saveButton.isEnabled = false
        Task {
            do {
                let response = try await AuthViewModel.updateProfileAPI(param: param)
                await MainActor.run {
                    self.saveButton.isEnabled = true
                    if response.success == false {
                        let message = response.message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        self.showSaveError(
                            message.isEmpty
                                ? "Unable to update profile. Please try again.".localized
                                : message
                        )
                        return
                    }
                    self.applyLocalAccount(name: name, email: email, phone: phone, user: response.resolvedUser)
                    let message = response.message?.trimmingCharacters(in: .whitespacesAndNewlines)
                    CommonMethods.showAlert(
                        message: (message?.isEmpty == false) ? message! : "Profile updated.".localized,
                        from: self
                    ) {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    self.saveButton.isEnabled = true
                    let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.showSaveError(
                        message.isEmpty
                            ? "Unable to update profile. Please try again.".localized
                            : message
                    )
                }
            }
        }
    }

    private func applyLocalAccount(name: String, email: String, phone: String, user: User? = nil) {
        if isAgent {
            if let user {
                AgentAccount.shared.apply(user: user)
            }
            if agencyId.isEmpty == false {
                AgentAccount.shared.agencyId = agencyId
            }
            if let agencyName = agencyField?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
               agencyName.isEmpty == false {
                AgentAccount.shared.agency = agencyName
            }
            if let pendingPhoto {
                AgentAccount.shared.saveProfileImage(pendingPhoto)
            }
        } else {
            TenantAccount.shared.name = name
            TenantAccount.shared.email = email
            TenantAccount.shared.phone = phone
        }
    }

    private func loadProfile() {
        Task {
            do {
                let res = try await AuthViewModel.profileAPI()
                await MainActor.run { self.fill(res.resolvedUser) }
            } catch {
                await MainActor.run { self.fill(nil) }
            }
        }
    }

    private func fill(_ user: User?) {
        profileModel = user.map { GetProfileResponseModel(success: true, message: nil, data: $0, user: $0) }
        let placeholder = UIImage(named: "profile")
        if isAgent {
            if let user {
                AgentAccount.shared.apply(user: user)
            }
            nameField.text = user?.name ?? ""
            emailField.text = user?.email ?? ""
            phoneField.text = user?.phone ?? ""
            agencyId = user?.agencyId?.trimmingCharacters(in: .whitespacesAndNewlines)
                ?? AgentAccount.shared.agencyId
            let agencyName = user?.agencyName?.trimmingCharacters(in: .whitespacesAndNewlines)
                ?? AgentAccount.shared.agency
            agencyField?.text = agencyName
            licenseField?.text = user?.licenseNumber
                ?? AgentAccount.shared.licenseNumber
            existingDocumentURL = user?.document
            refreshDocumentButtonTitle()
            applyProfilePhoto(user?.profileImage, placeholder: placeholder)
        }
        else {
            nameField.text = user?.name ?? ""
            emailField.text = user?.email ?? ""
            phoneField.text = user?.phone ?? ""
            photoView.image = placeholder
            applyProfilePhoto(user?.profileImage, placeholder: placeholder)
        }
    }

    private func applyProfilePhoto(_ path: String?, placeholder: UIImage?) {
        photoView.sd_cancelCurrentImageLoad()
        let trimmed = path?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard trimmed.isEmpty == false, let url = Constant.mediaImageURL(trimmed) else {
            photoView.image = placeholder
            return
        }
        photoView.sd_setImage(with: url, placeholderImage: placeholder, options: [.retryFailed, .refreshCached])
    }
}

private final class DocumentFullScreenVC: UIViewController, UIScrollViewDelegate {
    var image: UIImage?
    var imagePath: String?

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        imageView.image = image
        if image == nil {
            let trimmed = imagePath?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if trimmed.isEmpty == false {
                imageView.sd_setImage(with: Constant.mediaImageURL(trimmed), placeholderImage: nil, options: [.retryFailed, .refreshCached])
            }
        }
        scrollView.addSubview(imageView)

        let close = UIButton(type: .system)
        close.translatesAutoresizingMaskIntoConstraints = false
        close.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        close.tintColor = .white
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(close)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            close.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            close.widthAnchor.constraint(equalToConstant: 36),
            close.heightAnchor.constraint(equalToConstant: 36)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(closeTapped))
        tap.numberOfTapsRequired = 1
        scrollView.addGestureRecognizer(tap)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
