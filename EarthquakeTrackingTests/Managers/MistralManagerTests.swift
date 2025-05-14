import XCTest
import Foundation
@testable import EarthquakeTracking

class MistralManagerTests: XCTestCase {
    
    var mistralManager: MistralManager!
    var notificationCenter: NotificationCenter!
    
    override func setUp() {
        super.setUp()
        mistralManager = MistralManager()
        notificationCenter = NotificationCenter.default
    }
    
    override func tearDown() {
        mistralManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests

    func testInitialization() {
        // Given - Manager oluşturulduğunda
        let newManager = MistralManager()
        
        // Then - İlk durumları kontrol et
        XCTAssertEqual(newManager.messages.count, 1, "İlk sistemsel mesaj olmalı")
        XCTAssertEqual(newManager.messages.first?.role, .system)
        XCTAssertFalse(newManager.isTyping)
        XCTAssertNil(newManager.error)
    }
    
    func testInitialSystemMessage() {
        // Given
        let systemMessage = mistralManager.messages.first
        
        // Then
        XCTAssertNotNil(systemMessage)
        XCTAssertEqual(systemMessage?.role, .system)
        XCTAssertTrue(((systemMessage?.content.contains("Sen deprem uzmanı bir Türkçe dijital asistansın.")) != nil))
    }
    
    // MARK: - Message Handling Tests
    
    func testSendMessage() {
        // Given
        let userMessage = "Deprem nedir?"
        let expectation = XCTestExpectation(description: "Message sent notification")
        
        // When
        var notificationReceived = false
        let observer = notificationCenter.addObserver(
            forName: MistralManager.messagesDidChangeNotification,
            object: mistralManager,
            queue: .main
        ) { _ in
            notificationReceived = true
            expectation.fulfill()
        }
        
        mistralManager.sendMessage(userMessage)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(notificationReceived)
        XCTAssertEqual(mistralManager.messages.count, 2) // System + User message
        XCTAssertEqual(mistralManager.messages.last?.content, userMessage)
        XCTAssertEqual(mistralManager.messages.last?.role, .user)
        
        notificationCenter.removeObserver(observer)
    }
    
    func testTypingStatusChangedOnSendMessage() {
        // Given
        let expectation = XCTestExpectation(description: "Typing status changed")
        
        // When
        var notificationReceived = false
        let observer = notificationCenter.addObserver(
            forName: MistralManager.typingStatusDidChangeNotification,
            object: mistralManager,
            queue: .main
        ) { _ in
            notificationReceived = true
            expectation.fulfill()
        }
        
        mistralManager.sendMessage("Test message")
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(notificationReceived)
        XCTAssertTrue(mistralManager.isTyping)
        
        notificationCenter.removeObserver(observer)
    }
    
    // MARK: - Error Handling Tests
    
    func testHandleError() {
        // Given
        let errorMessage = "Test error message"
        let expectation = XCTestExpectation(description: "Error notification")
        
        // When
        var errorReceived: String?
        let observer = notificationCenter.addObserver(
            forName: MistralManager.errorDidChangeNotification,
            object: mistralManager,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let error = userInfo["error"] as? String {
                errorReceived = error
            }
            expectation.fulfill()
        }
        
        mistralManager.error = errorMessage
        mistralManager.notifyErrorDidChange()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(errorReceived, errorMessage)
        XCTAssertEqual(mistralManager.error, errorMessage)
        
        notificationCenter.removeObserver(observer)
    }
    
    // MARK: - Response Processing Tests
    
    func testProcessTurkishResponseWithPrefix() {
        // Given
        let contentWithPrefix = "Türkçe: Bu bir test mesajıdır."
        
        // When
        let result = mistralManager.processTurkishResponse(contentWithPrefix)
        
        // Then
        XCTAssertEqual(result, "Bu bir test mesajıdır.")
        XCTAssertFalse(result.contains("Türkçe:"))
    }
    
    func testProcessTurkishResponseWithEnglishPrefix() {
        // Given
        let contentWithPrefix = "Turkish: Bu Türkçe bir mesajdır."
        
        // When
        let result = mistralManager.processTurkishResponse(contentWithPrefix)
        
        // Then
        XCTAssertEqual(result, "Bu Türkçe bir mesajdır.")
        XCTAssertFalse(result.contains("Turkish:"))
    }
    
    func testProcessTurkishResponseRemovesEnglishLines() {
        // Given
        let content = """
        Bu bir Türkçe cümle.
        This is an English sentence.
        Diğer bir Türkçe cümle.
        """
        
        // When
        let result = mistralManager.processTurkishResponse(content)
        
        // Then
        XCTAssertTrue(result.contains("Bu bir Türkçe cümle."))
        XCTAssertTrue(result.contains("Diğer bir Türkçe cümle."))
        XCTAssertFalse(result.contains("This is an English sentence."))
    }
    
    func testProcessTurkishResponseLimitsLength() {
        // Given
        let longContent = String(repeating: "Bu çok uzun bir cümle. ", count: 50)
        
        // When
        let result = mistralManager.processTurkishResponse(longContent)
        
        // Then
        XCTAssertLessThanOrEqual(result.count, 200)
        XCTAssertTrue(result.contains("Bu çok uzun bir cümle."))
    }
    
    func testProcessTurkishResponseFixesFormatting() {
        // Given
        let messyContent = "Test  mesaj , formatı . bozuk.."
        
        // When
        let result = mistralManager.processTurkishResponse(messyContent)
        
        // Then
        XCTAssertEqual(result, "Test mesaj, formatı. bozuk.")
        XCTAssertFalse(result.contains("  "))
        XCTAssertFalse(result.contains(" ,"))
        XCTAssertFalse(result.contains(" ."))
        XCTAssertFalse(result.contains(".."))
    }
    
    // MARK: - Clear Conversation Tests
    
    func testClearConversation() {
        // Given
        mistralManager.sendMessage("Test message")
        XCTAssertGreaterThan(mistralManager.messages.count, 1)
        
        let expectation = XCTestExpectation(description: "Messages cleared notification")
        
        // When
        var notificationReceived = false
        let observer = notificationCenter.addObserver(
            forName: MistralManager.messagesDidChangeNotification,
            object: mistralManager,
            queue: .main
        ) { _ in
            notificationReceived = true
            expectation.fulfill()
        }
        
        mistralManager.clearConversation()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(notificationReceived)
        XCTAssertEqual(mistralManager.messages.count, 1)
        XCTAssertEqual(mistralManager.messages.first?.role, .system)
        
        notificationCenter.removeObserver(observer)
    }
    
    // MARK: - Notification Tests
    
    func testNotificationNames() {
        // Then
        XCTAssertEqual(
            MistralManager.messagesDidChangeNotification.rawValue,
            "MessagesDidChangeNotification"
        )
        XCTAssertEqual(
            MistralManager.typingStatusDidChangeNotification.rawValue,
            "TypingStatusDidChangeNotification"
        )
        XCTAssertEqual(
            MistralManager.errorDidChangeNotification.rawValue,
            "ErrorDidChangeNotification"
        )
    }
    
    // MARK: - MistralMessage Tests
    
    func testMistralMessageCreation() {
        // Given & When
        let message = MistralMessage(role: .user, content: "Test content")
        
        // Then
        XCTAssertNotNil(message.id)
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "Test content")
        XCTAssertNotNil(message.timestamp)
    }
    
    func testMessageRoleRawValues() {
        // Then
        XCTAssertEqual(MessageRole.user.rawValue, "user")
        XCTAssertEqual(MessageRole.assistant.rawValue, "assistant")
        XCTAssertEqual(MessageRole.system.rawValue, "system")
    }
    
    // MARK: - Network Error Simulation Tests
    
    func testErrorHandling() {
        // Given
        let errorMessage = "Test network error"
        
        // When
        mistralManager.handleError(errorMessage)
        
        // Then
        XCTAssertEqual(mistralManager.error, errorMessage)
        XCTAssertFalse(mistralManager.isTyping)
        XCTAssertGreaterThan(mistralManager.messages.count, 1)
        
        let lastMessage = mistralManager.messages.last
        XCTAssertEqual(lastMessage?.role, .assistant)
        XCTAssertTrue(((lastMessage?.content.contains("Üzgünüm")) != nil))
    }
}
