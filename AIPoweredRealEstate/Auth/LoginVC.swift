//
//  LoginVC.swift
//  AIPoweredRealEstate
//
//  Created by Shireen on 18/08/26.
//

import UIKit

class LoginVC: UIViewController {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var logoContainerView: CustomView!
    @IBOutlet weak var formCardView: CustomView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var emailTextField: CustomTextField!
    @IBOutlet weak var passwordTextField: CustomTextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var loginButton: CustomButton!
    @IBOutlet weak var showPasswordButton: UIButton!
    @IBOutlet weak var signupPromptLabel: UILabel!
    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var welcomeButton: UIButton!
    @IBOutlet weak var verifyEmailButton: UIButton!

    var selectedRole: String = "buyer"
    
    var from:String?

    private let brandingSize: CGFloat = 112
    private var brandingImages: [String] = []
    private var brandingIndex = 0
    private var brandingTimer: Timer?

    private lazy var brandingCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: brandingSize, height: brandingSize)
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.backgroundColor = .clear
        collection.isPagingEnabled = true
        collection.showsHorizontalScrollIndicator = false
        collection.clipsToBounds = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(LoginAgencyBrandCell.self, forCellWithReuseIdentifier: LoginAgencyBrandCell.reuseId)
        collection.isHidden = true
        collection.isUserInteractionEnabled = false
        return collection
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        applyLoginStyle()
        setupAgencyBranding()
        loadAgencyBranding()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        startBrandingAutoScroll()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopBrandingAutoScroll()
    }

    deinit {
        stopBrandingAutoScroll()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CommonMethods.updateGradientFrame(for: headerView)
        CommonMethods.updateGradientFrame(for: loginButton)
    }

    private func applyLoginStyle() {
        view.backgroundColor = .screenBackgroundColor
        CommonMethods.applyHeaderGradient(on: headerView, cornerRadius: 32)

        let roleTitle = (selectedRole == "buyer" ? "Tenant" : "Agent").localized
        titleLabel.text = "Login".localized
        subtitleLabel.text = "Login to continue as %@".localized(roleTitle)
        errorLabel.text = nil

        CommonMethods.styleLogoContainer(logoContainerView)

        formCardView.backgroundColor = .white
        formCardView.layer.cornerRadius = 20
        formCardView.layer.shadowColor = UIColor.darkThemeColor.cgColor
        formCardView.layer.shadowOpacity = 0.10
        formCardView.layer.shadowRadius = 16
        formCardView.layer.shadowOffset = CGSize(width: 0, height: 8)

        style(field: emailTextField)
        style(field: passwordTextField)
        emailTextField.keyboardType = .emailAddress
        emailTextField.textContentType = .username
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.spellCheckingType = .no
        emailTextField.smartQuotesType = .no
        emailTextField.smartDashesType = .no
        passwordTextField.isSecureTextEntry = true
        passwordTextField.textContentType = .password
        passwordTextField.autocorrectionType = .no
        passwordTextField.spellCheckingType = .no
        CommonMethods.stylePrimaryButton(loginButton)
        signupPromptLabel.textColor = .darkThemeColor
        createAccountButton.setTitleColor(.darkThemeColor, for: .normal)
        createAccountButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        verifyEmailButton.setTitle("Verify Email".localized, for: .normal)
        verifyEmailButton.setTitleColor(.darkThemeColor, for: .normal)
        verifyEmailButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .regular)
        verifyEmailButton.isHidden = selectedRole != "agent"

        let title = "Go to Welcome".localized
        let attributed = NSAttributedString(
            string: title,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.accentThemeColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )
        welcomeButton.setAttributedTitle(attributed, for: .normal)
        welcomeButton.backgroundColor = .clear
        welcomeButton.tintColor = .accentThemeColor
        welcomeButton.configuration = nil
        welcomeButton.contentHorizontalAlignment = .center
    }

    private func setupAgencyBranding() {
        view.addSubview(brandingCollection)
        NSLayoutConstraint.activate([
            brandingCollection.topAnchor.constraint(equalTo: welcomeButton.bottomAnchor, constant: 18),
            brandingCollection.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            brandingCollection.widthAnchor.constraint(equalToConstant: brandingSize),
            brandingCollection.heightAnchor.constraint(equalToConstant: brandingSize),
            brandingCollection.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }

    private func loadAgencyBranding() {
        Task {
            let items = (try? await AuthViewModel.agenciesAPI()) ?? []
            let paths = items.compactMap { item -> String? in
                guard let path = item.imagePath, Constant.mediaImageURL(path) != nil else { return nil }
                return path
            }
            await MainActor.run {
                self.brandingImages = paths
                self.brandingIndex = 0
                self.brandingCollection.reloadData()
                self.brandingCollection.isHidden = paths.isEmpty
                if paths.isEmpty == false {
                    self.brandingCollection.scrollToItem(
                        at: IndexPath(item: 0, section: 0),
                        at: .centeredHorizontally,
                        animated: false
                    )
                }
                self.startBrandingAutoScroll()
            }
        }
    }

    private func startBrandingAutoScroll() {
        stopBrandingAutoScroll()
        guard brandingImages.count > 1, brandingCollection.isHidden == false else { return }
        brandingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.scrollBrandingToNext()
        }
    }

    private func stopBrandingAutoScroll() {
        brandingTimer?.invalidate()
        brandingTimer = nil
    }

    private func scrollBrandingToNext() {
        guard brandingImages.count > 1 else { return }
        brandingIndex = (brandingIndex + 1) % brandingImages.count
        brandingCollection.scrollToItem(
            at: IndexPath(item: brandingIndex, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
    }

    private func style(field: CustomTextField) {
        field.backgroundColor = .screenBackgroundColor
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.cardBorderColor.cgColor
        field.font = .systemFont(ofSize: 16, weight: .regular)
    }

    @IBAction func welcomeTapped(_ sender: UIButton) {
        goToWelcomeTapped()
    }

    @IBAction func backTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func togglePasswordVisibilityTapped(_ sender: UIButton) {
        passwordTextField.isSecureTextEntry.toggle()
        let imageName = passwordTextField.isSecureTextEntry ? "eye" : "eye.slash"
        sender.setImage(UIImage(systemName: imageName), for: .normal)
    }

    @IBAction func loginTapped(_ sender: UIButton) {
        errorLabel.text = nil
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordTextField.text ?? ""

        guard !email.isEmpty, !password.isEmpty else {
            errorLabel.text = "Please enter email and password.".localized
            return
        }

        setLoginLoading(true)
        let param: [String: Any] = [
            "email": email,
            "password": password,
            "language": LanguageManager.shared.currentLanguage,
        ]
        print("LOGIN PARAM: \(param)")

        Task {
            do {
                
                let response = try await AuthViewModel.loginAPI(param: param)
                
                await MainActor.run {
                    self.setLoginLoading(false)
                    self.handleLoginSuccess(response)
                }
              
            } catch {
                print("LOGIN ERROR: \(error)")
                await MainActor.run {
                    self.setLoginLoading(false)
                    self.handleLoginFailure(error)
                }
            }
        }
    }

    private func setLoginLoading(_ loading: Bool) {
        loginButton.isEnabled = !loading
        loginButton.alpha = loading ? 0.6 : 1
        loginButton.setTitle(loading ? "Logging in...".localized : "Login".localized, for: .normal)
        view.isUserInteractionEnabled = !loading
    }

    private func handleLoginSuccess(_ response: LoginResponse) {
        if response.success == false {
            handleAgentOrGenericFailure(response.message)
            return
        }

        if shouldBlockPendingAgent(response) {
            if let role = response.data?.user?.role, selectedRole != role {
                CommonMethods.showAlert(message: "Incorrect Role is Selected", from: self) {
                    self.goToWelcomeTapped()
                }
                return
            }
            let message = response.message?.trimmingCharacters(in: .whitespacesAndNewlines)
            CommonMethods.showAlert(
                message: (message?.isEmpty == false ? message! : "Please verify your email first".localized),
                from: self
            )
            return
        }

        completeApprovedLogin(response)
    }

    private func handleLoginFailure(_ error: Error) {
        handleAgentOrGenericFailure((error as? APIError)?.errorDescription ?? error.localizedDescription)
    }

    private func handleAgentOrGenericFailure(_ rawMessage: String?) {
        let message = (rawMessage ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if selectedRole == "agent", shouldOpenVerifyEmail(for: message) {
            CommonMethods.showAlert(
                message: message.isEmpty ? "Please verify your email first".localized : message,
                from: self
            )
            return
        }
        errorLabel.text = message.isEmpty
            ? "Login failed. Please check your email and password.".localized
            : message
    }

    private func shouldOpenVerifyEmail(for message: String) -> Bool {
        let text = message.lowercased()
        return text.contains("pending")
            || (text.contains("verify") && text.contains("email"))
    }

    private func shouldBlockPendingAgent(_ response: LoginResponse) -> Bool {
        guard selectedRole == "agent" else { return false }
        let status = (response.data?.user?.status ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return status == "pending"
    }

    private func openVerifyEmail(using response: LoginResponse?) {
        let verifyVC = VerifyEmailVC()
        verifyVC.selectedRole = selectedRole
        verifyVC.prefilledEmail = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        verifyVC.pendingLoginResponse = response
        verifyVC.onApproved = { [weak self] approved in
            guard let self else { return }
            if self.presentedViewController != nil {
                self.dismiss(animated: false) {
                    self.completeApprovedLogin(approved)
                }
            } else {
                self.navigationController?.popViewController(animated: false)
                self.completeApprovedLogin(approved)
            }
        }

        if let navigationController {
            navigationController.pushViewController(verifyVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: verifyVC)
            nav.setNavigationBarHidden(true, animated: false)
            present(nav, animated: true)
        }
    }

    private func completeApprovedLogin(_ response: LoginResponse) {
        let token = KeyChainManager.normalizedAuthToken(response.resolvedToken)

        guard token.isEmpty == false else {
            errorLabel.text = response.message ?? "Login failed. Please check your email and password.".localized
            return
        }

        print("LOGIN TOKEN SAVED: jwtParts=\(token.split(separator: ".").count) chars=\(token.count)")
        if let user = response.data?.user {
            AgentAccount.shared.apply(user: user)
        }

        if let role = response.data?.user?.role,
           let homeRole = normalizedRole(role.lowercased()) {

            if selectedRole == role {
                KeyChainManager.shared.saveValue(value: token, key: "token")
                KeyChainManager.shared.saveValue(value: homeRole, key: "UserRole")
                CommonMethods.showAlert(message: response.message ?? "", from: self) {
                    self.openHome(for: homeRole)
                }
            } else {
                CommonMethods.showAlert(message: "Incorrect Role is Selected", from: self) {
                    self.goToWelcomeTapped()
                }
            }
         } else {
            CommonMethods.showAlert(message: "Something went wrong", from: self) {
                self.goToLoginRoot(role: self.selectedRole)
            }
        }
    }

    private func normalizedRole(_ raw: String) -> String? {
        switch raw {
        case "agent":
            return "agent"
        case "buyer":
            return "buyer"
        default:
            return nil
        }
    }

    private func openHome(for role: String) {
        switch role {
        case "buyer":
            CommonMethods.setRootViewController(TenantStoryboard.tabBar())
        case "agent":
            CommonMethods.setRootViewController(AgentStoryboard.tabBar())
        default:
            errorLabel.text = "Unable to determine user role.".localized
        }
    }

    @IBAction func verifyEmailTapped(_ sender: UIButton) {
        openVerifyEmail(using: nil)
    }

    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        guard let forgotVC = storyboard?.instantiateViewController(withIdentifier: "ForgotPasswordVC") as? ForgotPasswordVC else {
            return
        }
        forgotVC.selectedRole = selectedRole
        navigationController?.pushViewController(forgotVC, animated: true)
    }

    @IBAction func createAccountTapped(_ sender: UIButton) {
        guard let registerVC = storyboard?.instantiateViewController(withIdentifier: "RegistartionVC") as? RegistartionVC else {
            return
        }
        registerVC.selectedRole = selectedRole
        navigationController?.pushViewController(registerVC, animated: true)
    }
}

extension LoginVC: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        brandingImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: LoginAgencyBrandCell.reuseId,
            for: indexPath
        ) as! LoginAgencyBrandCell
        cell.configure(imagePath: brandingImages[indexPath.item])
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: brandingSize, height: brandingSize)
    }
}

private final class LoginAgencyBrandCell: UICollectionViewCell {
    static let reuseId = "LoginAgencyBrandCell"

    private let cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.darkThemeColor.cgColor
        view.layer.shadowOpacity = 0.10
        view.layer.shadowRadius = 10
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .white
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = false
        clipsToBounds = false
        contentView.addSubview(cardView)
        cardView.addSubview(imageView)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            imageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            imageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            imageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            imageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(imagePath: String) {
        imageView.setMediaProfileImage(imagePath, placeholder: UIImage(named: "appLogo"))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .white
    }
}
