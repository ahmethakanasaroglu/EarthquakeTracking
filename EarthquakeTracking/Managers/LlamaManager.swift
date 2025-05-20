import Foundation

class LlamaManager {
    var messages: [ChatMessage] = []
    var isTyping: Bool = false
    var error: String? = nil
    
    static let messagesDidChangeNotification = Notification.Name("MessagesDidChangeNotification")
    static let typingStatusDidChangeNotification = Notification.Name("TypingStatusDidChangeNotification")
    static let errorDidChangeNotification = Notification.Name("ErrorDidChangeNotification")

    private let baseURL = "http://localhost:11434/api/chat"
    private let modelName = "llama3"
    
    init() {
        let systemMessage = ChatMessage(
            role: .system,
            content: """
            Sen deprem uzmanı bir Türkçe dijital asistansın.
            
            TALİMATLAR:
            - HER ZAMAN ve SADECE Türkçe dilinde yanıt ver.
            - Akıcı ve doğru Türkçe kullan, çeviri gibi görünmeyen doğal cümleler kur.
            - Yanıtların 5-7 kısa ve net cümleden oluşsun.
            - Cümleler arasında mantıksal bağlantı olsun, bütünlük içinde olsun.
            - Teknik bilgileri basit ve anlaşılır Türkçe ile açıkla.
            - İngilizce kelime veya ifadeler KULLANMA.
            - Türkçe dil kurallarına dikkat et, doğru ve doğal cümleler olsun.
            - Depremler, deprem güvenliği ve Türkiye'deki depremler hakkında doğru bilgiler ver.
            - Soruları kısa ve öz cevapla, gereksiz bilgilerle yanıtı uzatma.
            """
        )
        messages.append(systemMessage)
    }
    
    private func notifyMessagesDidChange() {
        NotificationCenter.default.post(name: LlamaManager.messagesDidChangeNotification, object: self)
    }
    
    private func notifyTypingStatusDidChange() {
        NotificationCenter.default.post(name: LlamaManager.typingStatusDidChangeNotification, object: self)
    }
    
    func notifyErrorDidChange() {
        NotificationCenter.default.post(name: LlamaManager.errorDidChangeNotification, object: self, userInfo: ["error": error as Any])
    }
    
    func sendMessage(_ userMessage: String) {
        let newUserMessage = ChatMessage(role: .user, content: userMessage)
        messages.append(newUserMessage)
        notifyMessagesDidChange()
        
        isTyping = true
        notifyTypingStatusDidChange()
        
        var historyMessages: [[String: String]] = []
        
        // Mesaj geçmişini hazırla
        for message in messages {
            historyMessages.append([
                "role": message.role.rawValue,
                "content": message.content
            ])
        }
        
        let userInstruction = """
            Soru: \(userMessage)
            
            Lütfen bu soruya SADECE TÜRKÇE olarak, 5-7 cümleyle kısa ve öz yanıt ver. 
            Cümleler dilbilgisi açısından doğru, anlamlı ve bağlantılı olmalı.
            Kesinlikle İngilizce kelime kullanma.
            Yanıtlarının kısa ve öz olmasına dikkat et, gereksiz bilgilerle uzatma.
            """
        
        historyMessages[historyMessages.count - 1]["content"] = userInstruction
        
        let requestBody: [String: Any] = [
            "model": modelName,
            "messages": historyMessages,
            "stream": false,
            "options": [
                "temperature": 0.2,
                "max_tokens": 150,
                "top_p": 0.8,
                "top_k": 40,
                "frequency_penalty": 0.5,
                "presence_penalty": 0.5,
                "stop": ["English:", "İngilizce:", "User:", "Kullanıcı:"],
                "timeout": 60
            ]
        ]
        
        sendOllamaRequest(requestBody)
    }
    
    private func sendOllamaRequest(_ requestBody: [String: Any]) {
        guard let url = URL(string: baseURL) else {
            self.handleError("Bağlantı hatası")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            self.handleError("İstek oluşturma hatası")
            return
        }
        
        let maxRetries = 2
        var currentRetry = 0
        
        func performRequest() {
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {

                    if let error = error, error._domain == NSURLErrorDomain &&
                       (error._code == NSURLErrorTimedOut || error._code == NSURLErrorNotConnectedToInternet) {
                        
                        if currentRetry < maxRetries {
                            currentRetry += 1
                            print("Zaman aşımı. Yeniden deneniyor... (\(currentRetry)/\(maxRetries))")
                            performRequest()
                            return
                        }
                    }
                    
                    self.isTyping = false
                    self.notifyTypingStatusDidChange()
                    
                    if let error = error {
                        self.handleError("Bağlantı hatası: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let data = data else {
                        self.handleError("Veri alınamadı")
                        return
                    }
                    
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let errorMessage = json["error"] as? String {
                                self.handleError("Yapay zeka hatası: \(errorMessage)")
                                return
                            }
                            
                            if let message = json["message"] as? [String: Any],
                               let content = message["content"] as? String {
                                
                                let processedContent = self.processTurkishResponse(content)
                                let assistantMessage = ChatMessage(role: .assistant, content: processedContent)
                                self.messages.append(assistantMessage)
                                self.notifyMessagesDidChange()
                            } else {
                                self.handleError("Geçersiz yanıt formatı")
                            }
                        } else {
                            self.handleError("Geçersiz yanıt")
                        }
                    } catch {
                        self.handleError("Yanıt işleme hatası: \(error.localizedDescription)")
                    }
                }
            }
            
