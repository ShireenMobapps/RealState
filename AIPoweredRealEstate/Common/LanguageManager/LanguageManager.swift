//
//  LanguageManager.swift
//  AIPoweredRealEstate
//

import UIKit
import ObjectiveC

final class LanguageManager {

    static let shared = LanguageManager()
    static let didChange = Notification.Name("languageChanged")

    let languageKey = "selectedLang"

    var currentLanguage: String {
        get { KeyChainManager.shared.getValue(key: languageKey) ?? "en" }
        set {
            let next = (newValue == "es") ? "es" : "en"
            let previous = KeyChainManager.shared.getValue(key: languageKey) ?? "en"
            TenantAccount.shared.language = next == "es" ? "Español" : "English"
            guard next != previous else { return }
            _ = KeyChainManager.shared.saveValue(value: next, key: languageKey)
            NotificationCenter.default.post(name: Self.didChange, object: nil)
            reloadRootInterface()
        }
    }

    var locale: Locale {
        Locale(identifier: currentLanguage == "es" ? "es" : "en")
    }

    var preferredTextInputMode: UITextInputMode? {
        let lang = currentLanguage.lowercased()
        let modes = UITextInputMode.activeInputModes
        if let exact = modes.first(where: { $0.primaryLanguage?.lowercased() == lang }) {
            return exact
        }
        return modes.first { mode in
            let code = (mode.primaryLanguage ?? "").lowercased()
            return code.hasPrefix(lang + "-")
        }
    }

    func code(fromDisplayName value: String) -> String {
        value == "Español" ? "es" : "en"
    }

    func apiPreferredLanguage(forCode code: String) -> String {
        code == "es" ? "spanish" : "english"
    }

    func applyFromProfile(displayName: String, from controller: UIViewController) {
        let code = code(fromDisplayName: displayName)
        let param = ["preferredLanguage": apiPreferredLanguage(forCode: code)]
        Task {
            do {
                _ = try await AuthViewModel.changeLanguageAPI(param: param)
                await MainActor.run { self.currentLanguage = code }
            } catch {
                await MainActor.run {
                    CommonMethods.showAlert(
                        message: (error as? APIError)?.errorDescription ?? error.localizedDescription,
                        from: controller
                    )
                }
            }
        }
    }

    func localisedstr(key: String) -> String {
        guard !key.isEmpty else { return key }
        if let bundle = languageBundle() {
            let value = bundle.localizedString(forKey: key, value: nil, table: nil)
            if value != key { return value }
        }
        return Bundle.main.localizedString(forKey: key, value: key, table: nil)
    }

    func apply(to controller: UIViewController) {
        apply(to: controller.view)
        controller.navigationItem.title = controller.navigationItem.title?.localized
        localizeBarItem(controller.navigationItem.leftBarButtonItem)
        localizeBarItem(controller.navigationItem.rightBarButtonItem)
        controller.tabBarItem.title = controller.tabBarItem.title?.localized
        if let tab = controller as? UITabBarController {
            tab.viewControllers?.forEach { child in
                child.tabBarItem.title = child.tabBarItem.title?.localized
                if let nav = child as? UINavigationController {
                    nav.tabBarItem.title = nav.tabBarItem.title?.localized
                    nav.viewControllers.first?.tabBarItem.title = nav.viewControllers.first?.tabBarItem.title?.localized
                }
            }
        }
    }

    func apply(to view: UIView) {
        if let label = view as? UILabel, let text = label.text, shouldLocalize(text) {
            label.text = text.localized
        } else if let button = view as? UIButton {
            localize(button)
        } else if let field = view as? UITextField {
            if let placeholder = field.placeholder, shouldLocalize(placeholder) {
                field.placeholder = placeholder.localized
            }
        } else if let control = view as? UISegmentedControl {
            for index in 0..<control.numberOfSegments {
                if let title = control.titleForSegment(at: index), shouldLocalize(title) {
                    control.setTitle(title.localized, forSegmentAt: index)
                }
            }
        }
        view.subviews.forEach { apply(to: $0) }
    }

    func applyToKeyWindow() {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        windows.forEach { window in
            guard let root = window.rootViewController else { return }
            apply(to: root)
            root.children.forEach { apply(to: $0) }
            if let nav = root as? UINavigationController {
                nav.viewControllers.forEach { apply(to: $0) }
            }
            if let tab = root as? UITabBarController {
                tab.viewControllers?.forEach { child in
                    apply(to: child)
                    if let nav = child as? UINavigationController {
                        nav.viewControllers.forEach { apply(to: $0) }
                    }
                }
            }
        }
    }

    func reloadRootInterface() {
        guard let tab = currentTabBar() else {
            applyToKeyWindow()
            return
        }
        let selectedIndex = tab.selectedIndex
        let replacement: UITabBarController
        if tab is TenantTabBarController {
            replacement = TenantStoryboard.tabBar()
        } else if tab is AgentTabBarController {
            replacement = AgentStoryboard.tabBar() as? UITabBarController ?? tab
        } else {
            applyToKeyWindow()
            return
        }
        replacement.selectedIndex = selectedIndex
        CommonMethods.setRootViewController(replacement)
    }

