import Foundation

class MistralManager {
    var messages: [MistralMessage] = []
    var isTyping: Bool = false
    var error: String? = nil
    
    // Notification için kullanılacak sabitler
    static let messagesDidChangeNotification = Notification.Name("MessagesDidChangeNotification")
    static let typingStatusDidChangeNotification = Notification.Name("TypingStatusDidChangeNotification")
    static let errorDidChangeNotification = Notification.Name("ErrorDidChangeNotification")

    private let baseURL = "http://localhost:11434/api/chat"
    private let modelName = "mistral"
    
    init() {
        let systemMessage = MistralMessage(
            role: .system,
            content: """
            Sen deprem uzmanı bir Türkçe dijital asistansın.
            
            TALİMATLAR:
            - HER ZAMAN ve SADECE Türkçe dilinde yanıt ver.
            - Akıcı ve doğru Türkçe kullan, çeviri gibi görünmeyen doğal cümleler kur.
            - Yanıtların 9-10 kısa ve net cümleden oluşsun.
            - Cümleler arasında mantıksal bağlantı olsun, bütünlük içinde olsun.
            - Teknik bilgileri basit ve anlaşılır Türkçe ile açıkla.
            - İngilizce kelime veya ifadeler KULLANMA.
            - Türkçe dil kurallarına dikkat et, doğru ve doğal cümleler olsun. Sohbet ağzıyla konuşabilirsin. ASLA İMLA HATASI VE KONUŞMA BOZUKLUĞU, SAÇMA CÜMLE YAPISI GİBİ HATALAR YAPMA.
            - SANA SORULAN SORULARI İYİCE ANLAYIP CEVAP VER. ALAKASIZ CEVAPLAR VERME, GEREKSİZ KONUŞMAYI UZATMA.

            
            Depremler, deprem güvenliği, deprem hazırlığı ve Türkiye'deki depremler hakkında doğru bilgiler ver. Bilimsel ve güncel bilgilere sadık kal.
            """
        )
        messages.append(systemMessage)
    }
    
    // Yardımcı metotlar - Notification gönderme
    private func notifyMessagesDidChange() {
        NotificationCenter.default.post(name: MistralManager.messagesDidChangeNotification, object: self)
    }
    
    private func notifyTypingStatusDidChange() {
        NotificationCenter.default.post(name: MistralManager.typingStatusDidChangeNotification, object: self)
    }
    
    private func notifyErrorDidChange() {
        NotificationCenter.default.post(name: MistralManager.errorDidChangeNotification, object: self, userInfo: ["error": error as Any])
    }
    
