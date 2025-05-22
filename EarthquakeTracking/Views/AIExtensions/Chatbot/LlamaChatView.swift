import UIKit

class LlamaChatViewController: UIViewController {
    
    // MARK: - Properties
    private let llamaManager = LlamaManager()
    
    private let tableView = UITableView()
    private let messageInputBar = UIView()
    private let messageTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let infoView = UIView()
    
    private var keyboardHeight: CGFloat = 0
    private var bottomConstraint: NSLayoutConstraint!
    
    private let gradientLayer = CAGradientLayer()
    
    private var welcomeMessageSent = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotificationObservers()
        setupKeyboardObservers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        setupTabBarAppearance()
        
        if !welcomeMessageSent {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let welcomeMessage = ChatMessage(
                    role: .assistant,
                    content: "Merhaba! Ben Deprem Asistanınızım. Depremler, deprem güvenliği ve hazırlıkları hakkında sorularınızı yanıtlayabilirim. Size nasıl yardımcı olabilirim?"
                )
                self.llamaManager.messages.append(welcomeMessage)
                self.tableView.reloadData()
                self.scrollToBottom()
                self.welcomeMessageSent = true
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.navigationBar.prefersLargeTitles = true
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    private func setupUI() {

        setupGradientBackground()
        
        setupTableView()
        setupInfoView()
        setupMessageBar()
        setupNavigationBar()
        
        view.addSubview(tableView)
        view.addSubview(infoView)
        view.addSubview(messageInputBar)
        
        setupConstraints()
    }
    
    private func setupTabBarAppearance() {
        if let tabBar = self.tabBarController?.tabBar {

            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            
            appearance.backgroundColor = AppTheme.indigoColor
            
            let itemAppearance = UITabBarItemAppearance()
            
            itemAppearance.normal.iconColor = .white.withAlphaComponent(0.6)
            itemAppearance.normal.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.6)
            ]
            
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
    
    private func resetTabBarAppearance() {
        if let tabBar = self.tabBarController?.tabBar {

            tabBar.standardAppearance = UITabBarAppearance()
            
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = tabBar.standardAppearance
            }
        }
    }
    
    private func setupGradientBackground() {
        
        gradientLayer.colors = [
            AppTheme.indigoColor.cgColor,
            AppTheme.indigoLightColor.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupNavigationBar() {

        let navBar = UIView()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        navBar.layer.cornerRadius = 10
        
        let backButton = UIButton(type: .system)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Deprem Asistanı"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .white
        
        let clearButton = UIButton(type: .system)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.setImage(UIImage(systemName: "trash"), for: .normal)
        clearButton.tintColor = .white
        clearButton.addTarget(self, action: #selector(clearConversation), for: .touchUpInside)
        
        navBar.addSubview(backButton)
        navBar.addSubview(titleLabel)
        navBar.addSubview(clearButton)
        
        view.addSubview(navBar)
        
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            navBar.heightAnchor.constraint(equalToConstant: 50),
            
            backButton.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 30),
            backButton.heightAnchor.constraint(equalToConstant: 30),
            
            titleLabel.centerXAnchor.constraint(equalTo: navBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            
            clearButton.trailingAnchor.constraint(equalTo: navBar.trailingAnchor, constant: -16),
            clearButton.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 30),
            clearButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .interactive
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
    }
    
    private func setupInfoView() {
        infoView.translatesAutoresizingMaskIntoConstraints = false
        infoView.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        infoView.layer.cornerRadius = 15
        
        let infoIconView = UIImageView(image: UIImage(systemName: "info.circle.fill"))
        infoIconView.translatesAutoresizingMaskIntoConstraints = false
        infoIconView.tintColor = .white
        infoIconView.contentMode = .scaleAspectFit
        
        let infoLabel = UILabel()
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.text = "Depremler, güvenlik önlemleri ve Türkiye'deki depremler hakkında sorular sorabilirsiniz."
        infoLabel.textColor = .white
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        infoLabel.numberOfLines = 0
        
        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(dismissInfoView), for: .touchUpInside)
        
        infoView.addSubview(infoIconView)
        infoView.addSubview(infoLabel)
        infoView.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            infoIconView.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            infoIconView.centerYAnchor.constraint(equalTo: infoView.centerYAnchor),
            infoIconView.widthAnchor.constraint(equalToConstant: 24),
            infoIconView.heightAnchor.constraint(equalToConstant: 24),
            
            infoLabel.leadingAnchor.constraint(equalTo: infoIconView.trailingAnchor, constant: 12),
            infoLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -12),
            infoLabel.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 16),
            infoLabel.bottomAnchor.constraint(equalTo: infoView.bottomAnchor, constant: -16),
            
