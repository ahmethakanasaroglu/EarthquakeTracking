import Foundation
import Combine

class MistralManager: ObservableObject {
    @Published var messages: [MistralMessage] = []
    @Published var isTyping: Bool = false
    @Published var error: String? = nil
    
    // Ollama API endpoint'i (yerel kurulum için)
    private let baseURL = "http://localhost:11434/api/chat"
    private let modelName = "mistral"
    
    init() {
        // Başlangıç sistem mesajı - Türkçe çıktıyı optimize eden sistem talimatı
        let systemMessage = MistralMessage(
            role: .system,
            content: """
            Sen deprem uzmanı bir Türkçe dijital asistansın.
            
            TALİMATLAR:
            - HER ZAMAN ve SADECE Türkçe dilinde yanıt ver.
            - Akıcı ve doğru Türkçe kullan, çeviri gibi görünmeyen doğal cümleler kur.
            - Yanıtların 6-7 kısa ve net cümleden oluşsun.
            - Cümleler arasında mantıksal bağlantı olsun, bütünlük içinde olsun.
            - Teknik bilgileri basit ve anlaşılır Türkçe ile açıkla.
            - İngilizce kelime veya ifadeler KULLANMA.
            
            Depremler, deprem güvenliği, deprem hazırlığı ve Türkiye'deki depremler hakkında doğru bilgiler ver. Bilimsel ve güncel bilgilere sadık kal.
            """
        )
        messages.append(systemMessage)
    }
    
    func sendMessage(_ userMessage: String) {
        // Kullanıcı mesajını ekle
        let newUserMessage = MistralMessage(role: .user, content: userMessage)
        messages.append(newUserMessage)
        
        // AI'ın yanıt verdiğini göstermek için
        isTyping = true
        
        // Mesaj geçmişini oluştur
        var historyMessages: [[String: String]] = []
        for message in messages {
            historyMessages.append([
                "role": message.role.rawValue,
                "content": message.content
            ])
        }
        
        // Daha iyi Türkçe cevaplar için kullanıcı mesajını yönlendirelim
        let userInstruction = """
            Soru: \(userMessage)
            
            Lütfen bu soruya SADECE TÜRKÇE olarak, 6-7 cümleyle kısa ve öz yanıt ver. 
            Cümleler dilbilgisi açısından doğru, anlamlı ve bağlantılı olmalı.
            Kesinlikle İngilizce kelime kullanma.
            """
        
        historyMessages[historyMessages.count - 1]["content"] = userInstruction
        
        // API isteği için gerekli verileri oluştur
        let requestBody: [String: Any] = [
            "model": modelName,
            "messages": historyMessages,
            "stream": false,
            "options": [
                "temperature": 0.3,    // Daha tutarlı cevaplar için düşük değer
                "max_tokens": 120,     // Kısa cevaplar için
                "top_p": 0.7,          // Daha az rastgelelik
                "stop": ["English:", "İngilizce:"]  // İngilizce yanıtları durdur
            ]
        ]
        
        // API çağrısını gerçekleştir
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
        request.timeoutInterval = 30 // 30 saniyelik timeout
        
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
                
                // Hata kontrolü
                if let error = error {
                    self.handleError("Bağlantı hatası: \(error.localizedDescription)")
                    return
                }
                
                // Veri kontrolü
                guard let data = data else {
                    self.handleError("Veri alınamadı")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        // Hata kontrolü
                        if let errorMessage = json["error"] as? String {
                            self.handleError("Yapay zeka hatası")
                            return
                        }
                        
                        // Yanıt mesajını al
                        if let message = json["message"] as? [String: Any],
                           let content = message["content"] as? String {
                            
                            // Cevabı işle ve düzelt
                            let processedContent = self.processTurkishResponse(content)
                            let assistantMessage = MistralMessage(role: .assistant, content: processedContent)
                            self.messages.append(assistantMessage)
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
    
    // Türkçe yanıtları iyileştirme ve düzenleme
    private func processTurkishResponse(_ content: String) -> String {
        var result = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // "Türkçe:" veya "Turkish:" gibi başlangıçları kaldır
        if result.lowercased().hasPrefix("türkçe:") {
            result = String(result.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if result.lowercased().hasPrefix("turkish:") {
            result = String(result.dropFirst(8)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // İngilizce kelimeleri ve kısımları temizleme (basit bir yaklaşım)
        let lines = result.components(separatedBy: "\n")
        var cleanedLines: [String] = []
        
        for line in lines {
            // İngilizce satırları atla
            if line.range(of: "\\b[a-zA-Z]{4,}\\b", options: .regularExpression) != nil &&
               line.range(of: "[çğıöşüÇĞİÖŞÜ]", options: .regularExpression) == nil {
                continue
            }
            cleanedLines.append(line)
        }
        
        result = cleanedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Çok uzun cevapları kısalt
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
        
        // Noktalama ve boşluk düzeltmeleri
        result = result.replacingOccurrences(of: " ,", with: ",")
        result = result.replacingOccurrences(of: " .", with: ".")
        result = result.replacingOccurrences(of: "..", with: ".")
        result = result.replacingOccurrences(of: "  ", with: " ")
        
        return result
    }
    
    private func handleError(_ message: String) {
        error = message
        isTyping = false
        
        // Kullanıcıya dostane hata mesajı göster
        let errorMessage = MistralMessage(
            role: .assistant,
            content: "Üzgünüm, şu anda yanıt veremiyorum. Lütfen internet bağlantınızı ve Mistral modelinin çalıştığını kontrol edin."
        )
        messages.append(errorMessage)
    }
    
    func clearConversation() {
        messages.removeAll()
        
        // Sistem mesajını tekrar ekle
        let systemMessage = MistralMessage(
            role: .system,
            content: """
            Sen deprem uzmanı bir Türkçe dijital asistansın.
            
            TALİMATLAR:
            - HER ZAMAN ve SADECE Türkçe dilinde yanıt ver.
            - Akıcı ve doğru Türkçe kullan, çeviri gibi görünmeyen doğal cümleler kur.
            - Yanıtların 6-7 kısa ve net cümleden oluşsun.
            - Cümleler arasında mantıksal bağlantı olsun, bütünlük içinde olsun.
            - Teknik bilgileri basit ve anlaşılır Türkçe ile açıkla.
            - İngilizce kelime veya ifadeler KULLANMA.
            
            Depremler, deprem güvenliği, deprem hazırlığı ve Türkiye'deki depremler hakkında doğru bilgiler ver. Bilimsel ve güncel bilgilere sadık kal.
            """
        )
        messages.append(systemMessage)
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
