import UIKit

class OnboardingViewController: UIViewController {
    
    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let pageControl = UIPageControl()
    private let continueButton = UIButton(type: .system)
    private let skipButton = UIButton(type: .system)
    
    private var pages: [OnboardingPage] = []
    private var currentPage = 0
    private let numberOfPages = 4
    private var pageViews: [UIView] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPages()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateScrollViewContentSize()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = AppTheme.backgroundColor
        
        // Scroll View
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.bounces = false
        view.addSubview(scrollView)
        
        // Page Control
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.numberOfPages = numberOfPages
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = AppTheme.bodyTextColor.withAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = AppTheme.primaryColor
        pageControl.addTarget(self, action: #selector(pageControlTapped(_:)), for: .valueChanged)
        view.addSubview(pageControl)
        
        // Continue Button
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.setTitle("Devam", for: .normal)
        AppTheme.applyButtonStyle(to: continueButton)
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        view.addSubview(continueButton)
        
        // Skip Button
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.setTitle("Atla", for: .normal)
        skipButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        skipButton.setTitleColor(AppTheme.bodyTextColor, for: .normal)
        skipButton.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
        view.addSubview(skipButton)
        
        // Layout
        NSLayoutConstraint.activate([
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            scrollView.topAnchor.constraint(equalTo: skipButton.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -30),
            
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -30),
            
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            continueButton.widthAnchor.constraint(equalToConstant: 220),
            continueButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func setupPages() {
        // Create onboarding pages
        let page1 = OnboardingPage(
            title: "Deprem Bilgileri",
            description: "Türkiye ve dünya genelindeki son depremleri anında görüntüleyin ve harita üzerinde inceleyin.",
            image: UIImage(systemName: "list.bullet.rectangle")!,
            color: AppTheme.primaryColor
        )
        
        let page2 = OnboardingPage(
            title: "Deprem Uyarıları",
            description: "Önem verdiğiniz bölgeleri izleyin ve belirli büyüklüğün üzerindeki depremler için kişiselleştirilmiş bildirimler alın.",
            image: UIImage(systemName: "bell.fill")!,
            color: AppTheme.primaryLightColor
        )
        
        let page3 = OnboardingPage(
            title: "Deprem Simülasyonu",
            description: "Farklı büyüklüklerdeki depremlerin nasıl hissedileceğini güvenli bir ortamda deneyimleyin ve öğrenin.",
            image: UIImage(systemName: "waveform.path.ecg")!,
            color: AppTheme.secondaryColor
        )
        
        let page4 = OnboardingPage(
            title: "Yapay Zeka Desteği",
            description: "Deprem güvenliği, hazırlık önerileri ve risk analizi konularında yapay zeka destekli kişisel asistandan yardım alın.",
            image: UIImage(systemName: "brain.head.profile")!,
            color: AppTheme.accentColor
        )
        
        pages = [page1, page2, page3, page4]
        
        // Create all page views at once
        for page in pages {
            let pageView = createPageView(page: page)
            scrollView.addSubview(pageView)
            pageViews.append(pageView)
        }
    }
    
    private func updateScrollViewContentSize() {
        // Update page views layout
        for (index, pageView) in pageViews.enumerated() {
            pageView.frame = CGRect(
                x: view.frame.width * CGFloat(index),
                y: 0,
                width: view.frame.width,
                height: scrollView.frame.height
            )
        }
        
        scrollView.contentSize = CGSize(
            width: view.frame.width * CGFloat(pages.count),
            height: scrollView.frame.height
        )
    }
    
    private func createPageView(page: OnboardingPage) -> UIView {
        let pageView = UIView()
        pageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create image view
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = page.image
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        
        // Create background circle for the image
        let circleView = UIView()
        circleView.translatesAutoresizingMaskIntoConstraints = false
        circleView.backgroundColor = page.color
        circleView.layer.cornerRadius = 75
        
        // Add shadow to circle
        circleView.layer.shadowColor = UIColor.black.cgColor
        circleView.layer.shadowOffset = CGSize(width: 0, height: 4)
        circleView.layer.shadowRadius = 8
        circleView.layer.shadowOpacity = 0.2
        
        // Create title label
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = page.title
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = AppTheme.titleTextColor
        titleLabel.textAlignment = .center
        
        // Create description label
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = page.description
        descriptionLabel.font = UIFont.systemFont(ofSize: 17)
        descriptionLabel.textColor = AppTheme.bodyTextColor
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        
        // Create an underline for the title
        let underlineView = UIView()
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        underlineView.backgroundColor = page.color
        
        // Add to page view
        pageView.addSubview(circleView)
        circleView.addSubview(imageView)
        pageView.addSubview(titleLabel)
        pageView.addSubview(underlineView)
        pageView.addSubview(descriptionLabel)
        
        // Set constraints
        NSLayoutConstraint.activate([
            circleView.centerXAnchor.constraint(equalTo: pageView.centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: pageView.centerYAnchor, constant: -80),
            circleView.widthAnchor.constraint(equalToConstant: 150),
            circleView.heightAnchor.constraint(equalToConstant: 150),
            
            imageView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 70),
            imageView.heightAnchor.constraint(equalToConstant: 70),
            
            titleLabel.topAnchor.constraint(equalTo: circleView.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -40),
            
            underlineView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            underlineView.centerXAnchor.constraint(equalTo: titleLabel.centerXAnchor),
            underlineView.widthAnchor.constraint(equalToConstant: 80),
            underlineView.heightAnchor.constraint(equalToConstant: 3),
            
            descriptionLabel.topAnchor.constraint(equalTo: underlineView.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: 40),
            descriptionLabel.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -40)
        ])
        
        return pageView
    }
    
