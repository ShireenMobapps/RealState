//
//  OnboardingVC.swift
//  AIPoweredRealEstate
//

import UIKit

class OnboardingVC: UIViewController {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var logoContainerView: CustomView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var getStartedButton: CustomButton!

    private var autoScrollTimer: Timer?
    private var currentIndex = 0

    private let items: [OnboardingItem] = [
        OnboardingItem(
            iconName: "house.fill",
            title: "Find Your Perfect Property",
            subtitle: "Discover homes and rentals across the Dominican Republic, tailored to your lifestyle and budget."
        ),
        OnboardingItem(
            iconName: "sparkles",
            title: "Search With AI",
            subtitle: "Just describe what you need. Our AI finds matching properties faster than traditional search."
        ),
        OnboardingItem(
            iconName: "square.stack.3d.up.fill",
            title: "Compare & Save Properties",
            subtitle: "Shortlist favorites, compare options side by side, and decide with confidence."
        )
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        applyStyle()
        setupCollectionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        startAutoScroll()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoScroll()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CommonMethods.updateGradientFrame(for: headerView)
        CommonMethods.updateGradientFrame(for: getStartedButton)
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func applyStyle() {
        view.backgroundColor = .screenBackgroundColor
        CommonMethods.applyHeaderGradient(on: headerView, cornerRadius: 32)
        CommonMethods.styleLogoContainer(logoContainerView)
        CommonMethods.stylePrimaryButton(getStartedButton)

        pageControl.numberOfPages = items.count
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = .darkThemeColor
        pageControl.pageIndicatorTintColor = UIColor.lightThemeColor.withAlphaComponent(0.35)
        updateActionTitle()
    }

    private func setupCollectionView() {
        collectionView.register(OnboardingCell.self, forCellWithReuseIdentifier: OnboardingCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear

        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
        }
    }

    private func startAutoScroll() {
        stopAutoScroll()
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.scrollToNextPage()
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    private func scrollToNextPage() {
        currentIndex = (currentIndex + 1) % items.count
        collectionView.scrollToItem(
            at: IndexPath(item: currentIndex, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
        pageControl.currentPage = currentIndex
        updateActionTitle()
    }

    private func updateActionTitle() {
        let isLast = currentIndex == items.count - 1
        getStartedButton.setTitle((isLast ? "Get Started" : "Next").localized, for: .normal)
    }

    @IBAction func skipTapped(_ sender: UIButton) {
        goToWelcome()
    }

    @IBAction func getStartedTapped(_ sender: UIButton) {
        if currentIndex == items.count - 1 {
            goToWelcome()
        } else {
            stopAutoScroll()
            scrollToNextPage()
            startAutoScroll()
        }
    }

    private func goToWelcome() {
        stopAutoScroll()
        guard let languageVC = storyboard?.instantiateViewController(withIdentifier: "ChooseLanguageVC") as? ChooseLanguageVC else {
            return
        }
        navigationController?.setViewControllers([languageVC], animated: true)
    }
}

extension OnboardingVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OnboardingCell.identifier,
            for: indexPath
        ) as? OnboardingCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: items[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopAutoScroll()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / max(scrollView.bounds.width, 1)))
        currentIndex = min(max(page, 0), items.count - 1)
        pageControl.currentPage = currentIndex
        updateActionTitle()
        startAutoScroll()
    }
}
