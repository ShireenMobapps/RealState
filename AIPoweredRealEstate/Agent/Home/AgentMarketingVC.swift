//
//  AgentMarketingVC.swift
//  AIPoweredRealEstate
//

import UIKit
import MessageUI

final class AgentMarketingVC: UIViewController {

    var property: PropertyItem?

    @IBOutlet weak var pickerButton: UIButton!
    @IBOutlet weak var channelControl: UISegmentedControl?
    @IBOutlet weak var generateButton: CustomButton!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var resultCardView: CustomView!

    private var selectedOptionTag = 0
    private var optionRows: [UIView] = []
    private var optionButtons: [UIButton] = []
    private var hasGenerated = false
    private var didBuildScreen = false

    // Matches POST /properties/:id/marketing-content `contentType`
    private let contentOptions: [(title: String, contentType: String, tag: Int)] = [
        ("Generate Instagram content", "instagram", 0),
        ("Generate WhatsApp message", "whatsapp", 1),
        ("Generate email content", "email", 2)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Generate content".localized
        view.backgroundColor = .screenBackgroundColor
        navigationController?.navigationBar.tintColor = .darkThemeColor
        CommonMethods.stylePrimaryButton(generateButton)
        CommonMethods.styleFormCard(resultCardView)
        resultLabel.numberOfLines = 0
        resultLabel.lineBreakMode = .byWordWrapping
        copyButton.layer.cornerRadius = 12
        copyButton.layer.borderWidth = 1
        copyButton.layer.borderColor = UIColor.darkThemeColor.cgColor
        shareButton.layer.cornerRadius = 12
        shareButton.layer.borderWidth = 1
        shareButton.layer.borderColor = UIColor.darkThemeColor.cgColor
        rebuildScreen()
        refreshOptionStyles()
        refreshGenerateState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CommonMethods.updateGradientFrame(for: generateButton)
    }

    private func rebuildScreen() {
        guard !didBuildScreen else { return }
        didBuildScreen = true

        pickerButton.isHidden = true
        pickerButton.isUserInteractionEnabled = false
        channelControl?.isHidden = true
        channelControl?.isUserInteractionEnabled = false

        let shareRow = copyButton.superview
        let oldStack = generateButton.superview
        generateButton.removeFromSuperview()
        shareRow?.removeFromSuperview()
        resultCardView.removeFromSuperview()
        oldStack?.removeFromSuperview()

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        scroll.keyboardDismissMode = .onDrag
        scroll.showsVerticalScrollIndicator = true
        view.addSubview(scroll)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        let hint = UILabel()
        hint.numberOfLines = 0
        hint.font = .systemFont(ofSize: 13)
        hint.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)
        hint.text = "Choose a content type, then tap Generate. Then copy or share the text.".localized
        stack.addArrangedSubview(hint)

        let optionsStack = UIStackView()
        optionsStack.axis = .vertical
        optionsStack.spacing = 10
        optionsStack.alignment = .fill
        optionsStack.distribution = .fillEqually
        optionsStack.translatesAutoresizingMaskIntoConstraints = false
        contentOptions.forEach { row in
            let item = makeOptionRow(title: row.title, tag: row.tag)
            optionsStack.addArrangedSubview(item)
        }
        let optionsHeight = CGFloat(contentOptions.count) * 48 + CGFloat(max(contentOptions.count - 1, 0)) * 10
        optionsStack.heightAnchor.constraint(equalToConstant: optionsHeight).isActive = true
        stack.addArrangedSubview(optionsStack)

        generateButton.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(generateButton)
        if generateButton.constraints.contains(where: { $0.firstAttribute == .height }) == false {
            generateButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }

