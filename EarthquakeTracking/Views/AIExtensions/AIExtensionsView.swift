import UIKit

class AIExtensionsViewController: UIViewController {
    
    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "AI Eklentileri"
        view.backgroundColor = .systemBackground
        
        // Scroll View
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
        
        // Header Bölümü
        setupHeader()
        
        // Mistral AI Chatbot Bölümü
        setupMistralSection()
    }
    
    private func setupHeader() {
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.9)
        headerView.layer.cornerRadius = 16
        
        let iconImageView = UIImageView(image: UIImage(systemName: "brain.head.profile"))
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Deprem AI Asistanı"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .white
        
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Yapay zeka destekli yardımcınız"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = .white
        
        headerView.addSubview(iconImageView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(subtitleLabel)
        
        contentView.addSubview(headerView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            headerView.heightAnchor.constraint(equalToConstant: 180),
            
            iconImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            iconImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 60),
            iconImageView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor)
        ])
    }
    
    private func setupMistralSection() {
        let sectionTitle = UILabel()
        sectionTitle.translatesAutoresizingMaskIntoConstraints = false
        sectionTitle.text = "AI Destekli Özellikler"
        sectionTitle.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        sectionTitle.textColor = .label
        
        let mistralCard = createMistralCard()
        
        contentView.addSubview(sectionTitle)
        contentView.addSubview(mistralCard)
        
        NSLayoutConstraint.activate([
            sectionTitle.topAnchor.constraint(equalTo: contentView.subviews[0].bottomAnchor, constant: 30),
            sectionTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            mistralCard.topAnchor.constraint(equalTo: sectionTitle.bottomAnchor, constant: 16),
            mistralCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mistralCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mistralCard.heightAnchor.constraint(equalToConstant: 160),
            mistralCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    private func createMistralCard() -> UIView {
        let cardView = UIView()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .secondarySystemBackground
        cardView.layer.cornerRadius = 20
        
        // Gölge efekti
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 5)
        cardView.layer.shadowRadius = 10
        cardView.layer.shadowOpacity = 0.1
        
        // İçerik view
        let contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.backgroundColor = .clear
        
        // İcon
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = .systemIndigo
        iconContainer.layer.cornerRadius = 30
        
        let iconImageView = UIImageView(image: UIImage(systemName: "message.fill"))
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white
        
        // Başlık
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Deprem Chatbot"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .label
        
        // Açıklama
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = "Depremler hakkında tüm sorularınızı yanıtlayan yapay zeka asistanı"
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        
        // Buton
        let actionButton = UIButton(type: .system)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.setTitle("Konuşmaya Başla", for: .normal)
        actionButton.setImage(UIImage(systemName: "arrow.forward.circle.fill"), for: .normal)
        actionButton.tintColor = .systemIndigo
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        actionButton.addTarget(self, action: #selector(openMistralChatbot), for: .touchUpInside)
        
        // View hiyerarşisi
        iconContainer.addSubview(iconImageView)
        contentContainer.addSubview(iconContainer)
        contentContainer.addSubview(titleLabel)
        contentContainer.addSubview(descriptionLabel)
        contentContainer.addSubview(actionButton)
        cardView.addSubview(contentContainer)
        
        // Constraints
        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            contentContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            contentContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            contentContainer.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
            
            iconContainer.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            iconContainer.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 60),
            iconContainer.heightAnchor.constraint(equalToConstant: 60),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30),
            
            titleLabel.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 5),
            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            
            actionButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            actionButton.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 16),
            actionButton.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])
        
        // Tüm karta tıklama özelliği ekle
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openMistralChatbot))
        cardView.addGestureRecognizer(tapGesture)
        cardView.isUserInteractionEnabled = true
        
        return cardView
    }
    
    // MARK: - Actions
    @objc private func openMistralChatbot() {
        let mistralViewController = MistralChatViewController()
        navigationController?.pushViewController(mistralViewController, animated: true)
    }
}
