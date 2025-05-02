import UIKit
import Combine

class MistralChatViewController: UIViewController {
    
    // MARK: - Properties
    private let mistralManager = MistralManager()
    private var cancellables = Set<AnyCancellable>()
    
    private let tableView = UITableView()
    private let messageInputBar = UIView()
    private let messageTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let infoView = UIView()
    
    private var keyboardHeight: CGFloat = 0
    private var bottomConstraint: NSLayoutConstraint!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupKeyboardObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Deprem Chatbot"
        view.backgroundColor = .systemBackground
        
        // UI Bileşenlerini Oluştur
        setupTableView()
        setupInfoView()
        setupMessageBar()
        
        // View Hiyerarşisini Kur
        view.addSubview(tableView)
        view.addSubview(infoView)
        view.addSubview(messageInputBar)
        
        // Constraint'leri Kur - Burada infoView ve tableView ayrı ayrı view'a bağlı
        setupConstraints()
        
        // Temizle butonunu ekle
        let clearButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(clearConversation)
        )
        navigationItem.rightBarButtonItem = clearButton
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        tableView.keyboardDismissMode = .interactive
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    }
    
    private func setupInfoView() {
        infoView.translatesAutoresizingMaskIntoConstraints = false
        infoView.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.1)
        infoView.layer.cornerRadius = 10
        
        let infoIconView = UIImageView(image: UIImage(systemName: "info.circle.fill"))
        infoIconView.translatesAutoresizingMaskIntoConstraints = false
        infoIconView.tintColor = .systemIndigo
        infoIconView.contentMode = .scaleAspectFit
        
        let infoLabel = UILabel()
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.text = "Depremler, güvenlik önlemleri, deprem terminolojisi ve Türkiye'deki depremler hakkında sorular sorabilirsiniz."
        infoLabel.textColor = .darkGray
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        infoLabel.numberOfLines = 0
        
        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .darkGray
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
        messageInputBar.backgroundColor = .systemBackground
        messageInputBar.layer.shadowColor = UIColor.gray.cgColor
        messageInputBar.layer.shadowOffset = CGSize(width: 0, height: -3)
        messageInputBar.layer.shadowOpacity = 0.1
        messageInputBar.layer.shadowRadius = 5
        
        // Metin alanı
        let textFieldContainer = UIView()
        textFieldContainer.translatesAutoresizingMaskIntoConstraints = false
        textFieldContainer.backgroundColor = .secondarySystemBackground
        textFieldContainer.layer.cornerRadius = 20
        
        messageTextField.translatesAutoresizingMaskIntoConstraints = false
        messageTextField.placeholder = "Depremler hakkında bir soru sorun..."
        messageTextField.borderStyle = .none
        messageTextField.backgroundColor = .clear
        messageTextField.returnKeyType = .send
        messageTextField.delegate = self
        
        // Gönder butonu
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.tintColor = .systemIndigo
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
        // Önce infoView constraint'leri
        let infoViewConstraints: [NSLayoutConstraint] = [
            infoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            infoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            infoView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ]
        NSLayoutConstraint.activate(infoViewConstraints)
        
        // MessageInputBar constraint'leri
        bottomConstraint = messageInputBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        let messageBarConstraints: [NSLayoutConstraint] = [
            messageInputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageInputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageInputBar.heightAnchor.constraint(equalToConstant: 70),
            bottomConstraint // burada nil olmadığından emin olmak gerekiyor
        ]
        
        // nil kontrolü yapalım
        if bottomConstraint != nil {
            NSLayoutConstraint.activate(messageBarConstraints)
        } else {
            // bottomConstraint nil ise, onu hariç tutarak aktifleştirelim
            NSLayoutConstraint.activate([
                messageInputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                messageInputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                messageInputBar.heightAnchor.constraint(equalToConstant: 70),
                messageInputBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
        }
        
        // TableView constraint'leri - infoView görünür olduğunda ve olmadığında
        updateTableViewConstraints()
    }
    
    private func updateTableViewConstraints(infoViewVisible: Bool = true) {
        // Tüm eski tableView constraint'lerini kaldır
        for constraint in view.constraints {
            if (constraint.firstItem === tableView && constraint.firstAttribute == .top) ||
               (constraint.secondItem === tableView && constraint.secondAttribute == .top) {
                view.removeConstraint(constraint)
            }
        }
        
        // Yeni constraint'i ekle
        if infoViewVisible {
            tableView.topAnchor.constraint(equalTo: infoView.bottomAnchor, constant: 8).isActive = true
        } else {
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        }
        
        // Sabit olan diğer constraint'leri ekle
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: messageInputBar.topAnchor)
        ])
        
        view.layoutIfNeeded()
    }
    
    private func setupBindings() {
        mistralManager.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
                self?.scrollToBottom()
            }
            .store(in: &cancellables)
        
        mistralManager.$isTyping
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isTyping in
                if isTyping {
                    self?.showTypingIndicator()
                } else {
                    self?.hideTypingIndicator()
                }
            }
            .store(in: &cancellables)
        
        mistralManager.$error
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] errorMessage in
                self?.showErrorAlert(message: errorMessage)
            }
            .store(in: &cancellables)
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
        
        mistralManager.sendMessage(text)
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
            self?.mistralManager.clearConversation()
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
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            bottomConstraint.constant = -keyboardSize.height + view.safeAreaInsets.bottom
            
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
            
            scrollToBottom()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        bottomConstraint.constant = 0
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Helper Methods
    private func scrollToBottom() {
        if mistralManager.messages.count > 0 {
            // Sistem mesajlarını hariç tut (kullanıcıya gösterilmeyen)
            let visibleMessages = mistralManager.messages.filter { $0.role != .system }
            
            if visibleMessages.count > 0 {
                let indexPath = IndexPath(row: visibleMessages.count - 1, section: 0)
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
    
    private func showTypingIndicator() {
        let loadingCell = UIActivityIndicatorView(style: .medium)
        loadingCell.startAnimating()
        loadingCell.frame = CGRect(x: 13, y: 10, width: 30, height: 30)
        
        let containerView = UIView()
        containerView.backgroundColor = .secondarySystemBackground
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
extension MistralChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Sistem mesajlarını gösterme (bunlar arka planda çalışır)
        return mistralManager.messages.filter { $0.role != .system }.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as? MessageCell else {
            return UITableViewCell()
        }
        
        // Sistem mesajlarını filtreleyerek al
        let visibleMessages = mistralManager.messages.filter { $0.role != .system }
        
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
extension MistralChatViewController: UITextFieldDelegate {
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
        bubbleView.layer.cornerRadius = 16
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = UIFont.systemFont(ofSize: 10)
        timeLabel.textColor = .tertiaryLabel
        
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        contentView.addSubview(timeLabel)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Tüm eski constraint'leri kaldır
        for view in [bubbleView, messageLabel, timeLabel] {
            view.removeFromSuperview()
        }
        
        // UI'ı yeniden oluştur
        setupUI()
    }
    
    func configure(with message: MistralMessage) {
        let isUser = message.role == .user
        
        // Bubble styling
        bubbleView.backgroundColor = isUser ? .systemIndigo : .secondarySystemBackground
        messageLabel.textColor = isUser ? .white : .label
        
        // Content
        messageLabel.text = message.content
        
        // Tarih formatı
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        timeLabel.text = dateFormatter.string(from: message.timestamp)
        
        // Position constraints
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
            
            // Baloncuk şeklini ayarla
            bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner]
        } else {
            NSLayoutConstraint.activate([
                messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 12),
                messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12),
                messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
                messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
                
                bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
                bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
                bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),
                
                timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),
                timeLabel.leadingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 8)
            ])
            
            // Baloncuk şeklini ayarla
            bubbleView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
        }
    }
}
