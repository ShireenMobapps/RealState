//
//  CommonMethods.swift
//  AIPoweredRealEstate
//
//  Created by Shireen on 18/08/26.
//

import Foundation
import UIKit

extension UIColor {

    static var darkThemeColor: UIColor {
        UIColor(red: 14/255, green: 36/255, blue: 61/255, alpha: 1)
    }

    static var mediumThemeColor: UIColor {
        UIColor(red: 26/255, green: 58/255, blue: 92/255, alpha: 1)
    }

    static var lightThemeColor: UIColor {
        UIColor(red: 36/255, green: 82/255, blue: 122/255, alpha: 1)
    }

    static var accentThemeColor: UIColor {
        UIColor(red: 253/255, green: 185/255, blue: 19/255, alpha: 1)
    }

    static var screenBackgroundColor: UIColor {
        UIColor(red: 250/255, green: 249/255, blue: 246/255, alpha: 1)
    }

    static var cardBorderColor: UIColor {
        UIColor(red: 220/255, green: 226/255, blue: 232/255, alpha: 1)
    }
}

final class CommonMethods {

    private static let themeGradientLayerName = "themeGradient"
    private static let yellowGradientLayerName = "YellowGradientLayer"

    class func gradientOverView(view: UIView) {
        view.layer.sublayers?
            .filter { $0.name == themeGradientLayerName }
            .forEach { $0.removeFromSuperlayer() }

