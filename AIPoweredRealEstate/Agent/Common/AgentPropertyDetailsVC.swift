//
//  AgentPropertyDetailsVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class AgentPropertyDetailsVC: UIViewController {

    var property: PropertyItem?

    @IBOutlet weak var photoView: UIImageView?
    @IBOutlet weak var favoriteButton: UIButton?
    @IBOutlet weak var compareButton: UIButton?
    @IBOutlet weak var marketingButton: CustomButton?
    @IBOutlet weak var reportButton: UIButton?
    @IBOutlet weak var typeLabel: UILabel?
    @IBOutlet weak var priceLabel: UILabel?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var locationLabel: UILabel?
    @IBOutlet weak var specsLabel: UILabel?
    @IBOutlet weak var summaryLabel: UILabel?
    @IBOutlet weak var amenitiesLabel: UILabel?
    @IBOutlet weak var listedByLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .screenBackgroundColor
        showTenantDetails()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        showTenantDetails()
    }

    private func showTenantDetails() {
        guard let property, let nav = navigationController else { return }
        if nav.topViewController is TenantPropertyDetailsVC { return }
        let details: TenantPropertyDetailsVC = TenantStoryboard.load("TenantPropertyDetailsVC")
        details.property = property
        details.hidesBottomBarWhenPushed = true
        var stack = nav.viewControllers.filter { $0 !== self }
        stack.append(details)
        nav.setViewControllers(stack, animated: false)
    }
}