    private func updateUI() {
        pageControl.currentPage = currentPage
        
        if currentPage == pages.count - 1 {
            continueButton.setTitle("Başla", for: .normal)
            
            // Make button more prominent for the last page
            continueButton.backgroundColor = AppTheme.secondaryColor
            
            // Animate the button
            UIView.animate(withDuration: 0.3) {
                self.continueButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            } completion: { _ in
                UIView.animate(withDuration: 0.2) {
                    self.continueButton.transform = CGAffineTransform.identity
                }
            }
        } else {
            continueButton.setTitle("Devam", for: .normal)
            continueButton.backgroundColor = AppTheme.primaryColor
            continueButton.transform = CGAffineTransform.identity
        }
    }
    
    // MARK: - Actions
    @objc private func pageControlTapped(_ sender: UIPageControl) {
        currentPage = sender.currentPage
        let offsetX = CGFloat(currentPage) * scrollView.frame.width
        scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
        updateUI()
    }
    
    @objc private func continueButtonTapped() {
        if currentPage < pages.count - 1 {
            currentPage += 1
            let offsetX = CGFloat(currentPage) * scrollView.frame.width
            scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
            updateUI()
        } else {
            completeOnboarding()
        }
    }
    
    @objc private func skipButtonTapped() {
        completeOnboarding()
    }
    
    private func completeOnboarding() {
        // Mark onboarding as seen
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        
        // Transition to main interface
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let sceneDelegate = windowScene?.delegate as? SceneDelegate
        sceneDelegate?.setupMainInterface(in: windowScene!)
        
        dismiss(animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension OnboardingViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.width)
        currentPage = pageIndex
        updateUI()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Add parallax effect to the page elements
        let pageWidth = scrollView.frame.width
        let currentOffset = scrollView.contentOffset.x
        
        for (index, pageView) in pageViews.enumerated() {
            let pageOffset = CGFloat(index) * pageWidth
            let relativeOffset = currentOffset - pageOffset
            
            // Move the circle view at a different rate for parallax effect
            if let circleView = pageView.subviews.first(where: { $0.layer.cornerRadius == 75 }) {
                let parallaxOffset = relativeOffset * 0.3 // 30% of the scroll movement
                circleView.transform = CGAffineTransform(translationX: -parallaxOffset, y: 0)
            }
            
            // Adjust opacity based on position
            let normalizedOffset = abs(relativeOffset / pageWidth)
            pageView.alpha = 1.0 - normalizedOffset * 0.5 // Dim slightly when not centered
        }
    }
}

// MARK: - OnboardingPage Model
struct OnboardingPage {
    let title: String
    let description: String
    let image: UIImage
    let color: UIColor
}
