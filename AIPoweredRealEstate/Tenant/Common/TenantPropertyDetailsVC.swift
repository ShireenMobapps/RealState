//
//  TenantPropertyDetailsVC.swift
//  AIPoweredRealEstate
//

import UIKit

class TenantPropertyDetailsVC: UIViewController {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var imageContainerView: CustomView!
    @IBOutlet weak var galleryCollection: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var typeBadgeLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var specsLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var amenitiesLabel: UILabel!
    @IBOutlet weak var agentNameLabel: UILabel!
    @IBOutlet weak var agentAgencyLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var favoriteCircle: UIView!
    @IBOutlet weak var compareButton: UIButton!
    @IBOutlet weak var contactButton: CustomButton!

    var property: PropertyItem?
    private var gallery: [String] = []
    private var autoScrollTimer: Timer?
    private var currentIndex = 0
    private var lastGallerySize: CGSize = .zero
    private var detailsToken = UUID()

    override func viewDidLoad() {
        super.viewDidLoad()
        applyStyle()
        setupGallery()
        hideAgentSection()
        populate()
        loadPropertyDetails()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        updateFavoriteTitle()
        startAutoScroll()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoScroll()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateAgentActions()
        CommonMethods.updateGradientFrame(for: contactButton)
        CommonMethods.updateListingTypeBadgeShape(typeBadgeLabel)
        let size = galleryCollection.bounds.size
        guard size.width > 0, size != lastGallerySize else { return }
        lastGallerySize = size
        galleryCollection.collectionViewLayout.invalidateLayout()
        guard !gallery.isEmpty else { return }
        galleryCollection.scrollToItem(
            at: IndexPath(item: currentIndex, section: 0),
            at: .centeredHorizontally,
            animated: false
        )
    }

    private func applyStyle() {
        view.backgroundColor = .screenBackgroundColor
        imageContainerView.clipsToBounds = true
        updateAgentActions()
        CommonMethods.styleListingTypeBadge(typeBadgeLabel)
        favoriteCircle.backgroundColor = .white
        favoriteCircle.layer.cornerRadius = 18
        favoriteCircle.clipsToBounds = true
        favoriteButton.backgroundColor = .clear
        favoriteButton.setTitle(nil, for: .normal)
        pageControl.hidesForSinglePage = true
        pageControl.isUserInteractionEnabled = true
        [typeBadgeLabel, favoriteCircle, favoriteButton, pageControl].forEach {
            imageContainerView.bringSubviewToFront($0)
        }
    }