        let gradientLayer = CAGradientLayer()
        gradientLayer.name = themeGradientLayerName
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor.darkThemeColor.cgColor,
            UIColor.mediumThemeColor.cgColor,
            UIColor.lightThemeColor.cgColor
        ]
        gradientLayer.locations = [0.0, 0.55, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.05, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    class func applyHeaderGradient(on view: UIView, cornerRadius: CGFloat = 32) {
        gradientOverView(view: view)
        view.layer.cornerRadius = cornerRadius
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        view.clipsToBounds = true
    }

    class func applyButtonGradient(on button: UIButton, cornerRadius: CGFloat = 14) {
        button.backgroundColor = .clear
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = cornerRadius
        gradientOverView(view: button)
        updateGradientFrame(for: button)
        if let titleLabel = button.titleLabel {
            button.bringSubviewToFront(titleLabel)
        }
        if let imageView = button.imageView {
            button.bringSubviewToFront(imageView)
        }
    }

    class func applyYellowGradient(on view: UIView) {
        view.layer.sublayers?
            .filter { $0.name == yellowGradientLayerName || $0.name == themeGradientLayerName }
            .forEach { $0.removeFromSuperlayer() }

        let gradientLayer = CAGradientLayer()
        gradientLayer.name = yellowGradientLayerName
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 1.0, green: 0.72, blue: 0.0, alpha: 1.0).cgColor,
            UIColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.cornerRadius = view.layer.cornerRadius
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    class func styleYellowGradientButton(_ button: UIButton, cornerRadius: CGFloat = 14) {
        button.backgroundColor = .clear
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = cornerRadius
        button.clipsToBounds = true
        applyYellowGradient(on: button)
        updateGradientFrame(for: button)
        if let titleLabel = button.titleLabel {
            button.bringSubviewToFront(titleLabel)
        }
        if let imageView = button.imageView {
            button.bringSubviewToFront(imageView)
        }
    }

    class func updateGradientFrame(for view: UIView) {
        guard let gradientLayer = view.layer.sublayers?
            .compactMap({ $0 as? CAGradientLayer })
            .first(where: {
                $0.name == themeGradientLayerName || $0.name == yellowGradientLayerName
            }) else {
            return
        }
        gradientLayer.frame = view.bounds
        gradientLayer.cornerRadius = view.layer.cornerRadius
        gradientLayer.maskedCorners = view.layer.maskedCorners
    }

    class func styleLogoContainer(_ view: UIView) {
        view.backgroundColor = .white
        view.layer.cornerRadius = 18
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.12
        view.layer.shadowRadius = 10
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
    }

    class func styleProfilePhotoCircle(_ imageView: UIImageView) {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .white
        let radius = imageView.bounds.width / 2
        imageView.layer.cornerRadius = radius
        imageView.layer.masksToBounds = true

        guard imageView.bounds.width > 1, let superview = imageView.superview else { return }
        let tag = 9_101_203
        let halo: UIView
        if let existing = superview.viewWithTag(tag) {
            halo = existing
        } else {
            let view = UIView()
            view.tag = tag
            view.isUserInteractionEnabled = false
            view.backgroundColor = .white
            view.layer.masksToBounds = false
            view.layer.shadowColor = UIColor.darkThemeColor.cgColor
            view.layer.shadowOpacity = 0.22
            view.layer.shadowRadius = 10
            view.layer.shadowOffset = CGSize(width: 0, height: 4)
            superview.insertSubview(view, belowSubview: imageView)
            halo = view
        }
        halo.frame = imageView.frame
        halo.layer.cornerRadius = radius
        halo.layer.shadowPath = UIBezierPath(ovalIn: halo.bounds).cgPath
    }

    class func styleDashboardProfilePhoto(_ imageView: UIImageView) {
        imageView.superview?.viewWithTag(9_101_203)?.removeFromSuperview()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = imageView.bounds.width / 2
        imageView.layer.masksToBounds = true
        imageView.layer.shadowOpacity = 0
        imageView.layer.shadowPath = nil
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.accentThemeColor.cgColor
    }

    class func styleFormCard(_ view: UIView) {
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.darkThemeColor.cgColor
        view.layer.shadowOpacity = 0.10
        view.layer.shadowRadius = 16
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
    }

    class func styleTextField(_ field: CustomTextField) {
        field.backgroundColor = .screenBackgroundColor
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.cardBorderColor.cgColor
        field.font = .systemFont(ofSize: 16, weight: .regular)
        field.attachKeyboardDoneButton()
    }

    class func installKeyboardDoneButton() {
        KeyboardDoneAccessory.shared.start()
    }

    class func installBackChevronOnly() {
        BackButtonTitleHider.shared.start()
        BackButtonLeadingInset.shared.start()
        StandardBackInstaller.shared.start()
        applyNavigationBackChevronAppearance()
    }

    class func stylePageBackButton(_ button: UIButton, tint: UIColor) {
        let config = UIImage.SymbolConfiguration(pointSize: BackButtonLeadingInset.symbolSize, weight: .semibold)
        button.configuration = nil
        button.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        button.setPreferredSymbolConfiguration(config, forImageIn: .normal)
        button.tintColor = tint
        button.contentHorizontalAlignment = .leading
        button.contentVerticalAlignment = .center
        button.adjustsImageSizeForAccessibilityContentSizeCategory = false
    }

    class func applyNavigationBackChevronAppearance() {
        let config = UIImage.SymbolConfiguration(pointSize: BackButtonLeadingInset.symbolSize, weight: .semibold)
        guard let chevron = UIImage(systemName: "chevron.left", withConfiguration: config)?
            .withRenderingMode(.alwaysTemplate) else { return }

        func patch(_ appearance: UINavigationBarAppearance) {
            appearance.setBackIndicatorImage(chevron, transitionMaskImage: chevron)
        }

        let nav = UINavigationBar.appearance()
        let standard = nav.standardAppearance
        patch(standard)
        nav.standardAppearance = standard

        let scroll = nav.scrollEdgeAppearance ?? UINavigationBarAppearance()
        patch(scroll)
        nav.scrollEdgeAppearance = scroll

        let compact = nav.compactAppearance ?? UINavigationBarAppearance()
        patch(compact)
        nav.compactAppearance = compact

        let compactScroll = nav.compactScrollEdgeAppearance ?? UINavigationBarAppearance()
        patch(compactScroll)
        nav.compactScrollEdgeAppearance = compactScroll
        nav.tintColor = .darkThemeColor
    }

    class func stylePrimaryButton(_ button: UIButton) {
        CommonMethods.applyButtonGradient(on: button, cornerRadius: 14)
    }

    class func styleHomeNotificationBell(_ button: UIButton) {
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let image = UIImage(systemName: "bell.fill", withConfiguration: config)?
            .withRenderingMode(.alwaysTemplate)
        button.configuration = nil
        button.setImage(image, for: .normal)
        button.setPreferredSymbolConfiguration(config, forImageIn: .normal)
        button.tintColor = .darkThemeColor
        button.adjustsImageSizeForAccessibilityContentSizeCategory = false
    }

    class func styleListingTypeBadge(_ label: UILabel) {
        label.backgroundColor = .darkThemeColor
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textAlignment = .center
        label.clipsToBounds = true
        label.layer.masksToBounds = true
        updateListingTypeBadgeShape(label)
    }

    class func updateListingTypeBadgeShape(_ label: UILabel) {
        label.layer.cornerRadius = label.bounds.height / 2
    }

    class func styleOutlinedButton(_ button: UIButton) {
        button.configuration = nil
        button.backgroundColor = .white
        button.setTitleColor(.darkThemeColor, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.darkThemeColor.cgColor
        button.clipsToBounds = true
    }

    class func styleFilterChip(_ button: UIButton, title: String? = nil, selected: Bool, compact: Bool = false) {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        let inset: CGFloat = compact ? 6 : 14
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: inset, bottom: 8, trailing: inset)
        let english = title ?? button.accessibilityIdentifier ?? button.configuration?.title ?? button.title(for: .normal) ?? ""
        if !english.isEmpty {
            button.accessibilityIdentifier = english
        }
        config.title = english.localized
        config.titleLineBreakMode = .byTruncatingTail
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: compact ? 12 : 13, weight: .semibold)
            return outgoing
        }
        if selected {
            config.baseBackgroundColor = .darkThemeColor
            config.baseForegroundColor = .white
            config.background.strokeWidth = 0
        } else {
            config.baseBackgroundColor = .white
            config.baseForegroundColor = .darkThemeColor
            config.background.strokeColor = UIColor.darkThemeColor.withAlphaComponent(0.25)
            config.background.strokeWidth = 1
        }
        button.configuration = config
    }

    class func makeFilterChip(title: String, selected: Bool = false) -> UIButton {
        let button = UIButton(type: .system)
        styleFilterChip(button, title: title, selected: selected)
        return button
    }

    class func setRootViewController(_ viewController: UIViewController) {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?
                .windows
                .first

        guard let window else { return }
        UIView.transition(with: window, duration: 0.28, options: .transitionCrossDissolve) {
            window.rootViewController = viewController
        }
    }
    
    
    //Alerts
    static func showAlert(
        title: String = "appName".localized(),
          message: String,
        buttonTitle: String = "OK".localized(),
          from viewController: UIViewController,
          completion: (() -> Void)? = nil
      ) {
          
          let alert = UIAlertController(
              title: title,
              message: message,
              preferredStyle: .alert
          )
          
          let action = UIAlertAction(
              title: buttonTitle,
              style: .default
          ) { _ in
              completion?()
          }
          
          alert.addAction(action)
          
          viewController.present(alert, animated: true)
      }

    static func showToast(
        message: String,
        from viewController: UIViewController,
        below anchor: UIView? = nil,
        textColor: UIColor = .darkThemeColor,
        duration: TimeInterval = 2.4
    ) {
       
        let text = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else { return }
        guard let host = viewController.view else { return }

        host.subviews
            .filter { $0.tag == 9_171_626 }
            .forEach { $0.removeFromSuperview() }

        let toast = UIView()
        toast.tag = 9_171_626
        toast.backgroundColor = .white
        toast.layer.cornerRadius = 14
        toast.clipsToBounds = false
        toast.layer.shadowColor = UIColor.black.cgColor
        toast.layer.shadowOpacity = 0.22
        toast.layer.shadowRadius = 12
        toast.layer.shadowOffset = CGSize(width: 0, height: 4)
        toast.alpha = 0
        toast.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = textColor
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false

        toast.addSubview(label)
        host.addSubview(toast)

        var constraints: [NSLayoutConstraint] = [
            label.topAnchor.constraint(equalTo: toast.topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: toast.bottomAnchor, constant: -16),
            label.leadingAnchor.constraint(equalTo: toast.leadingAnchor, constant: 18),
            label.trailingAnchor.constraint(equalTo: toast.trailingAnchor, constant: -18),
            toast.centerXAnchor.constraint(equalTo: host.centerXAnchor),
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: host.leadingAnchor, constant: 32),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: host.trailingAnchor, constant: -32),
            toast.widthAnchor.constraint(lessThanOrEqualToConstant: 320)
        ]
        if let anchor, anchor.isDescendant(of: host) {
            constraints.append(toast.topAnchor.constraint(equalTo: anchor.bottomAnchor, constant: 10))
        } else {
            constraints.append(toast.centerYAnchor.constraint(equalTo: host.centerYAnchor))
        }
        NSLayoutConstraint.activate(constraints)

        UIView.animate(withDuration: 0.22) {
            toast.alpha = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            UIView.animate(withDuration: 0.22, animations: {
                toast.alpha = 0
            }, completion: { _ in
                toast.removeFromSuperview()
            })
        }
    }
    
    static func showConfirmationAlert(
           title:String = "appName".localized(),
           message: String,
           cancelTitle: String = "Cancel".localized(),
           confirmTitle: String = "OK".localized(),
           confirmStyle: UIAlertAction.Style = .default,
           from viewController: UIViewController,
           confirmAction: @escaping () -> Void
       ) {
           
           let alert = UIAlertController(
               title: title.localized,
               message: message.localized,
               preferredStyle: .alert
           )
           
           alert.addAction(
               UIAlertAction(
                   title: cancelTitle.localized,
                   style: .cancel
               )
           )
           
           alert.addAction(
               UIAlertAction(
                   title: confirmTitle.localized,
                   style: confirmStyle
               ) { _ in
                   confirmAction()
               }
           )
           
           viewController.present(alert, animated: true)
       }
}