            closeButton.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: infoView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    private func setupMessageBar() {
        messageInputBar.translatesAutoresizingMaskIntoConstraints = false
        messageInputBar.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        messageInputBar.layer.cornerRadius = 25
        
        let textFieldContainer = UIView()
        textFieldContainer.translatesAutoresizingMaskIntoConstraints = false
        textFieldContainer.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        textFieldContainer.layer.cornerRadius = 20
        
        messageTextField.translatesAutoresizingMaskIntoConstraints = false
        messageTextField.placeholder = "Depremler hakkında bir soru sorun..."
        messageTextField.attributedPlaceholder = NSAttributedString(
            string: "Depremler hakkında bir soru sorun...",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor(white: 1.0, alpha: 0.6)]
        )
        messageTextField.borderStyle = .none
        messageTextField.backgroundColor = .clear
        messageTextField.returnKeyType = .send
        messageTextField.textColor = .white
        messageTextField.delegate = self
        
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.tintColor = .white
        sendButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        
        textFieldContainer.addSubview(messageTextField)
        messageInputBar.addSubview(textFieldContainer)
        messageInputBar.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            messageTextField.leadingAnchor.constraint(equalTo: textFieldContainer.leadingAnchor, constant: 16),
            messageTextField.trailingAnchor.constraint(equalTo: textFieldContainer.trailingAnchor, constant: -16),
            messageTextField.topAnchor.constraint(equalTo: textFieldContainer.topAnchor),
            messageTextField.bottomAnchor.constraint(equalTo: textFieldContainer.bottomAnchor),
            
            textFieldContainer.leadingAnchor.constraint(equalTo: messageInputBar.leadingAnchor, constant: 16),
            textFieldContainer.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            textFieldContainer.centerYAnchor.constraint(equalTo: messageInputBar.centerYAnchor),
            textFieldContainer.heightAnchor.constraint(equalToConstant: 40),
            
            sendButton.trailingAnchor.constraint(equalTo: messageInputBar.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: messageInputBar.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 40),
            sendButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupConstraints() {
        let navBarHeight: CGFloat = 70
        
        let infoViewConstraints: [NSLayoutConstraint] = [
            infoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: navBarHeight),
            infoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            infoView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ]
        NSLayoutConstraint.activate(infoViewConstraints)
        
        bottomConstraint = messageInputBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        let messageBarConstraints: [NSLayoutConstraint] = [
            messageInputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            messageInputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            messageInputBar.heightAnchor.constraint(equalToConstant: 70),
            bottomConstraint
        ]
        
        NSLayoutConstraint.activate(messageBarConstraints)
        