        if let shareRow {
            shareRow.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview(shareRow)
        }
        resultCardView.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(resultCardView)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -28)
        ])
    }

    private func makeOptionRow(title: String, tag: Int) -> UIView {
        let wrap = UIView()
        wrap.translatesAutoresizingMaskIntoConstraints = false
        wrap.backgroundColor = .white
        wrap.layer.cornerRadius = 12
        wrap.layer.borderWidth = 1.5
        wrap.layer.borderColor = UIColor.cardBorderColor.cgColor
        wrap.clipsToBounds = true
        wrap.tag = tag

        let button = UIButton(type: .system)
        button.tag = tag
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.8
        button.titleLabel?.numberOfLines = 1
        button.setTitle(title.localized, for: .normal)
        button.setTitleColor(UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1), for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        button.addTarget(self, action: #selector(contentActionTapped(_:)), for: .touchUpInside)

        wrap.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: wrap.topAnchor),
            button.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: wrap.bottomAnchor)
        ])
        optionRows.append(wrap)
        optionButtons.append(button)
        return wrap
    }

    private func refreshOptionStyles() {
        zip(optionRows, optionButtons).forEach { wrap, button in
            let on = button.tag == selectedOptionTag
            wrap.backgroundColor = on ? UIColor.accentThemeColor.withAlphaComponent(0.12) : .white
            wrap.layer.borderColor = (on ? UIColor.accentThemeColor : UIColor.cardBorderColor).cgColor
            wrap.layer.borderWidth = on ? 1.5 : 1
            button.setTitleColor(
                on ? .darkThemeColor : UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1),
                for: .normal
            )
        }
    }

    private func refreshGenerateState() {
        generateButton.isEnabled = true
        generateButton.alpha = 1
        generateButton.setTitle((hasGenerated ? "Regenerate" : "Generate").localized, for: .normal)
        copyButton.isEnabled = hasGenerated
        shareButton.isEnabled = hasGenerated
        copyButton.alpha = hasGenerated ? 1 : 0.4
        shareButton.alpha = hasGenerated ? 1 : 0.4
    }

    @IBAction func pickProperty(_ sender: Any) {}

    @objc private func contentActionTapped(_ sender: UIButton) {
        selectedOptionTag = sender.tag
        refreshOptionStyles()
    }

    private func selectedContentType() -> String {
        contentOptions.first(where: { $0.tag == selectedOptionTag })?.contentType ?? "instagram"
    }

    @IBAction func generate() {
        generateSelectedContent()
    }

    private func generateSelectedContent() {
        guard let propertyId = property?.id.trimmingCharacters(in: .whitespacesAndNewlines),
              propertyId.isEmpty == false else {
            hasGenerated = false
            resultLabel.text = "Open this from a property to generate copy.".localized
            refreshGenerateState()
            return
        }

        generateButton.isEnabled = false
        generateButton.alpha = 0.6
        Task {
            do {
                let response = try await AgentViewModels.marketingContentAPI(
                    propertyId: propertyId,
                    contentType: selectedContentType()
                )
                await MainActor.run {
                    let report = response.resolvedReport
                    if report.isEmpty {
                        self.hasGenerated = false
                        self.resultLabel.text = response.message ?? "Open this from a property to generate copy.".localized
                    } else {
                        self.resultLabel.text = report
                        self.hasGenerated = true
                    }
                    self.refreshGenerateState()
                    self.refreshOptionStyles()
                }
            } catch {
                await MainActor.run {
                    self.hasGenerated = false
                    self.refreshGenerateState()
                    self.handleMarketingAPIError(error)
                }
            }
        }
    }

    private func handleMarketingAPIError(_ error: Error) {
        let message = ((error as? APIError)?.errorDescription ?? error.localizedDescription)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let text = message.isEmpty ? "Unable to generate content. Please try again.".localized : message
        resultLabel.text = text
        let isTokenFailed = message.caseInsensitiveCompare("Not authorized, token failed") == .orderedSame
        CommonMethods.showAlert(message: text, from: self) { [weak self] in
            guard let self, isTokenFailed else { return }
            KeyChainManager.shared.deleteValue(key: "token")
            KeyChainManager.shared.deleteValue(key: "UserRole")
            AgentAccount.shared.clear()
            self.goToWelcomeTapped()
        }
    }

    @IBAction func copyTapped(_ sender: Any) {
        let text = resultLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard hasGenerated, text.isEmpty == false else { return }
        UIPasteboard.general.string = text
        CommonMethods.showAlert(message: "report copied successfully".localized, from: self)
    }

    @IBAction func shareTapped(_ sender: Any) {
        let text = resultLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard hasGenerated, text.isEmpty == false else { return }
        switch selectedContentType() {
        case "email":
            shareEmail(text)
        case "whatsapp":
            shareWhatsApp(text)
        case "instagram":
            shareInstagram(text)
        default:
            presentShareSheet(text)
        }
    }

    private func shareEmail(_ text: String) {
        let parts = emailShareParts(from: text)
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setSubject(parts.subject)
            mail.setMessageBody(parts.body, isHTML: false)
            present(mail, animated: true)
            return
        }
        var components = URLComponents()
        components.scheme = "mailto"
        components.queryItems = [
            URLQueryItem(name: "subject", value: parts.subject),
            URLQueryItem(name: "body", value: parts.body)
        ]
        if let url = components.url {
            UIApplication.shared.open(url) { [weak self] success in
                if success == false {
                    self?.presentShareSheet(text)
                }
            }
            return
        }
        presentShareSheet(text)
    }

    private func shareWhatsApp(_ text: String) {
        var app = URLComponents(string: "whatsapp://send")
        app?.queryItems = [URLQueryItem(name: "text", value: text)]
        if let url = app?.url, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return
        }
        var web = URLComponents(string: "https://wa.me/")
        web?.queryItems = [URLQueryItem(name: "text", value: text)]
        if let url = web?.url {
            UIApplication.shared.open(url) { [weak self] success in
                if success == false {
                    self?.presentShareSheet(text)
                }
            }
            return
        }
        presentShareSheet(text)
    }

    private func shareInstagram(_ text: String) {
        UIPasteboard.general.string = text
        guard let instagramApp = URL(string: "instagram://app"),
              UIApplication.shared.canOpenURL(instagramApp) else {
            CommonMethods.showAlert(message: "Instagram is not installed.".localized, from: self)
            return
        }
        var share = URLComponents(string: "instagram://sharesheet")
        share?.queryItems = [URLQueryItem(name: "text", value: text)]
        if let shareURL = share?.url {
            UIApplication.shared.open(shareURL) { success in
                if success == false {
                    UIApplication.shared.open(instagramApp)
                }
            }
            return
        }
        UIApplication.shared.open(instagramApp)
    }

    private func presentShareSheet(_ text: String) {
        present(UIActivityViewController(activityItems: [text], applicationActivities: nil), animated: true)
    }

    private func emailShareParts(from text: String) -> (subject: String, body: String) {
        var lines = text.components(separatedBy: .newlines)
        while let first = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines),
              first.isEmpty || first.compare("Email:", options: .caseInsensitive) == .orderedSame || first.compare("Email", options: .caseInsensitive) == .orderedSame {
            lines.removeFirst()
        }
        let fallbackSubject: String = {
            let title = property?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let location = property?.location.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if title.isEmpty == false, location.isEmpty == false { return "\(title) in \(location)" }
            if title.isEmpty == false { return title }
            return "Property".localized
        }()
        var subject = fallbackSubject
        if let index = lines.firstIndex(where: {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().hasPrefix("subject:")
        }) {
            let line = lines.remove(at: index).trimmingCharacters(in: .whitespacesAndNewlines)
            let value = String(line.dropFirst("subject:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            if value.isEmpty == false { subject = value }
            while lines.first?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
                lines.removeFirst()
            }
        }
        let body = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return (subject, body.isEmpty ? text : body)
    }
}

extension AgentMarketingVC: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