private final class BackButtonTitleHider {
   
    static let shared = BackButtonTitleHider()
   
    private var started = false

    func start() {
        guard !started else { return }
        started = true
        swizzle(
            UINavigationController.self,
            from: #selector(UINavigationController.pushViewController(_:animated:)),
            to: #selector(UINavigationController.klever_pushWithoutBackTitle(_:animated:))
        )
        swizzle(
            UINavigationController.self,
            from: #selector(UINavigationController.setViewControllers(_:animated:)),
            to: #selector(UINavigationController.klever_setViewControllersWithoutBackTitle(_:animated:))
        )
    }

    private func swizzle(_ cls: AnyClass, from: Selector, to: Selector) {
        guard
            let original = class_getInstanceMethod(cls, from),
            let swizzled = class_getInstanceMethod(cls, to)
        else { return }
        method_exchangeImplementations(original, swizzled)
    }
    
}

private extension UIViewController {
    func hideBackButtonTitle() {
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.backButtonTitle = ""
    }
}

private final class BackButtonLeadingInset {
    static let shared = BackButtonLeadingInset()
    static let leading: CGFloat = 28
    static let symbolSize: CGFloat = 17
    static let hitSize: CGFloat = 32
    private var started = false

    func start() {
        guard !started else { return }
        started = true
        swizzle(
            UINavigationBar.self,
            from: #selector(UINavigationBar.layoutSubviews),
            to: #selector(UINavigationBar.klever_layoutBackLeading)
        )
    }