            task.resume()
        }
        
        performRequest()
    }
    
    func processTurkishResponse(_ content: String) -> String {
        var result = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let prefixesToRemove = ["türkçe:", "turkish:", "yanıt:", "cevap:", "assistant:", "asistan:"]
        for prefix in prefixesToRemove {
            if result.lowercased().hasPrefix(prefix) {
                result = String(result.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        let lines = result.components(separatedBy: .newlines)
        var cleanedLines: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }
            
            if line.range(of: "\\b[a-zA-Z]{3,}\\b", options: .regularExpression) != nil &&
               line.range(of: "[çğıöşüÇĞİÖŞÜ]", options: .regularExpression) == nil &&
               line.range(of: "\\b(ben|sen|biz|siz|ve|ile|için|bu|şu|o|de|da|ki|ne|ya|ama|fakat|veya|ancak)\\b", options: [.regularExpression, .caseInsensitive]) == nil {
                continue
            }
            
            var processedLine = trimmedLine
            if processedLine.lowercased().hasPrefix("tabii") || processedLine.lowercased().hasPrefix("tabi") {
                let words = processedLine.components(separatedBy: " ")
                if words.count > 2 {
                    processedLine = words[2...].joined(separator: " ")
                }
            }
            
            cleanedLines.append(processedLine)
        }
        
        result = cleanedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        
        if result.count > 280 {
            let sentences = result.components(separatedBy: ".")
            var shortAnswer = ""
            var sentenceCount = 0
            
            for sentence in sentences {
                let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty { continue }
                
                if sentenceCount >= 5 || shortAnswer.count > 250 {
                    break
                }
                
                shortAnswer += trimmed + ". "
                sentenceCount += 1
            }
            
            result = shortAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        result = result.replacingOccurrences(of: " ,", with: ",")
        result = result.replacingOccurrences(of: " .", with: ".")
        result = result.replacingOccurrences(of: "..", with: ".")
        result = result.replacingOccurrences(of: "  ", with: " ")
        result = result.replacingOccurrences(of: " !", with: "!")
        result = result.replacingOccurrences(of: " ?", with: "?")
        result = result.replacingOccurrences(of: "( ", with: "(")
        result = result.replacingOccurrences(of: " )", with: ")")
        
        let replacements = [
            "i̇": "i", "İ": "İ",
            "ı̇": "ı", "I": "I",
            "g̃": "ğ", "G̃": "Ğ",
            "s̨": "ş", "S̨": "Ş",
            "c̨": "ç", "C̨": "Ç"
        ]
        
        for (incorrect, correct) in replacements {
            result = result.replacingOccurrences(of: incorrect, with: correct)
        }
        
        return result
    }
    
    func handleError(_ message: String) {
        error = message
        notifyErrorDidChange()
        
        isTyping = false
        notifyTypingStatusDidChange()
        
        let errorMessage = ChatMessage(
            role: .assistant,
            content: "Üzgünüm, şu anda yanıt veremiyorum: \(message). Lütfen internet bağlantınızı kontrol edin veya biraz sonra tekrar deneyin."
        )
        messages.append(errorMessage)
        notifyMessagesDidChange()
    }
    
    func clearConversation() {
        messages.removeAll()
        
        let systemMessage = ChatMessage(
            role: .system,
            content: """
            Sen deprem uzmanı bir Türkçe dijital asistansın.
            
            TALİMATLAR:
            - HER ZAMAN ve SADECE Türkçe dilinde yanıt ver.
            - Akıcı ve doğru Türkçe kullan, çeviri gibi görünmeyen doğal cümleler kur.
            - Yanıtların 5-7 kısa ve net cümleden oluşsun.
            - Cümleler arasında mantıksal bağlantı olsun, bütünlük içinde olsun.
            - Teknik bilgileri basit ve anlaşılır Türkçe ile açıkla.
            - İngilizce kelime veya ifadeler KULLANMA.
            - Türkçe dil kurallarına dikkat et, doğru ve doğal cümleler olsun.
            - Depremler, deprem güvenliği ve Türkiye'deki depremler hakkında doğru bilgiler ver.
            - Soruları kısa ve öz cevapla, gereksiz bilgilerle yanıtı uzatma.
            """
        )
        messages.append(systemMessage)
        notifyMessagesDidChange()
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp = Date()
}

enum MessageRole: String {
    case user
    case assistant
    case system
}
