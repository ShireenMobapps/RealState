//
//  TenantStoryboard.swift
//  AIPoweredRealEstate
//

import UIKit

enum TenantStoryboard {
    static let board = UIStoryboard(name: "TenantSB", bundle: nil)

    static func tabBar() -> TenantTabBarController {
        board.instantiateViewController(withIdentifier: "TenantTabBarController") as! TenantTabBarController
    }

    static func load<T: UIViewController>(_ identifier: String) -> T {
        board.instantiateViewController(withIdentifier: identifier) as! T
    }
}
