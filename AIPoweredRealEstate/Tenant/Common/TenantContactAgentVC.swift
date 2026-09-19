//
//  TenantContactAgentVC.swift
//  AIPoweredRealEstate
//

import UIKit

class TenantContactAgentVC: UIViewController {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var formCardView: CustomView!
    @IBOutlet weak var agentLabel: UILabel!
    @IBOutlet weak var propertyLabel: UILabel!
    @IBOutlet weak var nameTextField: CustomTextField!
    @IBOutlet weak var emailTextField: CustomTextField!
    @IBOutlet weak var phoneTextField: CustomTextField!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendButton: CustomButton!
    @IBOutlet weak var errorLabel: UILabel!

    var property: PropertyItem?
    var selectedRealtor: PlatformRealtor?
    private weak var navTitleLabel: UILabel?
    private let messagePlaceholder = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        resolveNavTitleLabel()
        applyStyle()
        populate()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CommonMethods.updateGradientFrame(for: sendButton)
    }

    private func resolveNavTitleLabel() {
        navTitleLabel = headerView?.subviews.compactMap { $0 as? UILabel }.first
    }

    private func applyStyle() {
        view.backgroundColor = .screenBackgroundColor
        CommonMethods.styleFormCard(formCardView)
        CommonMethods.styleTextField(nameTextField)
        CommonMethods.styleTextField(emailTextField)
        CommonMethods.styleTextField(phoneTextField)
        nameTextField.delegate = self
        emailTextField.delegate = self
        phoneTextField.delegate = self
        nameTextField.returnKeyType = .next
        emailTextField.returnKeyType = .next
        phoneTextField.returnKeyType = .next
        nameTextField.attachKeyboardDoneButton()
        emailTextField.attachKeyboardDoneButton()
        phoneTextField.attachKeyboardDoneButton()
        styleMessageTextView()
        CommonMethods.stylePrimaryButton(sendButton)
        errorLabel.text = nil
        sendButton.setTitle("Send".localized, for: .normal)
    }

    private func styleMessageTextView() {
        messageTextView.backgroundColor = .screenBackgroundColor
        messageTextView.layer.cornerRadius = 12
        messageTextView.clipsToBounds = true
        messageTextView.layer.borderWidth = 1
        messageTextView.layer.borderColor = UIColor.cardBorderColor.cgColor
        messageTextView.font = .systemFont(ofSize: 16, weight: .regular)
        messageTextView.textColor = .black
        messageTextView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.delegate = self
        messageTextView.attachKeyboardDoneButton()
        messagePlaceholder.text = "Describe your requirements".localized
        messagePlaceholder.font = .systemFont(ofSize: 16, weight: .regular)
        messagePlaceholder.textColor = UIColor(red: 0.66, green: 0.68, blue: 0.70, alpha: 1)
        messagePlaceholder.numberOfLines = 0
        messagePlaceholder.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.addSubview(messagePlaceholder)
        NSLayoutConstraint.activate([
            messagePlaceholder.topAnchor.constraint(equalTo: messageTextView.topAnchor, constant: 12),
            messagePlaceholder.leadingAnchor.constraint(equalTo: messageTextView.leadingAnchor, constant: 14),
            messagePlaceholder.trailingAnchor.constraint(equalTo: messageTextView.trailingAnchor, constant: -14)
        ])
        refreshMessagePlaceholder()
    }

    private func refreshMessagePlaceholder() {
        messagePlaceholder.isHidden = !(messageTextView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func populate() {
        nameTextField.text = TenantAccount.shared.name
        emailTextField.text = TenantAccount.shared.email
        phoneTextField.text = TenantAccount.shared.phone
        messageTextView.text = nil
        refreshMessagePlaceholder()
        propertyLabel.numberOfLines = 0

        if let selectedRealtor {
            let title = "Your agent %@".localized(selectedRealtor.name)
            navTitleLabel?.text = title
            agentLabel.text = selectedRealtor.name
            if let property {
                propertyLabel.text = "\(selectedRealtor.agency) · \(property.title)"
            } else {
                propertyLabel.text = "Send your requirements to %@.".localized(selectedRealtor.name)
            }
        } else {
            navTitleLabel?.text = "Contact".localized
            agentLabel.text = "SpeddyProp"
            if let property {
                propertyLabel.text = "\("Contact Agent".localized) · \(property.title)"
            } else {
                propertyLabel.text = "Send your requirements to SpeddyProp.".localized
            }
        }
    }

    @IBAction func backTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func sendTapped(_ sender: UIButton) {
        errorLabel.text = nil
        let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty, !email.isEmpty else {
            errorLabel.text = "Please enter your name and email.".localized
            return
        }

        let phone = phoneTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        TenantAccount.shared.name = name
        TenantAccount.shared.email = email
        TenantAccount.shared.phone = phone

        let description = messageTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !description.isEmpty else {
            errorLabel.text = "Please enter your requirements.".localized
            return
        }

        guard let agentId = selectedRealtor?.id, !agentId.isEmpty else {
            errorLabel.text = "Please select an agent.".localized
            return
        }

        sendButton.isEnabled = false
        Task {
            do {
                let response = try await TenantViewModels.sendLeadAPI(
                    agentId: agentId,
                    name: name,
                    email: email,
                    phone: phone,
                    description: description
                )
                await MainActor.run {
                    self.sendButton.isEnabled = true
                    let message = response.message?.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.showSuccessAndGoHome(
                        message: (message?.isEmpty == false) ? message! : "Lead sent successfully.".localized
                    )
                }
            } catch {
                await MainActor.run {
                    self.sendButton.isEnabled = true
                    self.errorLabel.text = "Unable to send lead. Please try again.".localized
                }
            }
        }
    }

    private func showSuccessAndGoHome(message: String) {
        let alert = UIAlertController(
            title: "Success".localized,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default) { [weak self] _ in
            self?.goToDashboard()
        })
        present(alert, animated: true)
    }

    private func goToDashboard() {
        if let tab = tabBarController {
            tab.selectedIndex = 0
        }
        navigationController?.popToRootViewController(animated: true)
    }
}

extension TenantContactAgentVC: UITextViewDelegate, UITextFieldDelegate {
    func textViewDidChange(_ textView: UITextView) {
        refreshMessagePlaceholder()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            emailTextField.becomeFirstResponder()
        } else if textField == emailTextField {
            phoneTextField.becomeFirstResponder()
        } else if textField == phoneTextField {
            messageTextView.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
