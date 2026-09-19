//
//  TenantProfileStyle.swift
//  AIPoweredRealEstate
//

import UIKit

enum TenantProfileStyle {
    static func applyPushed(_ controller: UIViewController, title: String) {
        controller.view.backgroundColor = .screenBackgroundColor
        controller.title = title.localized
        controller.navigationController?.navigationBar.tintColor = .darkThemeColor
    }
}