    private func swizzle(_ cls: AnyClass, from: Selector, to: Selector) {
        guard
            let original = class_getInstanceMethod(cls, from),
            let swizzled = class_getInstanceMethod(cls, to)
        else { return }
        method_exchangeImplementations(original, swizzled)
    }
}

private extension UINavigationBar {
    @objc func klever_layoutBackLeading() {
        klever_layoutBackLeading()
        preservesSuperviewLayoutMargins = false
        insetsLayoutMarginsFromSafeArea = false
        let leading = BackButtonLeadingInset.leading
        var directional = directionalLayoutMargins
        if directional.leading != leading {
            directional.leading = leading
            directionalLayoutMargins = directional
        }
        var legacy = layoutMargins
        if legacy.left != leading {
            legacy.left = leading
            layoutMargins = legacy
        }
    }
}

private extension UINavigationController {

    @objc func klever_pushWithoutBackTitle(_ viewController: UIViewController, animated: Bool) {
        topViewController?.hideBackButtonTitle()
        klever_pushWithoutBackTitle(viewController, animated: animated)
    }

    @objc func klever_setViewControllersWithoutBackTitle(_ viewControllers: [UIViewController], animated: Bool) {
        viewControllers.forEach { $0.hideBackButtonTitle() }
        klever_setViewControllersWithoutBackTitle(viewControllers, animated: animated)
    }
}