    func sendMessage(_ userMessage: String) {
        let newUserMessage = MistralMessage(role: .user, content: userMessage)
        messages.append(newUserMessage)
        notifyMessagesDidChange()
        
        isTyping = true
        notifyTypingStatusDidChange()
        
        var historyMessages: [[String: String]] = []
        for message in messages {
            historyMessages.append([
                "role": message.role.rawValue,
                "content": message.content
            ])
        }
        
        let userInstruction = """
            Soru: \(userMessage)
            
            Lütfen bu soruya SADECE TÜRKÇE olarak, 9-10 cümleyle kısa ve öz yanıt ver. 
            Cümleler dilbilgisi açısından doğru, anlamlı ve bağlantılı olmalı.
            Kesinlikle İngilizce kelime kullanma.
            Türkçe dil kurallarına dikkat et, doğru ve doğal cümleler olsun. Sohbet ağzıyla konuşabilirsin. ASLA İMLA HATASI VE KONUŞMA BOZUKLUĞU, SAÇMA CÜMLE YAPISI GİBİ HATALAR YAPMA.
            SANA SORULAN SORULARI İYİCE ANLAYIP CEVAP VER. ALAKASIZ CEVAPLAR VERME, GEREKSİZ KONUŞMAYI UZATMA.
            """
        
        historyMessages[historyMessages.count - 1]["content"] = userInstruction
        
        let requestBody: [String: Any] = [
            "model": modelName,
            "messages": historyMessages,
            "stream": false,
            "options": [
                "temperature": 0.3,
                "max_tokens": 120,
                "top_p": 0.7,
                "stop": ["English:", "İngilizce:"]
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
        request.timeoutInterval = 30
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            self.handleError("İstek oluşturma hatası")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
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
                            self.handleError("Yapay zeka hatası")
                            return
                        }
                        
                        if let message = json["message"] as? [String: Any],
                           let content = message["content"] as? String {
                            
                            let processedContent = self.processTurkishResponse(content)
                            let assistantMessage = MistralMessage(role: .assistant, content: processedContent)
                            self.messages.append(assistantMessage)
                            self.notifyMessagesDidChange()
                        } else {
                            self.handleError("Geçersiz yanıt formatı")
                        }
                    } else {
                        self.handleError("Geçersiz yanıt")
                    }
                } catch {
                    self.handleError("Yanıt işleme hatası")
                }
            }
        }
        
        task.resume()
    }
    
    private func processTurkishResponse(_ content: String) -> String {
        var result = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if result.lowercased().hasPrefix("türkçe:") {
            result = String(result.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if result.lowercased().hasPrefix("turkish:") {
            result = String(result.dropFirst(8)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        let lines = result.components(separatedBy: "\n")
        var cleanedLines: [String] = []
        
        for line in lines {
            if line.range(of: "\\b[a-zA-Z]{4,}\\b", options: .regularExpression) != nil &&
               line.range(of: "[çğıöşüÇĞİÖŞÜ]", options: .regularExpression) == nil {
                continue
            }
            cleanedLines.append(line)
        }
        
        result = cleanedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        
        if result.count > 200 {
            let sentences = result.components(separatedBy: ".")
            var shortAnswer = ""
            var sentenceCount = 0
            
            for sentence in sentences {
                let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty { continue }
                
                if sentenceCount >= 3 || shortAnswer.count > 180 {
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
        
        return result
    }
    
    private func handleError(_ message: String) {
        error = message
        notifyErrorDidChange()
        
        isTyping = false
        notifyTypingStatusDidChange()
        
        let errorMessage = MistralMessage(
            role: .assistant,
            content: "Üzgünüm, şu anda yanıt veremiyorum. Lütfen internet bağlantınızı ve Mistral modelinin çalıştığını kontrol edin."
        )
        messages.append(errorMessage)
        notifyMessagesDidChange()
    }
    
    func clearConversation() {
        messages.removeAll()
        
        let systemMessage = MistralMessage(
            role: .system,
            content: """
            Sen deprem uzmanı bir Türkçe dijital asistansın.
            
            TALİMATLAR:
            - HER ZAMAN ve SADECE Türkçe dilinde yanıt ver.
            - Akıcı ve doğru Türkçe kullan, çeviri gibi görünmeyen doğal cümleler kur.
            - Yanıtların 9-10 kısa ve net cümleden oluşsun.
            - Cümleler arasında mantıksal bağlantı olsun, bütünlük içinde olsun.
            - Teknik bilgileri basit ve anlaşılır Türkçe ile açıkla.
            - İngilizce kelime veya ifadeler KULLANMA.
            - Türkçe dil kurallarına dikkat et, doğru ve doğal cümleler olsun. Sohbet ağzıyla konuşabilirsin. ASLA İMLA HATASI VE KONUŞMA BOZUKLUĞU, SAÇMA CÜMLE YAPISI GİBİ HATALAR YAPMA.
            - SANA SORULAN SORULARI İYİCE ANLAYIP CEVAP VER. ALAKASIZ CEVAPLAR VERME, GEREKSİZ KONUŞMAYI UZATMA.
            
            Depremler, deprem güvenliği, deprem hazırlığı ve Türkiye'deki depremler hakkında doğru bilgiler ver. Bilimsel ve güncel bilgilere sadık kal.
            """
        )
        messages.append(systemMessage)
        notifyMessagesDidChange()
    }
}

struct MistralMessage: Identifiable {
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