    private func setupGallery() {
        galleryCollection.register(PropertyGalleryCell.self, forCellWithReuseIdentifier: PropertyGalleryCell.identifier)
        galleryCollection.dataSource = self
        galleryCollection.delegate = self
        galleryCollection.isPagingEnabled = true
        galleryCollection.showsHorizontalScrollIndicator = false
        galleryCollection.backgroundColor = .clear
        galleryCollection.decelerationRate = .fast
        if let layout = galleryCollection.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
        }
    }

    private func style(action button: UIButton) {
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.darkThemeColor.cgColor
        button.setTitleColor(.darkThemeColor, for: .normal)
        button.backgroundColor = .white
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
    }

    private func hideAgentSection() {
        let agentCard = agentNameLabel.superview?.superview
        agentCard?.isHidden = true
        agentNameLabel.isHidden = true
        agentAgencyLabel.isHidden = true
        if let height = agentCard?.constraints.first(where: {
            $0.firstAttribute == .height && $0.secondItem == nil
        }) {
            height.constant = 0
        }
    }

    private func populate() {
        guard let property else { return }
        titleLabel.text = property.title
        priceLabel.text = property.priceText
        locationLabel.text = property.location
        specsLabel.text = property.detailSpecsText
        descriptionLabel.text = property.summary
        amenitiesLabel.text = property.amenities.map { $0.localized }.joined(separator: "  ·  ")
        typeBadgeLabel.text = "  \(property.listingType.localized) · \(property.propertyType.localized)  "
        gallery = property.galleryImageNames
        currentIndex = 0
        pageControl.numberOfPages = max(gallery.count, 1)
        pageControl.currentPage = 0
        pageControl.isHidden = gallery.count <= 1
        galleryCollection.reloadData()
        updateFavoriteTitle()
        startAutoScroll()
        hideAgentSection()
        updateAgentActions()
    }

    private func updateAgentActions() {
        compareButton.isHidden = true
        if isAgentFlow {
            compareButton.superview?.isHidden = false
            contactButton.isHidden = false
            contactButton.setTitle("Generate marketing copy".localized, for: .normal)
            CommonMethods.stylePrimaryButton(contactButton)
        } else {
            contactButton.isHidden = true
            compareButton.superview?.isHidden = true
        }
    }

    private func loadPropertyDetails() {
        guard let id = property?.id, !id.isEmpty else { return }
        let token = UUID()
        detailsToken = token
        Task {
            do {
                let item = try await TenantViewModels.propertyDetailsAPI(id: id)
                await MainActor.run {
                    guard self.detailsToken == token else { return }
                    self.property = item
                    PropertyStore.shared.markViewed(item)
                    self.populate()
                }
            } catch {
                print("PROPERTY DETAILS ERROR: \(error)")
            }
        }
    }

    private func startAutoScroll() {
        stopAutoScroll()
        guard gallery.count > 1 else { return }
        let timer = Timer(timeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.scrollToNextPage()
        }
        RunLoop.main.add(timer, forMode: .common)
        autoScrollTimer = timer
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    private func scrollToNextPage() {
        guard gallery.count > 1, galleryCollection.bounds.width > 0 else { return }
        currentIndex = (currentIndex + 1) % gallery.count
        galleryCollection.scrollToItem(
            at: IndexPath(item: currentIndex, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
        pageControl.currentPage = currentIndex
    }

    private func updateFavoriteTitle() {
        guard let property else { return }
        let saved = isAgentFlow
            ? AgentStore.shared.isFavorite(property.id)
            : (PropertyStore.shared.isFavorite(property.id) || property.isFav)
        let heartRed = UIColor(red: 220/255, green: 38/255, blue: 38/255, alpha: 1)
        favoriteCircle.backgroundColor = .white
        favoriteCircle.layer.borderWidth = 0
        favoriteCircle.layer.borderColor = UIColor.clear.cgColor
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        favoriteButton.setImage(
            UIImage(systemName: saved ? "heart.fill" : "heart", withConfiguration: config)?
                .withTintColor(heartRed, renderingMode: .alwaysOriginal),
            for: .normal
        )
    }

    @IBAction func backTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func favoriteTapped(_ sender: UIButton) {
        guard let property else { return }
        if isAgentFlow {
            favoriteButton.isEnabled = false
            toggleAgentWorkingSet(property) { [weak self] in
                guard let self else { return }
                self.property?.isFav = AgentStore.shared.isFavorite(property.id)
                self.favoriteButton.isEnabled = true
                self.updateFavoriteTitle()
            }
            return
        }
        favoriteButton.isEnabled = false
        toggleFavoriteRemote(propertyId: property.id) { [weak self] isFav in
            guard let self else { return }
            self.property?.isFav = isFav
            self.favoriteButton.isEnabled = true
            self.updateFavoriteTitle()
        }
    }

    @IBAction func compareTapped(_ sender: UIButton) {
        guard let property else { return }
        let message = PropertyStore.shared.addToCompare(property.id)
        let alert = UIAlertController(title: "Compare".localized, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
        present(alert, animated: true)
    }

    @IBAction func contactTapped(_ sender: UIButton) {
        if isAgentFlow {
            openMarketingCopy()
            return
        }
        openContactAgent(property: property)
    }

    private func openMarketingCopy() {
        guard let property else { return }
        let vc: AgentMarketingVC = AgentStoryboard.load("AgentMarketingVC")
        vc.property = property
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func pageControlChanged(_ sender: UIPageControl) {
        currentIndex = sender.currentPage
        galleryCollection.scrollToItem(
            at: IndexPath(item: currentIndex, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
        startAutoScroll()
    }
}

extension TenantPropertyDetailsVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        gallery.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PropertyGalleryCell.identifier,
            for: indexPath
        ) as? PropertyGalleryCell else {
            return UICollectionViewCell()
        }
        cell.configure(imageName: gallery[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopAutoScroll()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        syncPage(from: scrollView)
        startAutoScroll()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        syncPage(from: scrollView)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.width
        guard width > 0, gallery.count > 0 else { return }
        pageControl.currentPage = min(max(Int(round(scrollView.contentOffset.x / width)), 0), gallery.count - 1)
    }

    private func syncPage(from scrollView: UIScrollView) {
        let width = scrollView.bounds.width
        guard width > 0, gallery.count > 0 else { return }
        currentIndex = min(max(Int(round(scrollView.contentOffset.x / width)), 0), gallery.count - 1)
        pageControl.currentPage = currentIndex
    }
}

private final class PropertyGalleryCell: UICollectionViewCell {
    static let identifier = "PropertyGalleryCell"
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(imageName: String) {
        if let url = URL(string: imageName), imageName.lowercased().hasPrefix("http") {
            imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "propertyCityApartment"))
        } else {
            imageView.image = UIImage(named: imageName)
        }
    }
}