private final class StandardNavBackView: UIView {
    var extraLeading: CGFloat = 12
    let button = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        tag = StandardBackInstaller.itemTag
        button.tag = StandardBackInstaller.itemTag
        addSubview(button)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: extraLeading + BackButtonLeadingInset.hitSize, height: 44)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        button.frame = CGRect(x: extraLeading, y: 0, width: BackButtonLeadingInset.hitSize, height: bounds.height)
    }
    
}

private final class StandardBackInstaller {
    static let shared = StandardBackInstaller()
    static let itemTag = 91_204
    private var started = false

    func start() {
        guard !started else { return }
        started = true
        swizzle(
            UIViewController.self,
            from: #selector(UIViewController.viewWillAppear(_:)),
            to: #selector(UIViewController.klever_standardBackWillAppear(_:))
        )
        swizzle(
            UIViewController.self,
            from: #selector(UIViewController.viewDidAppear(_:)),
            to: #selector(UIViewController.klever_standardBackDidAppear(_:))
        )
    }

    private func swizzle(_ cls: AnyClass, from: Selector, to: Selector) {
        guard
            let original = class_getInstanceMethod(cls, from),
            let swizzled = class_getInstanceMethod(cls, to)
        else { return }
        method_exchangeImplementations(original, swizzled)
    }
}

private final class NavPopGestureKeeper: NSObject, UIGestureRecognizerDelegate {
    static let shared = NavPopGestureKeeper()

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        var responder: UIResponder? = gestureRecognizer.view
        while let current = responder {
            if let nav = current as? UINavigationController {
                return nav.viewControllers.count > 1
            }
            responder = current.next
        }
        return false
    }
}

private extension UIViewController {
    @objc func klever_standardBackWillAppear(_ animated: Bool) {
        klever_standardBackWillAppear(animated)
        installStandardNavigationBackIfNeeded()
    }

    @objc func klever_standardBackDidAppear(_ animated: Bool) {
        klever_standardBackDidAppear(animated)
        styleEmbeddedBackButtonsIfNeeded()
    }

    @objc func klever_standardBackTapped() {
        navigationController?.popViewController(animated: true)
    }

    func installStandardNavigationBackIfNeeded() {
        guard isViewLoaded,
              !(self is UIAlertController),
              !(self is UISearchController),
              let nav = navigationController,
              nav.isNavigationBarHidden == false,
              nav.viewControllers.count > 1,
              nav.topViewController === self
        else { return }

        let alreadyOurs = navigationItem.leftBarButtonItem?.customView?.tag == StandardBackInstaller.itemTag
        if navigationItem.hidesBackButton, alreadyOurs == false {
            return
        }
        if alreadyOurs == false {
            if let title = navigationItem.leftBarButtonItem?.title, title.isEmpty == false {
                return
            }
            if navigationItem.leftBarButtonItems?.contains(where: { ($0.title ?? "").isEmpty == false }) == true {
                return
            }
        }

        if nav.interactivePopGestureRecognizer?.delegate == nil
            || nav.interactivePopGestureRecognizer?.delegate is NavPopGestureKeeper {
            nav.interactivePopGestureRecognizer?.delegate = NavPopGestureKeeper.shared
            nav.interactivePopGestureRecognizer?.isEnabled = true
        }

        let extraLeading: CGFloat = 12
        let wrap = (navigationItem.leftBarButtonItem?.customView as? StandardNavBackView) ?? StandardNavBackView()
        wrap.extraLeading = extraLeading
        wrap.tag = StandardBackInstaller.itemTag
        CommonMethods.stylePageBackButton(wrap.button, tint: .darkThemeColor)
        wrap.button.addTarget(self, action: #selector(klever_standardBackTapped), for: .touchUpInside)
        wrap.invalidateIntrinsicContentSize()
        wrap.frame = CGRect(x: 0, y: 0, width: extraLeading + BackButtonLeadingInset.hitSize, height: 44)

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: wrap)
        navigationItem.hidesBackButton = true
    }

