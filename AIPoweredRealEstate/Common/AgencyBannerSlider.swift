//
//  AgencyBannerSlider.swift
//  AIPoweredRealEstate
//

import UIKit

final class AgencyBannerSlider: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    static let bannerHeight: CGFloat = 120

    var onVisibilityChange: ((Bool) -> Void)?

    private var imagePaths: [String] = []
    private var currentIndex = 0
    private var timer: Timer?
    private var heightConstraint: NSLayoutConstraint!

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.backgroundColor = .clear
        collection.isPagingEnabled = true
        collection.showsHorizontalScrollIndicator = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(AgencyBannerCell.self, forCellWithReuseIdentifier: AgencyBannerCell.reuseId)
        collection.isUserInteractionEnabled = false
        return collection
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = false
        isHidden = true
        addSubview(collectionView)
        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightConstraint
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        timer?.invalidate()
    }

    func load() {
        Task {
            let items = (try? await AuthViewModel.agenciesAPI()) ?? []
            let paths = items.compactMap { item -> String? in
                guard let path = item.imagePath, Constant.mediaImageURL(path) != nil else { return nil }
                return path
            }
            await MainActor.run {
                self.imagePaths = paths
                self.currentIndex = 0
                self.collectionView.reloadData()
                let visible = paths.isEmpty == false
                self.isHidden = !visible
                self.heightConstraint.constant = visible ? Self.bannerHeight : 0
                self.onVisibilityChange?(visible)
                if visible {
                    self.collectionView.layoutIfNeeded()
                    self.collectionView.scrollToItem(
                        at: IndexPath(item: 0, section: 0),
                        at: .centeredHorizontally,
                        animated: false
                    )
                }
                self.startAutoScroll()
            }
        }
    }

    func startAutoScroll() {
        stopAutoScroll()
        guard imagePaths.count > 1, isHidden == false else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.scrollToNext()
        }
    }

    func stopAutoScroll() {
        timer?.invalidate()
        timer = nil
    }

    private func scrollToNext() {
        guard imagePaths.count > 1 else { return }
        currentIndex = (currentIndex + 1) % imagePaths.count
        collectionView.scrollToItem(
            at: IndexPath(item: currentIndex, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        imagePaths.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: AgencyBannerCell.reuseId,
            for: indexPath
        ) as! AgencyBannerCell
        cell.configure(imagePath: imagePaths[indexPath.item])
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let size = collectionView.bounds.size
        if size.width > 1, size.height > 1 { return size }
        return CGSize(width: max(bounds.width, 1), height: Self.bannerHeight)
    }
}

private final class AgencyBannerCell: UICollectionViewCell {
    static let reuseId = "AgencyBannerCell"

    private let cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.darkThemeColor.cgColor
        view.layer.shadowOpacity = 0.10
        view.layer.shadowRadius = 10
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = 16
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = false
        clipsToBounds = false
        contentView.addSubview(cardView)
        cardView.addSubview(imageView)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            imageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            imageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            imageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(imagePath: String) {
        imageView.setMediaProfileImage(imagePath, placeholder: UIImage(named: "appLogo"))
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white
    }
}
