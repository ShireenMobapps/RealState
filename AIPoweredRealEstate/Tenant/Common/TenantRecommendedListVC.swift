//
//  TenantRecommendedListVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class TenantRecommendedListVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var footerSpinner: UIActivityIndicatorView!

    var filterSelections: [DashboardFilterChip] = []
    var rangeFilters = PropertyRangeFilters()

    private let pageSize = 10
    private var items: [PropertyItem] = []
    private var filterRecord: [PropertyItem] = []
    private var currentPage = 1
    private var hasMore = true
    private var isLoading = false
    private var loadToken = UUID()
    private var didLoadOnce = false
    private let searchField = CustomTextField()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Recommended Properties".localized
        view.backgroundColor = .screenBackgroundColor
        navigationController?.navigationBar.tintColor = .darkThemeColor
        emptyLabel.text = "No properties found".localized
        emptyLabel.isHidden = true
        spinner.hidesWhenStopped = true
        footerSpinner.hidesWhenStopped = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.register(PropertyCardCell.nib, forCellWithReuseIdentifier: PropertyCardCell.identifier)
        collectionView.contentInset = UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16)
        collectionView.keyboardDismissMode = .onDrag
        installSearchBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        if !didLoadOnce {
            didLoadOnce = true
            reloadFromStart()
        } else {
            applyKeywordFilter()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func installSearchBar() {
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.placeholder = "Search by name or location".localized
        searchField.returnKeyType = .search
        searchField.clearButtonMode = .whileEditing
        searchField.delegate = self
        searchField.addTarget(self, action: #selector(keywordChanged), for: .editingChanged)
        CommonMethods.styleTextField(searchField)
        searchField.leftPadding = 40
        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        icon.tintColor = UIColor.darkThemeColor.withAlphaComponent(0.45)
        icon.contentMode = .scaleAspectFit
        let wrap = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 24))
        icon.frame = CGRect(x: 12, y: 2, width: 20, height: 20)
        wrap.addSubview(icon)
        searchField.leftView = wrap
        searchField.leftViewMode = .always
        view.addSubview(searchField)

        view.constraints
            .filter { ($0.firstItem as? UIView) === collectionView && $0.firstAttribute == .top }
            .forEach { $0.isActive = false }

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchField.heightAnchor.constraint(equalToConstant: 44),
            collectionView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8)
        ])
    }

    @objc private func keywordChanged() {
        applyKeywordFilter()
    }

    private func applyKeywordFilter() {
        let keyword = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        filterRecord = keyword.isEmpty ? items : items.filter { $0.matchesKeyword(keyword) }
        emptyLabel.text = "No properties found".localized
        emptyLabel.isHidden = isLoading || !filterRecord.isEmpty
        collectionView.reloadData()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        applyKeywordFilter()
        return true
    }

    private func reloadFromStart() {
        currentPage = 1
        hasMore = true
        items = []
        filterRecord = []
        collectionView.reloadData()
        loadPage(reset: true)
    }

    private func loadPage(reset: Bool) {
        guard !isLoading else { return }
        guard hasMore || reset else { return }
        isLoading = true
        let token = UUID()
        loadToken = token
        if reset {
            spinner.startAnimating()
            emptyLabel.isHidden = true
        } else {
            footerSpinner.startAnimating()
        }

        var request = PropertyFilterRequest.dashboard(selections: filterSelections)
        request.apply(rangeFilters)
        request.page = currentPage
        request.limit = pageSize

        Task {
            do {
                let page = try await TenantViewModels.searchPropertiesPageAPI(request)
                await MainActor.run {
                    guard self.loadToken == token else { return }
                    self.applyPage(page, reset: reset)
                }
            } catch {
                await MainActor.run {
                    guard self.loadToken == token else { return }
                    self.isLoading = false
                    self.spinner.stopAnimating()
                    self.footerSpinner.stopAnimating()
                    if reset {
                        self.applyPage(
                            PropertySearchPage(items: [], page: 1, limit: self.pageSize, total: 0, hasMore: false),
                            reset: true
                        )
                    }
                }
            }
        }
    }

    private func applyPage(_ page: PropertySearchPage, reset: Bool) {
        isLoading = false
        spinner.stopAnimating()
        footerSpinner.stopAnimating()

        if reset {
            items = page.items
        } else {
            let existing = Set(items.map(\.id))
            let fresh = page.items.filter { !existing.contains($0.id) }
            items.append(contentsOf: fresh)
            if fresh.isEmpty {
                hasMore = false
                PropertyStore.shared.mergeRemote(items)
                applyKeywordFilter()
                updateBottomInset()
                return
            }
        }

        currentPage = page.page + 1
        hasMore = page.hasMore && !page.items.isEmpty
        PropertyStore.shared.mergeRemote(items)
        applyKeywordFilter()
        updateBottomInset()
    }

    private func updateBottomInset() {
        collectionView.contentInset.bottom = hasMore ? 56 : 24
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard hasMore, !isLoading, !items.isEmpty else { return }
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        if offsetY > contentHeight - height - 120 {
            loadPage(reset: false)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filterRecord.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PropertyCardCell.identifier,
            for: indexPath
        ) as? PropertyCardCell else {
            return UICollectionViewCell()
        }
        let property = filterRecord[indexPath.item]
        cell.configure(
            with: property,
            isFavorite: (isAgentFlow ? AgentStore.shared.isFavorite(property.id) : PropertyStore.shared.isFavorite(property.id)) || property.isFav
        )
        cell.onFavorite = { [weak self] in
            guard let self else { return }
            let reload = {
                self.applyKeywordFilter()
            }
            if self.isAgentFlow {
                self.toggleAgentWorkingSet(property, reload: reload)
            } else {
                self.toggleFavoriteRemote(propertyId: property.id) { isFav in
                    if let index = self.items.firstIndex(where: { $0.id == property.id }) {
                        self.items[index].isFav = isFav
                    }
                    reload()
                }
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        openPropertyDetails(filterRecord[indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 32
        return CGSize(
            width: width,
            height: PropertyCardCell.height(forTitle: filterRecord[indexPath.item].title, width: width)
        )
    }
}