    func styleEmbeddedBackButtonsIfNeeded() {
        guard isViewLoaded, !(self is UIAlertController) else { return }
        styleEmbeddedBackButtons(in: view)
    }

    func styleEmbeddedBackButtons(in view: UIView) {
        if let button = view as? UIButton, isEmbeddedBackButton(button) {
            CommonMethods.stylePageBackButton(button, tint: button.tintColor)
            constrainEmbeddedBackButton(button)
        }
        view.subviews.forEach { styleEmbeddedBackButtons(in: $0) }
    }

    func isEmbeddedBackButton(_ button: UIButton) -> Bool {
        let title = (button.currentTitle ?? button.configuration?.title ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty == false {
            return false
        }
        let actions = button.actions(forTarget: self, forControlEvent: .touchUpInside) ?? []
        return actions.contains(where: { $0 == "backTapped:" })
    }

    func constrainEmbeddedBackButton(_ button: UIButton) {
        button.superview?.constraints
            .filter { $0.firstItem === button && $0.firstAttribute == .leading }
            .forEach { $0.constant = BackButtonLeadingInset.leading }
        button.constraints
            .filter { $0.secondItem == nil && ($0.firstAttribute == .width || $0.firstAttribute == .height) }
            .forEach { $0.constant = BackButtonLeadingInset.hitSize }
    }
}

private final class KeyboardDoneAccessory {
    static let shared = KeyboardDoneAccessory()
    private var started = false

    func start() {
        guard !started else { return }
        started = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textFieldBegan(_:)),
            name: UITextField.textDidBeginEditingNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textViewBegan(_:)),
            name: UITextView.textDidBeginEditingNotification,
            object: nil
        )
    }

    @objc private func textFieldBegan(_ notification: Notification) {
        (notification.object as? UITextField)?.attachKeyboardDoneButton()
    }

    @objc private func textViewBegan(_ notification: Notification) {
        (notification.object as? UITextView)?.attachKeyboardDoneButton()
    }
}

extension UITextField {
    func attachKeyboardDoneButton() {
        guard inputAccessoryView == nil || inputAccessoryView?.tag == KeyboardDoneBar.toolbarTag else { return }
        if inputAccessoryView?.tag != KeyboardDoneBar.toolbarTag {
            inputAccessoryView = KeyboardDoneBar.makeToolbar(target: self)
            reloadInputViews()
        }
        if returnKeyType == .default {
            returnKeyType = .done
        }
    }

    @objc func dismissKeyboardFromToolbar() {
        resignFirstResponder()
    }
}

extension UITextView {
    func attachKeyboardDoneButton() {
        guard inputAccessoryView == nil || inputAccessoryView?.tag == KeyboardDoneBar.toolbarTag else { return }
        if inputAccessoryView?.tag != KeyboardDoneBar.toolbarTag {
            inputAccessoryView = KeyboardDoneBar.makeToolbar(target: self)
            reloadInputViews()
        }
    }

    @objc func dismissKeyboardFromToolbar() {
        resignFirstResponder()
    }
}

enum KeyboardDoneBar {
    static let toolbarTag = 918_273

    static func makeToolbar(target: Any) -> UIToolbar {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        toolbar.tag = toolbarTag
        toolbar.barTintColor = .screenBackgroundColor
        toolbar.tintColor = .darkThemeColor
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(
                title: "Done".localized,
                style: .done,
                target: target,
                action: #selector(UITextField.dismissKeyboardFromToolbar)
            )
        ]
        return toolbar
    }
}