    private func currentTabBar() -> UITabBarController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
        if let tab = root as? UITabBarController { return tab }
        if let nav = root as? UINavigationController {
            return nav.viewControllers.first as? UITabBarController
        }
        return root?.tabBarController
    }

    static func enableRuntimeLocalization() {
        UIViewController.lm_swizzleAppearance()
    }

    private func languageBundle() -> Bundle? {
        let lang = currentLanguage
        let candidates: [String?] = [
            Bundle.main.path(forResource: lang, ofType: "lproj"),
            Bundle.main.path(forResource: lang, ofType: "lproj", inDirectory: "LanguageManager"),
            Bundle.main.bundleURL.appendingPathComponent("LanguageManager/\(lang).lproj").path
        ]
        for path in candidates {
            if let path, FileManager.default.fileExists(atPath: path) {
                return Bundle(path: path)
            }
        }
        return nil
    }

    private func shouldLocalize(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if trimmed.contains("@") { return false }
        if trimmed.hasPrefix("$") { return false }
        if trimmed.allSatisfy({ $0.isNumber || $0 == "." || $0 == "," || $0 == "+" || $0 == " " }) { return false }
        return true
    }

    private func localize(_ button: UIButton) {
        if (button.accessibilityIdentifier ?? "").isEmpty {
            button.accessibilityIdentifier = button.configuration?.title ?? button.title(for: .normal)
        }
        if var config = button.configuration, let title = config.title, shouldLocalize(title) {
            config.title = title.localized
            button.configuration = config
        }
        [UIControl.State.normal, .highlighted, .selected, .disabled].forEach { state in
            if let title = button.title(for: state), shouldLocalize(title) {
                button.setTitle(title.localized, for: state)
            }
        }
    }

    private func localizeBarItem(_ item: UIBarButtonItem?) {
        guard let item, let title = item.title, shouldLocalize(title) else { return }
        item.title = title.localized
    }
    
}

extension String {
   
    var localized: String {
        LanguageManager.shared.localisedstr(key: self)
    }

    func localized(_ args: CVarArg...) -> String {
        String(format: localized, locale: LanguageManager.shared.locale, arguments: args)
    }
    
}

extension UIButton {
    var chipValue: String {
        if let id = accessibilityIdentifier, !id.isEmpty { return id }
        return configuration?.title ?? title(for: .normal) ?? ""
    }
}

private extension UIViewController {
    static func lm_swizzleAppearance() {
        _ = lm_swizzleOnce
    }

    private static let lm_swizzleOnce: Void = {
        let pairs: [(Selector, Selector)] = [
            (#selector(viewDidLoad), #selector(lm_viewDidLoad)),
            (#selector(viewWillAppear(_:)), #selector(lm_viewWillAppear(_:)))
        ]
        for (original, swizzled) in pairs {
            guard
                let originalMethod = class_getInstanceMethod(UIViewController.self, original),
                let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzled)
            else { continue }
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }()

    @objc func lm_viewDidLoad() {
        lm_viewDidLoad()
        LanguageManager.shared.apply(to: self)
    }

    @objc func lm_viewWillAppear(_ animated: Bool) {
        lm_viewWillAppear(animated)
        LanguageManager.shared.apply(to: self)
    }
   
}

enum KeyboardLanguageSync {
    static func start() {
        // Forcing textInputMode in Simulator breaks Mac/hardware keyboard typing.
        #if targetEnvironment(simulator)
        return
        #else
        _ = swizzleOnce
        #endif
    }

    static func reloadIfEditing() {
        guard let responder = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .findFirstResponder() else { return }
        responder.reloadInputViews()
    }

    private static let swizzleOnce: Void = {
        swizzleInputMode(on: UITextField.self)
        swizzleInputMode(on: UITextView.self)
    }()

    private static func swizzleInputMode(on cls: AnyClass) {
        let originalSelector = #selector(getter: UIResponder.textInputMode)
        let swizzledSelector = #selector(UIResponder.app_textInputMode)
        guard
            let original = class_getInstanceMethod(cls, originalSelector),
            let swizzled = class_getInstanceMethod(cls, swizzledSelector)
        else { return }
        let didAdd = class_addMethod(
            cls,
            originalSelector,
            method_getImplementation(swizzled),
            method_getTypeEncoding(swizzled)
        )
        if didAdd {
            class_replaceMethod(
                cls,
                swizzledSelector,
                method_getImplementation(original),
                method_getTypeEncoding(original)
            )
        } else {
            method_exchangeImplementations(original, swizzled)
        }
    }
}

private extension UIView {
    func findFirstResponder() -> UIResponder? {
        if isFirstResponder { return self }
        for child in subviews {
            if let responder = child.findFirstResponder() { return responder }
        }
        return nil
    }
}

private extension UIResponder {
    var usesAppLanguageKeyboard: Bool {
        if let field = self as? UITextField {
            switch field.keyboardType {
            case .numberPad, .phonePad, .decimalPad, .asciiCapableNumberPad:
                return false
            default:
                return true
            }
        }
        if let view = self as? UITextView {
            switch view.keyboardType {
            case .numberPad, .phonePad, .decimalPad, .asciiCapableNumberPad:
                return false
            default:
                return true
            }
        }
        return false
    }

    @objc func app_textInputMode() -> UITextInputMode? {
        #if targetEnvironment(simulator)
        return app_textInputMode()
        #else
        if usesAppLanguageKeyboard, let mode = LanguageManager.shared.preferredTextInputMode {
            return mode
        }
        return app_textInputMode()
        #endif
    }
}
