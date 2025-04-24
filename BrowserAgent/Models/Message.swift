import Foundation

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

struct Message: Identifiable, Codable, Equatable {
    var id = UUID()
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    init(role: MessageRole, content: String, timestamp: Date = Date()) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id &&
               lhs.role == rhs.role &&
               lhs.content == rhs.content &&
               lhs.timestamp == rhs.timestamp
    }
}

// Для демонстрації у UI
extension Message {
    static let sampleMessages = [
        Message(role: .user, content: "Привіт! Я хочу зайти на сайт Google і знайти інформацію про iPhone 15."),
        Message(role: .assistant, content: "Привіт! Я допоможу вам знайти інформацію про iPhone 15 на Google. Давайте я відкрию браузер і виконаю пошук для вас."),
        Message(role: .user, content: "Чудово, дякую!"),
    ]
} 