//
//  TenantTextPageVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class TenantTextPageVC: UIViewController {
    @IBOutlet weak var bodyLabel: UILabel!

    private var titleText = ""
    private var body = ""

    func configure(title: String, body: String) {
        titleText = title
        self.body = body
        self.title = title
        if isViewLoaded {
            bodyLabel.text = body
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        TenantProfileStyle.applyPushed(self, title: titleText)
        bodyLabel.text = body
        bodyLabel.font = .systemFont(ofSize: 15, weight: .regular)
        bodyLabel.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
        bodyLabel.numberOfLines = 0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}
