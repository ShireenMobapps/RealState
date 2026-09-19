//
//  TenantRecentlyViewedVC.swift
//  AIPoweredRealEstate
//

import UIKit

final class TenantRecentlyViewedVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var emptyLabel: UILabel!

    private var items: [PropertyItem] = []
    private var loadToken = UUID()
    private var isClearing = false

    override func viewDidLoad() {
        super.viewDidLoad()
        TenantProfileStyle.applyPushed(self, title: "Recently Viewed")
        emptyLabel.text = "No data found".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Remove All".localized,
            style: .plain,
            target: self,
            action: #selector(removeAllTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = .accentThemeColor
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PropertyCardCell.nib, forCellWithReuseIdentifier: PropertyCardCell.identifier)
        collectionView.contentInset = UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16)
        updateRemoveAllButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        emptyLabel.text = "No data found".localized
        loadItems()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func updateRemoveAllButton() {
        navigationItem.rightBarButtonItem?.isEnabled = !items.isEmpty && !isClearing
        navigationItem.rightBarButtonItem?.title = "Remove All".localized
    }

    private func applyItems(_ remote: [PropertyItem]) {
        PropertyStore.shared.setRecentlyViewed(remote)
        items = remote
        emptyLabel.text = "No data found".localized
        emptyLabel.isHidden = !remote.isEmpty
        collectionView.reloadData()
        updateRemoveAllButton()
    }

    private func loadItems() {
        let token = UUID()
        loadToken = token
        Task {
            do {
                let remote = try await TenantViewModels.recentlyViewedAPI()
                await MainActor.run {
                    guard self.loadToken == token else { return }
                    self.applyItems(remote)
                }
            } catch {
                await MainActor.run {
                    guard self.loadToken == token else { return }
                    self.applyItems([])
                }
            }
        }
    }

    @objc private func removeAllTapped() {
        guard !items.isEmpty, !isClearing else { return }
        let alert = UIAlertController(
            title: "Remove All".localized,
            message: "Clear all recently viewed properties?".localized,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "Remove All".localized, style: .destructive) { [weak self] _ in
            self?.clearRecentlyViewed()
        })
        present(alert, animated: true)
    }

    private func clearRecentlyViewed() {
        isClearing = true
        updateRemoveAllButton()
        Task {
            do {
                try await TenantViewModels.clearRecentlyViewedAPI()
                await MainActor.run {
                    self.isClearing = false
                    self.applyItems([])
                    self.loadItems()
                }
            } catch {
                await MainActor.run {
                    self.isClearing = false
                    self.updateRemoveAllButton()
                    let alert = UIAlertController(
                        title: "Error".localized,
                        message: "Unable to clear recently viewed.".localized,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { items.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PropertyCardCell.identifier, for: indexPath) as? PropertyCardCell else {
            return UICollectionViewCell()
        }
        let property = items[indexPath.item]
        cell.configure(
            with: property,
            isFavorite: PropertyStore.shared.isFavorite(property.id) || property.isFav,
            showsDelete: true
        )
        cell.onFavorite = nil
        cell.onDelete = { [weak self] in
            self?.deleteRecentlyViewedRemote(property) { success in
                guard success else { return }
                self?.loadItems()
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        openPropertyDetails(items[indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 32
        return CGSize(
            width: width,
            height: PropertyCardCell.height(forTitle: items[indexPath.item].title, width: width)
        )
    }
}