extension UIViewController{
    func goToLoginRoot(role: String? = nil) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginVC else {
            return
        }
        if let role, role.isEmpty == false {
            loginVC.selectedRole = role
        } else if let saved = KeyChainManager.shared.getValue(key: "UserRole"),
                  saved == "agent" || saved == "buyer" {
            loginVC.selectedRole = saved
        }

        let nav = UINavigationController(rootViewController: loginVC)
        nav.setNavigationBarHidden(true, animated: false)

        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            let window = sceneDelegate.window
            window?.rootViewController = nav
            window?.makeKeyAndVisible()
        }
    }
    
     func goToWelcomeTapped() {
        let welcome = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "WelcomeVC")
        let nav = UINavigationController(rootViewController: welcome)
        nav.setNavigationBarHidden(true, animated: false)
         
         if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
             
             let window = sceneDelegate.window
             window?.rootViewController = nav
             window?.makeKeyAndVisible()
             
         }
         
      }
    
    func tenantTabbarRootTapped() {
        
        let tenantTabbar = UIStoryboard(name: "TenantSB", bundle: nil)
            .instantiateViewController(withIdentifier: "TenantTabBarController")
        
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            sceneDelegate.window?.rootViewController = tenantTabbar
            sceneDelegate.window?.makeKeyAndVisible()
        }
    }
    
}

extension UIImageView {
    func setMediaProfileImage(_ path: String?, placeholder: UIImage?) {
        contentMode = .scaleAspectFill
        clipsToBounds = true
        layer.masksToBounds = true
        guard let url = Constant.mediaImageURL(path) else {
            image = placeholder
            return
        }
        sd_setImage(with: url, placeholderImage: placeholder, options: [.retryFailed, .refreshCached])
    }
}









