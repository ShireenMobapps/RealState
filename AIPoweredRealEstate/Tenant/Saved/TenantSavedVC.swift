//
//  TenantSavedVC.swift
//  AIPoweredRealEstate
//

import UIKit

class TenantSavedVC: UIViewController {

    private enum Section: Int {
        case properties, searches, compare
    }

    @IBOutlet weak var segment: UISegmentedControl!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var compareButton: CustomButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!

    private var section: Section = .properties
    private var favorites: [PropertyItem] = []
    private var candidates: [PropertyItem] = []
    private var favoritesToken = UUID()
    private var lastCollectionWidth: CGFloat = 0
    private var searchItems: [AISearchHistoryItem] = []
    private var searchLoadToken = UUID()
    private var isUpdatingSearches = false
    private let searchesTableView = UITableView(frame: .zero, style: .plain)
    private let searchesSpinner = UIActivityIndicatorView(style: .medium)
    private let removeAllButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .screenBackgroundColor
        segment.selectedSegmentTintColor = .darkThemeColor
        segment.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 13, weight: .semibold)], for: .selected)
        segment.setTitleTextAttributes([.foregroundColor: UIColor.darkThemeColor, .font: UIFont.systemFont(ofSize: 13, weight: .medium)], for: .normal)
        CommonMethods.stylePrimaryButton(compareButton)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PropertyCardCell.nib, forCellWithReuseIdentifier: PropertyCardCell.identifier)
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 24, right: 16)
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CompareSelectCell.nib, forCellReuseIdentifier: CompareSelectCell.identifier)
        addButton.isHidden = true
        addButton.isUserInteractionEnabled = false
        installSearchesViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        reloadContent()
        if section == .searches {
            loadSearchHistory()
        } else if section == .properties || section == .compare {
            loadFavorites()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = collectionView.bounds.width
        if section == .properties,
           collectionView.isHidden == false,
           width > 32,
           abs(width - lastCollectionWidth) > 0.5 {
            lastCollectionWidth = width
            collectionView.collectionViewLayout.invalidateLayout()
        }
        CommonMethods.updateGradientFrame(for: compareButton)
        view.bringSubviewToFront(compareButton)
        view.bringSubviewToFront(removeAllButton)
    }

    private func installSearchesViews() {
        searchesTableView.translatesAutoresizingMaskIntoConstraints = false
        searchesTableView.backgroundColor = .clear
        searchesTableView.separatorStyle = .none
        searchesTableView.dataSource = self
        searchesTableView.delegate = self
        searchesTableView.rowHeight = AISearchQueryCell.rowHeight
        searchesTableView.register(AISearchQueryCell.self, forCellReuseIdentifier: AISearchQueryCell.identifier)
        searchesTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        searchesTableView.isHidden = true
        view.addSubview(searchesTableView)

        searchesSpinner.translatesAutoresizingMaskIntoConstraints = false
        searchesSpinner.hidesWhenStopped = true
        view.addSubview(searchesSpinner)

        removeAllButton.translatesAutoresizingMaskIntoConstraints = false
        removeAllButton.setTitle("Remove All".localized, for: .normal)
        removeAllButton.setTitleColor(.accentThemeColor, for: .normal)
        removeAllButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        removeAllButton.addTarget(self, action: #selector(removeAllSearchesTapped), for: .touchUpInside)
        removeAllButton.isHidden = true
        view.addSubview(removeAllButton)

        NSLayoutConstraint.activate([
            searchesTableView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            searchesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            searchesTableView.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor),
            searchesSpinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchesSpinner.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            removeAllButton.centerYAnchor.constraint(equalTo: addButton.centerYAnchor),
            removeAllButton.trailingAnchor.constraint(equalTo: addButton.trailingAnchor)
        ])
        view.bringSubviewToFront(removeAllButton)
    }

    private func reloadContent(resetCompareOrder: Bool = false) {
        favorites = PropertyStore.shared.favoriteProperties()
        if section == .compare {
            if resetCompareOrder || candidates.isEmpty {
                candidates = PropertyStore.shared.favoriteProperties()
            } else {
                candidates = Self.mergeKeepingOrder(current: candidates, incoming: PropertyStore.shared.favoriteProperties())
            }
        } else {
            candidates = PropertyStore.shared.favoriteProperties()
        }
        addButton.isHidden = true
        collectionView.isHidden = section != .properties
        tableView.isHidden = section != .compare
        searchesTableView.isHidden = section != .searches
        compareButton.isHidden = section != .compare
        updateRemoveAllButton()

        switch section {
        case .properties:
            emptyLabel.text = "Tap the heart on a listing to shortlist it here.".localized
            emptyLabel.isHidden = !favorites.isEmpty
            collectionView.reloadData()
        case .searches:
            emptyLabel.text = "No data found".localized
            emptyLabel.isHidden = !searchItems.isEmpty || searchesSpinner.isAnimating
            searchesTableView.reloadData()
        case .compare:
            emptyLabel.text = "Save listings first, then pick 2–3 to compare.".localized
            emptyLabel.isHidden = !candidates.isEmpty
            refreshCompareButton()
            tableView.contentInset.bottom = 70
            tableView.verticalScrollIndicatorInsets.bottom = 70
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }

    private static func mergeKeepingOrder(current: [PropertyItem], incoming: [PropertyItem]) -> [PropertyItem] {
        let incomingById = Dictionary(incoming.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var kept = current.compactMap { incomingById[$0.id] }
        let keptIDs = Set(kept.map(\.id))
        kept.append(contentsOf: incoming.filter { keptIDs.contains($0.id) == false })
        return kept
    }

    private func refreshCompareButton() {
        let count = PropertyStore.shared.compareIDs.count
        compareButton.setTitle("Compare (%d)".localized(count), for: .normal)
        compareButton.alpha = count >= 2 ? 1 : 0.45
        compareButton.isEnabled = count >= 2
    }

    private func loadFavorites() {
        let token = UUID()
        favoritesToken = token
        Task {
            do {
                let items = try await TenantViewModels.favoritesAPI()
                await MainActor.run {
                    guard self.favoritesToken == token else { return }
                    PropertyStore.shared.setFavorites(items)
                    if self.section == .compare {
                        self.favorites = PropertyStore.shared.favoriteProperties()
                        self.candidates = Self.mergeKeepingOrder(
                            current: self.candidates,
                            incoming: PropertyStore.shared.favoriteProperties()
                        )
                        if self.candidates.isEmpty {
                            self.candidates = PropertyStore.shared.favoriteProperties()
                        }
                        self.emptyLabel.isHidden = !self.candidates.isEmpty
                        self.refreshCompareButton()
                        UIView.performWithoutAnimation {
                            self.tableView.reloadData()
                        }
                    } else {
                        self.reloadContent()
                    }
                }
            } catch {
                await MainActor.run {
                    guard self.favoritesToken == token else { return }
                    PropertyStore.shared.setFavorites([])
                    if self.section == .properties || self.section == .compare {
                        self.reloadContent(resetCompareOrder: true)
                    }
                }
            }
        }
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        section = Section(rawValue: sender.selectedSegmentIndex) ?? .properties
        reloadContent(resetCompareOrder: section == .compare)
        if section == .searches {
            loadSearchHistory()
        } else if section == .properties || section == .compare {
            loadFavorites()
        }
    }

    @IBAction func addSearchTapped(_ sender: Any) {
        openSavedSearch(nil)
    }

    @IBAction func openComparison(_ sender: Any) {
        let selected = PropertyStore.shared.comparedProperties()
        guard selected.count >= 2 else { return }
        openCompare(selected)
    }

    private func updateRemoveAllButton() {
        let show = section == .searches
            && AISearchHistoryItem.showsRemoveAll(count: searchItems.count)
            && !isUpdatingSearches
        removeAllButton.isHidden = !show
        removeAllButton.isEnabled = show
        removeAllButton.setTitle("Remove All".localized, for: .normal)
    }

    private func loadSearchHistory() {
        let token = UUID()
        searchLoadToken = token
        searchesSpinner.startAnimating()
        emptyLabel.isHidden = true
        updateRemoveAllButton()
        Task {
            do {
                let remote = try await AgentViewModels.recentlyAISearchAPI()
                await MainActor.run {
                    guard self.searchLoadToken == token else { return }
                    self.applySearchItems(remote)
                }
            } catch {
                await MainActor.run {
                    guard self.searchLoadToken == token else { return }
                    self.applySearchItems([])
                }
            }
        }
    }

    private func applySearchItems(_ remote: [AISearchHistoryItem]) {
        searchesSpinner.stopAnimating()
        searchItems = remote
        emptyLabel.text = "No data found".localized
        emptyLabel.isHidden = section != .searches || !remote.isEmpty
        searchesTableView.reloadData()
        updateRemoveAllButton()
    }

    @objc private func removeAllSearchesTapped() {
        guard AISearchHistoryItem.showsRemoveAll(count: searchItems.count), !isUpdatingSearches else { return }
        CommonMethods.showConfirmationAlert(
            message: "Clear all AI search history?",
            confirmTitle: "Remove All",
            confirmStyle: .destructive,
            from: self
        ) { [weak self] in
            self?.deleteAllSearchHistory()
        }
    }

    private func deleteAllSearchHistory() {
        isUpdatingSearches = true
        updateRemoveAllButton()
        Task {
            do {
                try await AgentViewModels.deleteAllAISearchHistoryAPI()
                await MainActor.run {
                    self.isUpdatingSearches = false
                    self.applySearchItems([])
                }
            } catch {
                await MainActor.run {
                    self.isUpdatingSearches = false
                    self.updateRemoveAllButton()
                    self.showSearchAPIError(error)
                }
            }
        }
    }

    private func confirmDeleteSearch(_ item: AISearchHistoryItem) {
        guard !isUpdatingSearches else { return }
        CommonMethods.showConfirmationAlert(
            message: "Delete this search history?",
            confirmTitle: "Delete",
            confirmStyle: .destructive,
            from: self
        ) { [weak self] in
            self?.deleteSearchHistory(item)
        }
    }

    private func deleteSearchHistory(_ item: AISearchHistoryItem) {
        isUpdatingSearches = true
        updateRemoveAllButton()
        Task {
            do {
                try await AgentViewModels.deleteAISearchHistoryAPI(id: item.historyId)
                await MainActor.run {
                    self.isUpdatingSearches = false
                    self.searchItems.removeAll { $0.historyId == item.historyId }
                    self.emptyLabel.isHidden = self.section != .searches || !self.searchItems.isEmpty
                    self.searchesTableView.reloadData()
                    self.updateRemoveAllButton()
                }
            } catch {
                await MainActor.run {
                    self.isUpdatingSearches = false
                    self.updateRemoveAllButton()
                    self.showSearchAPIError(error)
                }
            }
        }
    }

    private func showSearchAPIError(_ error: Error) {
        let message = ((error as? APIError)?.errorDescription ?? error.localizedDescription)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let text = message.isEmpty ? "Unable to delete search history.".localized : message
        CommonMethods.showAlert(message: text, from: self)
    }
}

extension TenantSavedVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        favorites.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.item < favorites.count,
              let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PropertyCardCell.identifier,
            for: indexPath
        ) as? PropertyCardCell else {
            return UICollectionViewCell()
        }
        let property = favorites[indexPath.item]
        cell.configure(with: property, isFavorite: true)
        cell.onFavorite = { [weak self] in
            self?.toggleFavoriteRemote(propertyId: property.id) { isFav in
                guard let self else { return }
                if !isFav {
                    self.favorites.removeAll { $0.id == property.id }
                    PropertyStore.shared.setFavorite(property.id, isOn: false)
                }
                self.emptyLabel.isHidden = !self.favorites.isEmpty
                self.collectionView.reloadData()
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < favorites.count else { return }
        openPropertyDetails(favorites[indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = max(collectionView.bounds.width - 32, 1)
        return CGSize(
            width: width,
            height: PropertyCardCell.height(forTitle: favorites[indexPath.item].title, width: width)
        )
    }
}

extension TenantSavedVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView == searchesTableView ? searchItems.count : candidates.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == searchesTableView {
            guard indexPath.row < searchItems.count,
                  let cell = tableView.dequeueReusableCell(
                    withIdentifier: AISearchQueryCell.identifier,
                    for: indexPath
                  ) as? AISearchQueryCell else {
                return UITableViewCell()
            }
            let item = searchItems[indexPath.row]
            cell.configure(query: item.query)
            cell.onDelete = { [weak self] in
                self?.confirmDeleteSearch(item)
            }
            return cell
        }

        guard indexPath.row < candidates.count,
              let cell = tableView.dequeueReusableCell(withIdentifier: CompareSelectCell.identifier, for: indexPath) as? CompareSelectCell else {
            return UITableViewCell()
        }
        let property = candidates[indexPath.row]
        cell.configure(property, selected: PropertyStore.shared.isCompared(property.id))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if tableView == searchesTableView {
            guard indexPath.row < searchItems.count else { return }
            let item = searchItems[indexPath.row]
            openAISearch(prefilled: item.query, chatId: item.historyId)
            return
        }
        guard indexPath.row < candidates.count else { return }
        let property = candidates[indexPath.row]
        if !PropertyStore.shared.isCompared(property.id), PropertyStore.shared.compareIDs.count >= 3 {
            let alert = UIAlertController(title: "Compare".localized, message: "You can compare up to 3 properties.".localized, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
            present(alert, animated: true)
            return
        }
        PropertyStore.shared.toggleCompare(property.id)
        refreshCompareButton()
        guard let cell = tableView.cellForRow(at: indexPath) as? CompareSelectCell else { return }
        cell.configure(property, selected: PropertyStore.shared.isCompared(property.id))
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        tableView == searchesTableView ? AISearchQueryCell.rowHeight : CompareSelectCell.rowHeight
    }
}
