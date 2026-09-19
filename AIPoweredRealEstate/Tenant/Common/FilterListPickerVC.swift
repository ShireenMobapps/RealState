//
//  FilterListPickerVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class FilterListPickerVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    static func present(
        from host: UIViewController,
        group: DashboardFilterGroup,
        selected: [DashboardFilterChip],
        onApply: @escaping ([DashboardFilterChip]) -> Void
    ) {
        let picker = FilterListPickerVC(group: group, selected: selected, onApply: onApply)
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.selectedDetentIdentifier = group.options.count > 8 ? .large : .medium
        }
        host.present(nav, animated: true)
    }

    private let group: DashboardFilterGroup
    private let onApply: ([DashboardFilterChip]) -> Void
    private var selected: [DashboardFilterChip]
    private var query = ""
    private var shouldApplyOnDismiss = true

    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyLabel = UILabel()

    private init(
        group: DashboardFilterGroup,
        selected: [DashboardFilterChip],
        onApply: @escaping ([DashboardFilterChip]) -> Void
    ) {
        self.group = group
        self.selected = selected
        self.onApply = onApply
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .screenBackgroundColor
        title = "Amenities".localized
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel".localized,
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done".localized,
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = .darkThemeColor
        navigationItem.leftBarButtonItem?.tintColor = .darkThemeColor
        setupSearchBar()
        setupTable()
        setupEmptyLabel()
        reloadVisibleRows()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let dismissing = isBeingDismissed || navigationController?.isBeingDismissed == true
        guard shouldApplyOnDismiss, dismissing else { return }
        shouldApplyOnDismiss = false
        onApply(selected)
    }

    private func setupSearchBar() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search by name".localized
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.delegate = self
        searchBar.returnKeyType = .search
        view.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8)
        ])
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .screenBackgroundColor
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelection = true
        tableView.keyboardDismissMode = .onDrag
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupEmptyLabel() {
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = "No data found".localized
        emptyLabel.textAlignment = .center
        emptyLabel.font = .systemFont(ofSize: 15, weight: .medium)
        emptyLabel.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    private var filteredOptions: [DashboardFilterChip] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return group.options }
        return group.options.filter { $0.label.localizedCaseInsensitiveContains(trimmed) }
    }

    private func option(at indexPath: IndexPath) -> DashboardFilterChip? {
        guard filteredOptions.indices.contains(indexPath.row) else { return nil }
        return filteredOptions[indexPath.row]
    }

    private func isSelected(_ option: DashboardFilterChip) -> Bool {
        selected.contains { $0.value.caseInsensitiveCompare(option.value) == .orderedSame }
    }

    private func reloadVisibleRows() {
        tableView.reloadData()
        emptyLabel.isHidden = tableView.numberOfRows(inSection: 0) > 0
    }

    @objc private func cancelTapped() {
        shouldApplyOnDismiss = false
        dismiss(animated: true)
    }

    @objc private func doneTapped() {
        shouldApplyOnDismiss = false
        onApply(selected)
        dismiss(animated: true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        query = searchText
        reloadVisibleRows()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        let option = option(at: indexPath)
        config.text = option?.label
        let isOn = option.map { isSelected($0) } ?? false
        cell.contentConfiguration = config
        cell.selectionStyle = .none
        cell.accessoryType = .none
        cell.accessoryView = checkboxView(isOn: isOn)
        cell.backgroundColor = .white
        return cell
    }

    private func checkboxView(isOn: Bool) -> UIImageView {
        let name = isOn ? "checkmark.square.fill" : "square"
        let view = UIImageView(image: UIImage(systemName: name))
        view.tintColor = isOn ? .darkThemeColor : UIColor(red: 173/255, green: 181/255, blue: 189/255, alpha: 1)
        view.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        view.bounds = CGRect(x: 0, y: 0, width: 24, height: 24)
        return view
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let option = option(at: indexPath) else { return }
        if isSelected(option) {
            selected.removeAll { $0.value.caseInsensitiveCompare(option.value) == .orderedSame }
        } else {
            selected.append(option)
        }
        tableView.reloadData()
    }
}