/*
 TAB 2 — SEARCH

 Ye agent ke liye sabse important module hai.

 SEARCH
   ↓
 Search Type
   ├── AI Search
   └── Traditional Filters
 AI Search

 Agent normal language me search karega:

 "Find me 2 bedroom furnished apartments in Piantini under $1,500."

 Agent Query
      ↓
 AI understands request
      ↓
 Extract parameters
      ↓
 Location
 Budget
 Bedrooms
 Property Type
 Furnished
 Amenities
      ↓
 Search Properties
      ↓
 Results
 AI Follow-up

 Agar information incomplete hai:

 AI:
 "What is your maximum budget?"


 Agent:
 "$2,000"


 AI:
 "Do you prefer furnished?"


 Agent:
 "Yes"

 Then:

 AI Search
    ↓
 Top 3 Properties

 Each property:

 Property Card
  ├── Image
  ├── Price
  ├── Location
  ├── Bedrooms
  ├── Bathrooms
  ├── Area
  ├── Match %
  ├── Why this property?
  ├── ❤️ Save
  └── Compare
 Traditional Search / Filters

 Agent manually bhi search kar sake:

 Search
  │
  ├── Location
  ├── Buy / Rent
  ├── Property Type
  ├── Price Range
  ├── Bedrooms
  ├── Bathrooms
  ├── Property Size
  ├── Furnished
  ├── Amenities
  └── Apply Filters

 Results:

 Property Listing
       ↓
 Property Details
 PROPERTY DETAILS

 Agent ke liye details screen:

 Property Details
  │
  ├── Image Gallery
  ├── Property Title
  ├── Price
  ├── Location
  ├── Property Type
  ├── Bedrooms
  ├── Bathrooms
  ├── Area
  ├── Amenities
  ├── Description
  ├── Source / Portal
  ├── Agent Information
  │
  ├── ❤️ Save
  ├── Compare
  ├── Contact Agent
  │
  └── AI Tools
        ├── Instagram
        ├── WhatsApp
        ├── Email
        └── Marketing Description
 
 
 
 
 TAB 3 — SAVED

 Agent ke saved properties:

 SAVED
  │
  ├── Saved Properties
  │
  ├── Saved Searches
  │
  └── Client Searches
 Saved Properties
 Property Card
  ├── Image
  ├── Price
  ├── Location
  ├── Details
  ├── Remove
  └── Compare
 Saved Searches

 Agent apni frequently used search save kar sakta hai:

 "2BR Apartments in Piantini"
 "Luxury Villas under $500K"

 Search ko open karke latest properties dekh sakta hai.

 PROPERTY COMPARISON

 Ye Saved ya Search dono se open ho sakta hai.

 Select 2–3 Properties
         ↓
 Compare
         ↓
 ┌─────────────────────────────┐
 │ Property A │ Property B │ C │
 ├─────────────────────────────┤
 │ Price       │ Price      │   │
 │ Location    │ Location   │   │
 │ Bedrooms    │ Bedrooms   │   │
 │ Bathrooms   │ Bathrooms  │   │
 │ Area        │ Area       │   │
 │ $/m²        │ $/m²       │   │
 │ Amenities   │ Amenities  │   │
 │ Social Area │ Social Area│   │
 └─────────────────────────────┘

 Then:

 AI Comparison
       ↓
 "Property A is better for..."
 "Property B is better for..."
 AI MARKETING CONTENT

 Agent kisi property ko select kare:

 Property
    ↓
 Generate Content
    ↓
 Choose Platform
 ┌─────────────────────────┐
 │ Instagram               │
 │ WhatsApp                │
 │ Email                   │
 │ Marketing Description   │
 └─────────────────────────┘

 Example flow:

 Property Details
       ↓
 Generate Instagram Content
       ↓
 AI generates content
       ↓
 Preview
       ↓
 Copy / Share

 Same flow for:

 WhatsApp
 Email
 Property Description
 CLIENT / LEAD FLOW

 Agent ko client enquiries bhi milengi.

 Property
    ↓
 Contact / Enquiry
    ↓
 Lead Created
    ↓
 Agent Notification
    ↓
 Lead Details

 Lead screen:

 Lead Details
  ├── Client Name
  ├── Contact
  ├── Requirement
  ├── Interested Property
  ├── Date
  ├── Status
  │    ├── New
  │    ├── Contacted
  │    ├── Interested
  │    └── Closed
  └── Contact History
 
 TAB 4 — PROFILE
 PROFILE
  │
  ├── Profile Image
  ├── Agent Name
  ├── Email
  ├── Phone
  ├── Agency
  ├── License / Verification
  │
  ├── Edit Profile
  │
  ├── My Leads
  │
  ├── My Searches
  │
  ├── AI Usage
  │
  ├── Notification Settings
  │
  ├── Security
  │
  ├── Change Password
  │
  ├── Terms & Conditions
  │
  ├── Privacy Policy
  │
  └── Logout
 Complete Agent Flow

 Cursor ko dene ke liye overall flow:

                     SPLASH
                        ↓
                  LOGIN / SIGNUP
                        ↓
                 SELECT ROLE
                        ↓
                     AGENT
                        ↓
               ACCOUNT VERIFICATION
                        ↓
                   AGENT HOME
                        ↓
        ┌───────────────┼────────────────┐
        ↓               ↓                ↓
      HOME            SEARCH           SAVED
        │               │                │
        │               ├── AI Search    ├── Properties
        │               │                ├── Searches
        │               ├── Filters      └── Compare
        │               │
        │               └── Results
        │                    ↓
        │              Property Details
        │                    │
        │          ┌─────────┼──────────┐
        │          ↓         ↓          ↓
        │        Save      Compare    AI Content
        │                               │
        │                    ┌──────────┼─────────┐
        │                    ↓          ↓         ↓
        │                Instagram   WhatsApp   Email
        │
        └── Notifications
                │
                ├── New Property
                ├── Lead
                └── Enquiry


                        ↓
                     PROFILE
                        │
               ┌────────┼─────────┐
               ↓        ↓         ↓
            Account   Leads    Settings
 Agent ka core experience

 Home → AI Search → Property Results → Property Details → Save/Compare → Generate Marketing Content → Lead/Client Enquiry

 Ye agent ko document ke according high-speed real estate sales copilot ke role me cover karta hai.
 */