        updateTableViewConstraints()
    }
    
    private func updateTableViewConstraints(infoViewVisible: Bool = true) {
        for constraint in view.constraints {
            if (constraint.firstItem === tableView && constraint.firstAttribute == .top) ||
                (constraint.secondItem === tableView && constraint.secondAttribute == .top) {
                view.removeConstraint(constraint)
            }
        }
        
        if infoViewVisible {
            tableView.topAnchor.constraint(equalTo: infoView.bottomAnchor, constant: 8).isActive = true
        } else {
            // Custom navigation bar'ın altından başla
            if let navBar = view.subviews.first(where: { $0.subviews.contains(where: { ($0 as? UILabel)?.text == "Deprem Asistanı" }) }) {
                tableView.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 16).isActive = true
            } else {
                tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70).isActive = true
            }
        }
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            tableView.bottomAnchor.constraint(equalTo: messageInputBar.topAnchor, constant: -8)
        ])
        
        view.layoutIfNeeded()
    }
    
    // MARK: - Notification Observers
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(messagesDidChange),
            name: LlamaManager.messagesDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(typingStatusDidChange),
            name: LlamaManager.typingStatusDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(errorDidChange),
            name: LlamaManager.errorDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func messagesDidChange() {
        tableView.reloadData()
        scrollToBottom()
    }
    
    @objc private func typingStatusDidChange() {
        if llamaManager.isTyping {
            showTypingIndicator()
        } else {
            hideTypingIndicator()
        }
    }
    
    @objc private func errorDidChange() {
        if let error = llamaManager.error {
            showErrorAlert(message: error)
        }
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // MARK: - Actions
    @objc private func sendMessage() {
        guard let text = messageTextField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        llamaManager.sendMessage(text)
        messageTextField.text = ""
    }
    
    @objc private func clearConversation() {
        let alert = UIAlertController(
            title: "Konuşmayı Temizle",
            message: "Tüm mesajlar silinecek. Devam etmek istiyor musunuz?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Temizle", style: .destructive) { [weak self] _ in
            self?.llamaManager.clearConversation()
            self?.welcomeMessageSent = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let welcomeMessage = ChatMessage(
                    role: .assistant,
                    content: "Merhaba! Ben Deprem Asistanınızım. Depremler, deprem güvenliği ve hazırlıkları hakkında sorularınızı yanıtlayabilirim. Size nasıl yardımcı olabilirim?"
                )
                self?.llamaManager.messages.append(welcomeMessage)
                self?.tableView.reloadData()
                self?.scrollToBottom()
                self?.welcomeMessageSent = true
            }
        })
        
        present(alert, animated: true)
    }
    
    @objc private func dismissInfoView() {
        UIView.animate(withDuration: 0.3) {
            self.infoView.alpha = 0
        } completion: { _ in
            self.infoView.isHidden = true
            self.updateTableViewConstraints(infoViewVisible: false)
        }
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            bottomConstraint.constant = -keyboardSize.height
            
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
            
            scrollToBottom()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        bottomConstraint.constant = -20
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Helper Methods
    private func scrollToBottom() {
        let visibleMessages = llamaManager.messages.filter { $0.role != .system }
        
        if visibleMessages.count > 0 {
            let indexPath = IndexPath(row: visibleMessages.count - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    private func showTypingIndicator() {
        let loadingCell = UIActivityIndicatorView(style: .medium)
        loadingCell.color = .white
        loadingCell.startAnimating()
        loadingCell.frame = CGRect(x: 13, y: 10, width: 30, height: 30)
        
        let containerView = UIView()
        containerView.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        containerView.layer.cornerRadius = 16
        containerView.frame = CGRect(x: 16, y: 0, width: 50, height: 50)
        containerView.addSubview(loadingCell)
        
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 60))
        footerView.addSubview(containerView)
        
        tableView.tableFooterView = footerView
        scrollToBottom()
    }
    
    private func hideTypingIndicator() {
        tableView.tableFooterView = nil
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Hata",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension LlamaChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return llamaManager.messages.filter { $0.role != .system }.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as? MessageCell else {
            return UITableViewCell()
        }
        
        let visibleMessages = llamaManager.messages.filter { $0.role != .system }
        
        if indexPath.row < visibleMessages.count {
            let message = visibleMessages[indexPath.row]
            cell.configure(with: message)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - UITextFieldDelegate
extension LlamaChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}

// MARK: - MessageCell
class MessageCell: UITableViewCell {
    
    private let messageLabel = UILabel()
    private let bubbleView = UIView()
    private let timeLabel = UILabel()
    
    private let energyRingView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.layer.cornerRadius = 18
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = UIFont.systemFont(ofSize: 10)
        timeLabel.textColor = UIColor(white: 1.0, alpha: 0.7)
        
        energyRingView.translatesAutoresizingMaskIntoConstraints = false
        energyRingView.contentMode = .scaleAspectFit
        energyRingView.isHidden = true
        
        contentView.addSubview(energyRingView)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        contentView.addSubview(timeLabel)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        for view in [bubbleView, messageLabel, timeLabel, energyRingView] {
            view.removeFromSuperview()
        }
        
        setupUI()
    }
    
    func configure(with message: ChatMessage) {
        let isUser = message.role == .user
        
        if isUser {
            bubbleView.backgroundColor = UIColor(red: 0.0/255.0, green: 120.0/255.0, blue: 210.0/255.0, alpha: 0.8)
            messageLabel.textColor = .white
            energyRingView.isHidden = true
        } else {
            // Asistan mesajları için transparent bubble
            bubbleView.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
            messageLabel.textColor = .white
            
            // Asistan mesajlarında enerji halkası görünümü
            energyRingView.isHidden = false
            energyRingView.image = createEnergyRingImage()
        }
        
        messageLabel.text = message.content
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        timeLabel.text = dateFormatter.string(from: message.timestamp)
        
        if isUser {
            NSLayoutConstraint.activate([
                messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 12),
                messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12),
                messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
                messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
                
                bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
                bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
                bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),
                
                timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),
                timeLabel.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: -8)
            ])
            
            bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner]
        } else {
            NSLayoutConstraint.activate([
                messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 12),
                messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12),
                messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
                messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
                
                energyRingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
                energyRingView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 0),
                energyRingView.widthAnchor.constraint(equalToConstant: 40),
                energyRingView.heightAnchor.constraint(equalToConstant: 40),
                
                bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
                bubbleView.leadingAnchor.constraint(equalTo: energyRingView.trailingAnchor, constant: 4),
                bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
                bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),
                
                timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),
                timeLabel.leadingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 8)
            ])
            
            bubbleView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
        }
    }
    
    private func createEnergyRingImage() -> UIImage? {
        let size = CGSize(width: 40, height: 40)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        let colors = [
            UIColor(red: 0.0/255.0, green: 240.0/255.0, blue: 160.0/255.0, alpha: 0.1).cgColor,
            UIColor(red: 0.0/255.0, green: 240.0/255.0, blue: 160.0/255.0, alpha: 0.5).cgColor,
            UIColor(red: 0.0/255.0, green: 240.0/255.0, blue: 160.0/255.0, alpha: 0.0).cgColor
        ]
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations: [CGFloat] = [0.0, 0.5, 1.0]
        
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations) else { return nil }
        
        let center = CGPoint(x: size.width/2, y: size.height/2)
        context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: size.width/2, options: [])
        
        context.setStrokeColor(UIColor(red: 0.0/255.0, green: 240.0/255.0, blue: 160.0/255.0, alpha: 0.8).cgColor)
        context.setLineWidth(1.5)
        context.addEllipse(in: CGRect(x: 5, y: 5, width: size.width-10, height: size.height-10))
        context.strokePath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}
