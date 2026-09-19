//
//  TenantOptionPickerVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class TenantOptionPickerVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!

    var dismissesOnSelect = true
    private var titleText = ""
    private var options: [String] = []
    private var selected = ""
    private var onSelect: ((String) -> Void)?

    func configure(title: String, options: [String], selected: String, onSelect: @escaping (String) -> Void) {
        titleText = title
        self.options = options
        self.selected = selected
        self.onSelect = onSelect
        self.title = title.localized
        if isViewLoaded {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        TenantProfileStyle.applyPushed(self, title: titleText)
        tableView.backgroundColor = .screenBackgroundColor
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        title = titleText.localized
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { options.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let value = options[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = value
        cell.contentConfiguration = config
        cell.accessoryType = value == selected ? .checkmark : .none
        cell.tintColor = .darkThemeColor
        cell.backgroundColor = .white
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let value = options[indexPath.row]
        let changed = value != selected
        selected = value
        onSelect?(selected)
        tableView.reloadData()
        if dismissesOnSelect || !changed {
            navigationController?.popViewController(animated: true)
        }
    }
}
