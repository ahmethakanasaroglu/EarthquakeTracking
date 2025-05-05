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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPages()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Scroll View
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        view.addSubview(scrollView)
        
        // Page Control
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.numberOfPages = numberOfPages
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .systemGray4
        pageControl.currentPageIndicatorTintColor = .systemIndigo
        pageControl.addTarget(self, action: #selector(pageControlTapped(_:)), for: .valueChanged)
        view.addSubview(pageControl)
        
        // Continue Button
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.setTitle("Devam", for: .normal)
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        continueButton.backgroundColor = .systemIndigo
        continueButton.tintColor = .white
        continueButton.layer.cornerRadius = 25
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        view.addSubview(continueButton)
        
        // Skip Button
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.setTitle("Atla", for: .normal)
        skipButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        skipButton.setTitleColor(.secondaryLabel, for: .normal)
        skipButton.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
        view.addSubview(skipButton)
        
        // Layout
        NSLayoutConstraint.activate([
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            scrollView.topAnchor.constraint(equalTo: skipButton.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -20),
            
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -30),
            
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            continueButton.widthAnchor.constraint(equalToConstant: 200),
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupPages() {
        // Create onboarding pages
        let page1 = OnboardingPage(
            title: "Deprem Bilgileri",
            description: "Türkiye ve dünya genelindeki son depremleri anında görüntüleyin ve harita üzerinde inceleyin.",
            image: UIImage(systemName: "list.bullet.rectangle")!
        )
        
        let page2 = OnboardingPage(
            title: "Deprem Uyarıları",
            description: "Önem verdiğiniz bölgeleri izleyin ve belirli büyüklüğün üzerindeki depremler için kişiselleştirilmiş bildirimler alın.",
            image: UIImage(systemName: "bell.fill")!
        )
        
        let page3 = OnboardingPage(
            title: "Deprem Simülasyonu",
            description: "Farklı büyüklüklerdeki depremlerin nasıl hissedileceğini güvenli bir ortamda deneyimleyin ve öğrenin.",
            image: UIImage(systemName: "waveform.path.ecg")!
        )
        
        let page4 = OnboardingPage(
            title: "Yapay Zeka Desteği",
            description: "Deprem güvenliği, hazırlık önerileri ve risk analizi konularında yapay zeka destekli kişisel asistandan yardım alın.",
            image: UIImage(systemName: "brain.head.profile")!
        )
        
        pages = [page1, page2, page3, page4]
        
        // Add pages to scroll view
        for (index, page) in pages.enumerated() {
            let pageView = createPageView(page: page)
            scrollView.addSubview(pageView)
            
            NSLayoutConstraint.activate([
                pageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                pageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: CGFloat(index) * view.frame.width),
                pageView.widthAnchor.constraint(equalToConstant: view.frame.width),
                pageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
            ])
        }
        
        scrollView.contentSize = CGSize(width: view.frame.width * CGFloat(pages.count), height: scrollView.frame.height)
    }
    
    private func createPageView(page: OnboardingPage) -> UIView {
        let pageView = UIView()
        pageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create image view
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = page.image
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemIndigo
        
        // Create background circle for the image
        let circleView = UIView()
        circleView.translatesAutoresizingMaskIntoConstraints = false
        circleView.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.1)
        circleView.layer.cornerRadius = 75
        
        // Create title label
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = page.title
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        
        // Create description label
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = page.description
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        
        // Add to page view
        pageView.addSubview(circleView)
        pageView.addSubview(imageView)
        pageView.addSubview(titleLabel)
        pageView.addSubview(descriptionLabel)
        
        // Set constraints
        NSLayoutConstraint.activate([
            circleView.centerXAnchor.constraint(equalTo: pageView.centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: pageView.centerYAnchor, constant: -60),
            circleView.widthAnchor.constraint(equalToConstant: 150),
            circleView.heightAnchor.constraint(equalToConstant: 150),
            
            imageView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 70),
            imageView.heightAnchor.constraint(equalToConstant: 70),
            
            titleLabel.topAnchor.constraint(equalTo: circleView.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -40),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: 40),
            descriptionLabel.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -40)
        ])
        
        return pageView
    }
    
    private func updateUI() {
        pageControl.currentPage = currentPage
        
        if currentPage == pages.count - 1 {
            continueButton.setTitle("Başla", for: .normal)
        } else {
            continueButton.setTitle("Devam", for: .normal)
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
}

// MARK: - OnboardingPage Model
struct OnboardingPage {
    let title: String
    let description: String
    let image: UIImage
}
