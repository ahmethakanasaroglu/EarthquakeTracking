import UIKit

class AIExtensionsViewController: UIViewController {
    
    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Arka plan için gradient layer
    private let gradientLayer = CAGradientLayer()
    
    // Animasyon için gerekli property'ler
    private var viewComponents: [UIView] = []
    private var headerComponents: [UIView] = []
    private var cardComponents: [UIView] = []
    private var animationStarted = false
    private var particleLayer: CAEmitterLayer?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupUI()
        setupParticleEffects() // Parçacık efektleri
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        particleLayer?.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupTabBarAppearance()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !animationStarted {
            startEntryAnimations()
            animationStarted = true
        }
    }
    
    // MARK: - Setup Methods
    private func setupGradientBackground() {
        // İndigo tonlarıyla gradient oluştur
        gradientLayer.colors = [
            AppTheme.indigoColor.cgColor,
            AppTheme.indigoLightColor.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    // Parçacık efekti için yeni metod
    private func setupParticleEffects() {
        let particleEmitter = CAEmitterLayer()
        
        particleEmitter.emitterPosition = CGPoint(x: view.bounds.width / 2.0, y: -50)
        particleEmitter.emitterShape = .line
        particleEmitter.emitterSize = CGSize(width: view.bounds.width, height: 1)
        
        let cell = CAEmitterCell()
        cell.birthRate = 2.0
        cell.lifetime = 20.0
        cell.velocity = 20
        cell.velocityRange = 10
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 4
        cell.spin = 0.5
        cell.spinRange = 1.0
        cell.scale = 0.1
        cell.scaleRange = 0.1
        cell.color = UIColor(white: 1.0, alpha: 0.3).cgColor
        
        // Küçük ışık parçacıkları için
        let circleImage = UIImage(systemName: "circle.fill")!
        cell.contents = circleImage.cgImage
        cell.alphaSpeed = -0.1
        cell.yAcceleration = 10
        
        particleEmitter.emitterCells = [cell]
        
        view.layer.insertSublayer(particleEmitter, at: 1)
        self.particleLayer = particleEmitter
    }
    
    private func setupTabBarAppearance() {
        if let tabBar = self.tabBarController?.tabBar {
            // Tab bar'ı koyu mavi yap
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            
            // Görseldeki koyu mavi renk
            appearance.backgroundColor = UIColor(red: 0.0/255.0, green: 20.0/255.0, blue: 40.0/255.0, alpha: 1.0)
            
            // Tab bar öğeleri
            let itemAppearance = UITabBarItemAppearance()
            
            // Normal durum renkleri
            itemAppearance.normal.iconColor = .white.withAlphaComponent(0.6)
            itemAppearance.normal.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.6)
            ]
            
            // Seçili durum renkleri
            itemAppearance.selected.iconColor = .white
            itemAppearance.selected.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]
            
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance
            
            tabBar.standardAppearance = appearance
            
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = appearance
            }
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "AI Eklentileri"
        view.backgroundColor = .clear // Gradient için arka planı şeffaf yap
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        setupHeader()
        setupAISection()
        
        // Tüm bileşenleri başlangıçta gizle (animasyon için)
        for component in viewComponents {
            component.alpha = 0
            component.transform = CGAffineTransform(translationX: 0, y: 20)
        }
    }
    
    private func setupHeader() {
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = AppTheme.indigoColor
        headerView.layer.cornerRadius = 16
        
        headerView.layer.shadowColor = AppTheme.indigoColor.cgColor
        headerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        headerView.layer.shadowRadius = 8
        headerView.layer.shadowOpacity = 0.3
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            AppTheme.indigoColor.cgColor,
            AppTheme.indigoLightColor.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.cornerRadius = 16
        
        let iconContainerView = UIView()
        iconContainerView.translatesAutoresizingMaskIntoConstraints = false
        iconContainerView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        iconContainerView.layer.cornerRadius = 35
        
        let iconImageView = UIImageView(image: UIImage(systemName: "brain.head.profile"))
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Deprem AI Asistanı"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white
        
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Yapay zeka destekli kişisel deprem asistanı"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = .white
        subtitleLabel.numberOfLines = 0
        
        headerView.addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(subtitleLabel)
        
        contentView.addSubview(headerView)
        
        headerView.layer.insertSublayer(gradientLayer, at: 0)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            headerView.heightAnchor.constraint(equalToConstant: 200),
            
            iconContainerView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 30),
            iconContainerView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 30),
            iconContainerView.widthAnchor.constraint(equalToConstant: 70),
            iconContainerView.heightAnchor.constraint(equalToConstant: 70),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: iconContainerView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 30),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -30),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 30),
            subtitleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -30)
        ])
        
        headerView.layoutIfNeeded()
        gradientLayer.frame = headerView.bounds
        
        // Beyin ikonu için özel bir dönen animasyon
        setupPulsingAnimation(for: iconContainerView)
        
        // Header'ı animasyon listelerine ekleyelim
        viewComponents.append(headerView)
        headerComponents = [iconContainerView, titleLabel, subtitleLabel]
    }
    
    private func setupAISection() {
        let sectionTitle = createSectionTitle(title: "AI Destekli Özellikler")
        let mistralCard = createChatbotCard()
        let earthquakePredictionCard = createPredictionCard()
        let safetyAssistantCard = createSafetyAssistantCard()
        
        contentView.addSubview(sectionTitle)
        contentView.addSubview(mistralCard)
        contentView.addSubview(earthquakePredictionCard)
        contentView.addSubview(safetyAssistantCard)
        
        NSLayoutConstraint.activate([
            sectionTitle.topAnchor.constraint(equalTo: contentView.subviews[0].bottomAnchor, constant: 30),
            sectionTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sectionTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            mistralCard.topAnchor.constraint(equalTo: sectionTitle.bottomAnchor, constant: 16),
            mistralCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mistralCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            earthquakePredictionCard.topAnchor.constraint(equalTo: mistralCard.bottomAnchor, constant: 16),
            earthquakePredictionCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            earthquakePredictionCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            safetyAssistantCard.topAnchor.constraint(equalTo: earthquakePredictionCard.bottomAnchor, constant: 16),
            safetyAssistantCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            safetyAssistantCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            safetyAssistantCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
        
        // Animasyon listelerine ekleyelim
        viewComponents.append(sectionTitle)
        cardComponents = [mistralCard, earthquakePredictionCard, safetyAssistantCard]
        viewComponents.append(contentsOf: cardComponents)
    }
    
    private func createSectionTitle(title: String) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = AppTheme.titleTextColor
        
        let lineView = UIView()
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = AppTheme.indigoColor
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(lineView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            
            lineView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            lineView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            lineView.widthAnchor.constraint(equalToConstant: 40),
            lineView.heightAnchor.constraint(equalToConstant: 3),
            lineView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    private func createChatbotCard() -> UIView {
        let cardView = UIView()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        AppTheme.applyCardStyle(to: cardView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openMistralChatbot))
        cardView.addGestureRecognizer(tapGesture)
        cardView.isUserInteractionEnabled = true
        
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = AppTheme.indigoColor
        iconContainer.layer.cornerRadius = 30
        
        let iconImageView = UIImageView(image: UIImage(systemName: "message.fill"))
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Deprem Chatbot"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = AppTheme.titleTextColor
        
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = "Depremler hakkında tüm sorularınızı yanıtlayan yapay zeka asistanı"
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = AppTheme.bodyTextColor
        descriptionLabel.numberOfLines = 0
        
        let tagView = UIView()
        tagView.translatesAutoresizingMaskIntoConstraints = false
        tagView.backgroundColor = AppTheme.indigoColor
        tagView.layer.cornerRadius = 10
        
        let tagLabel = UILabel()
        tagLabel.translatesAutoresizingMaskIntoConstraints = false
        tagLabel.text = "YENİ"
        tagLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        tagLabel.textColor = .white
        
        let actionButton = UIButton(type: .system)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.setTitle("Konuşmaya Başla", for: .normal)
        actionButton.setImage(UIImage(systemName: "arrow.forward.circle.fill"), for: .normal)
        AppTheme.applyButtonStyle(to: actionButton)
        
        // Buton için animasyon efektleri
        actionButton.addTarget(self, action: #selector(animateButtonTap(_:)), for: .touchDown)
        actionButton.addTarget(self, action: #selector(animateButtonRelease(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        actionButton.addTarget(self, action: #selector(openMistralChatbot), for: .touchUpInside)
        
        iconContainer.addSubview(iconImageView)
        tagView.addSubview(tagLabel)
        
        cardView.addSubview(iconContainer)
        cardView.addSubview(titleLabel)
        cardView.addSubview(descriptionLabel)
        cardView.addSubview(tagView)
        cardView.addSubview(actionButton)
        
        NSLayoutConstraint.activate([
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 160),
            
            iconContainer.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            iconContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            iconContainer.widthAnchor.constraint(equalToConstant: 60),
            iconContainer.heightAnchor.constraint(equalToConstant: 60),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30),
            
            tagView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            tagView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            tagView.widthAnchor.constraint(equalToConstant: 40),
            tagView.heightAnchor.constraint(equalToConstant: 20),
            
            tagLabel.centerXAnchor.constraint(equalTo: tagView.centerXAnchor),
            tagLabel.centerYAnchor.constraint(equalTo: tagView.centerYAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: tagView.leadingAnchor, constant: -8),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            actionButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            actionButton.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 20),
            actionButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20)
        ])
        
        return cardView
    }
    
    private func createPredictionCard() -> UIView {
        let cardView = UIView()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        AppTheme.applyCardStyle(to: cardView)
        
        let overlayView = UIView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = AppTheme.backgroundColor.withAlphaComponent(0.7)
        overlayView.layer.cornerRadius = 16
        
        let comingSoonLabel = UILabel()
        comingSoonLabel.translatesAutoresizingMaskIntoConstraints = false
        comingSoonLabel.text = "YAKINDA"
        comingSoonLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        comingSoonLabel.textColor = AppTheme.indigoColor
        comingSoonLabel.textAlignment = .center
        
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = AppTheme.secondaryColor
        iconContainer.layer.cornerRadius = 30
        
        let iconImageView = UIImageView(image: UIImage(systemName: "chart.line.uptrend.xyaxis"))
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Deprem Tahmin Motoru"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = AppTheme.titleTextColor
        
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = "Gelişmiş makine öğrenmesi ile deprem olasılıklarını analiz eden yapay zeka modeli"
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = AppTheme.bodyTextColor
        descriptionLabel.numberOfLines = 0
        
        iconContainer.addSubview(iconImageView)
        
        cardView.addSubview(iconContainer)
        cardView.addSubview(titleLabel)
        cardView.addSubview(descriptionLabel)
        
        cardView.addSubview(overlayView)
        overlayView.addSubview(comingSoonLabel)
        
        NSLayoutConstraint.activate([
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            iconContainer.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            iconContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            iconContainer.widthAnchor.constraint(equalToConstant: 60),
            iconContainer.heightAnchor.constraint(equalToConstant: 60),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30),
            
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            descriptionLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
            
            // Overlay constraints
            overlayView.topAnchor.constraint(equalTo: cardView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            
            comingSoonLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            comingSoonLabel.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor)
        ])
        
        return cardView
    }
    
    private func createSafetyAssistantCard() -> UIView {
        let cardView = UIView()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        AppTheme.applyCardStyle(to: cardView)
        
        let overlayView = UIView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = AppTheme.backgroundColor.withAlphaComponent(0.7)
        overlayView.layer.cornerRadius = 16
        
        let comingSoonLabel = UILabel()
        comingSoonLabel.translatesAutoresizingMaskIntoConstraints = false
        comingSoonLabel.text = "YAKINDA"
        comingSoonLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        comingSoonLabel.textColor = AppTheme.indigoColor
        comingSoonLabel.textAlignment = .center
        
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = AppTheme.accentColor
        iconContainer.layer.cornerRadius = 30
        
        let iconImageView = UIImageView(image: UIImage(systemName: "shield.lefthalf.filled"))
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Deprem Güvenlik Asistanı"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = AppTheme.titleTextColor
        
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = "Size özel güvenlik tavsiyeleri ve binanız için deprem değerlendirmesi sunan yapay zeka asistanı"
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = AppTheme.bodyTextColor
        descriptionLabel.numberOfLines = 0
        
        iconContainer.addSubview(iconImageView)
        
        cardView.addSubview(iconContainer)
        cardView.addSubview(titleLabel)
        cardView.addSubview(descriptionLabel)
        
        cardView.addSubview(overlayView)
        overlayView.addSubview(comingSoonLabel)
        
        NSLayoutConstraint.activate([
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            iconContainer.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            iconContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            iconContainer.widthAnchor.constraint(equalToConstant: 60),
            iconContainer.heightAnchor.constraint(equalToConstant: 60),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30),
            
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            descriptionLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
            
            overlayView.topAnchor.constraint(equalTo: cardView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            
            comingSoonLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            comingSoonLabel.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor)
        ])
        
        return cardView
    }
    
    // MARK: - Animation Methods
    
    private func startEntryAnimations() {
        // Header animasyonu
        UIView.animate(withDuration: 0.8, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {
            self.viewComponents[0].alpha = 1
            self.viewComponents[0].transform = .identity
        }, completion: { _ in
            // Header içindeki elementlerin tek tek belirmesi
            self.animateHeaderComponents()
        })
        
        // Başlık animasyonu
        UIView.animate(withDuration: 0.6, delay: 0.9, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {
            self.viewComponents[1].alpha = 1
            self.viewComponents[1].transform = .identity
        }, completion: nil)
        
        // Kartların kademeli olarak görünmesi
        for (index, card) in self.cardComponents.enumerated() {
            UIView.animate(withDuration: 0.7, delay: 1.2 + Double(index) * 0.2, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {
                card.alpha = 1
                card.transform = .identity
            }, completion: { _ in
                // Her kartın görünümünden sonra animasyon efekti
                self.animateCardAppearance(card)
            })
        }
    }
    
    private func animateHeaderComponents() {
        // Header içindeki bileşenler için kademeli belirme animasyonu
        for (index, component) in headerComponents.enumerated() {
            // Başlangıç durumu
            component.alpha = 0
            component.transform = CGAffineTransform(translationX: -30, y: 0)
            
            // Animasyon
            UIView.animate(withDuration: 0.6, delay: Double(index) * 0.15, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {
                component.alpha = 1
                component.transform = .identity
            }, completion: nil)
        }
    }
    
    private func animateCardAppearance(_ card: UIView) {
        // Kartın belirme animasyonu
        UIView.animate(withDuration: 0.3, animations: {
            card.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }, completion: { _ in
            UIView.animate(withDuration: 0.2, animations: {
                card.transform = .identity
            })
        })
        
        // İkon için parlama efekti
        if let iconContainer = card.subviews.first(where: { $0.layer.cornerRadius == 30 }) {
            addGlowEffect(to: iconContainer)
        }
    }
    
    // MARK: - Animation Effects
    
    private func setupPulsingAnimation(for view: UIView) {
        // Daha teknolojik görünüm için beyin ikonuna nefes alan efekt ekle
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 2.0
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.1
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        view.layer.add(pulseAnimation, forKey: "pulsing")
    }
    
    private func addGlowEffect(to view: UIView) {
        // İkon etrafında kısa süreli parlama efekti
        let glowLayer = CALayer()
        glowLayer.frame = view.bounds
        glowLayer.cornerRadius = view.layer.cornerRadius
        glowLayer.backgroundColor = view.backgroundColor?.cgColor
        glowLayer.shadowColor = view.backgroundColor?.cgColor
        glowLayer.shadowOffset = .zero
        glowLayer.shadowOpacity = 0
        glowLayer.shadowRadius = 10
        
        view.layer.insertSublayer(glowLayer, at: 0)
        
        // Parlama animasyonu
        let animation = CABasicAnimation(keyPath: "shadowOpacity")
        animation.fromValue = 0
        animation.toValue = 0.8
        animation.duration = 0.5
        animation.autoreverses = true
        animation.isRemovedOnCompletion = true
        
        glowLayer.add(animation, forKey: "glow")
        
        // Animasyon bittikten sonra layer'ı kaldır
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            glowLayer.removeFromSuperlayer()
        }
    }
    
    // MARK: - Button Animations
    
    @objc private func animateButtonTap(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            sender.alpha = 0.9
        }
    }
    
    @objc private func animateButtonRelease(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = .identity
            sender.alpha = 1.0
        }
    }
    
    // MARK: - Actions
    @objc private func openMistralChatbot() {
        // Tıklamada parlama efekti
        if let chatbotCard = cardComponents.first {
            UIView.animate(withDuration: 0.15, animations: {
                chatbotCard.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                chatbotCard.alpha = 0.8
            }, completion: { _ in
                UIView.animate(withDuration: 0.15, animations: {
                    chatbotCard.transform = .identity
                    chatbotCard.alpha = 1.0
                }, completion: { _ in
                    // Animasyon bittikten sonra ekranı aç
                    let mistralViewController = MistralChatViewController()
                    self.navigationController?.pushViewController(mistralViewController, animated: true)
                })
            })
        } else {
            // Kart bulunamazsa direkt aç
            let mistralViewController = MistralChatViewController()
            navigationController?.pushViewController(mistralViewController, animated: true)
        }
    }
}
