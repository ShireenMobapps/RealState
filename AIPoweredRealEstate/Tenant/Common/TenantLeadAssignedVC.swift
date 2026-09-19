//
//  TenantLeadAssignedVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class TenantLeadAssignedVC: UIViewController {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var viewLeadButton: UIButton!
    @IBOutlet weak var myLeadsButton: UIButton!
    @IBOutlet weak var recsButton: UIButton!
    @IBOutlet weak var doneButton: CustomButton!

    var result: ContactAgentWorkflowResult?
    var realtor: PlatformRealtor?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Realtor assigned".localized
        view.backgroundColor = .screenBackgroundColor
        navigationController?.navigationBar.tintColor = .darkThemeColor
        navigationItem.hidesBackButton = true
        CommonMethods.styleFormCard(cardView)
        CommonMethods.stylePrimaryButton(doneButton)
        viewLeadButton.setTitle("View lead".localized, for: .normal)
        myLeadsButton.setTitle("My Leads".localized, for: .normal)
        recsButton.setTitle("View recommendations".localized, for: .normal)
        doneButton.setTitle("Done".localized, for: .normal)
        populate()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CommonMethods.updateGradientFrame(for: doneButton)
    }

    private func populate() {
        guard let realtor, let result else { return }
        let notes = result.buyerNotifications?.inApp
        titleLabel.text = notes?.title ?? "Great Choice! 🎉".localized
        var body = """
        \(realtor.name)
        \(realtor.agency)
        \("Match".localized): \(Int(result.lead.assignmentMetadata?.matchScore ?? 0))
        \(result.lead.assignmentMetadata?.assignmentReason ?? "")

        \(notes?.body ?? "")
        """
        let code = result.lead.displayLeadCode
        if !code.isEmpty {
            body += "\n\n\("Lead ID".localized): \(code)"
        }
        bodyLabel.text = body
    }

    @IBAction func doneTapped(_ sender: Any) {
        guard let nav = navigationController else { return }
        let leadsVC: TenantLeadsVC = TenantStoryboard.load("TenantLeadsVC")
        leadsVC.hidesBottomBarWhenPushed = true
        var stack = nav.viewControllers.filter {
            !($0 is TenantLeadAssignedVC || $0 is TenantContactAgentVC || $0 is TenantAgentListVC || $0 is TenantLeadsVC)
        }
        stack.append(leadsVC)
        nav.setViewControllers(stack, animated: true)
    }

    @IBAction func openRecommendations(_ sender: Any) {
        let vc: TenantRealtorRecommendationsVC = TenantStoryboard.load("TenantRealtorRecommendationsVC")
        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func openLead(_ sender: Any) {
        guard let id = result?.lead.id else { return }
        openBuyerLead(id: id)
    }
}
