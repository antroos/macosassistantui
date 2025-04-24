import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var selectedModel: AIModel = AIModel.defaultModel
    @Published var apiKey: String = ""
    
    private let browserUseManager = BrowserUseManager()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Демо повідомлення для тестування
        #if DEBUG
        messages = Message.sampleMessages
        #endif
        
        // Підписуємось на зміни стану браузерного агента
        browserUseManager.$isAgentRunning
            .sink { [weak self] isRunning in
                self?.isLoading = isRunning
            }
            .store(in: &cancellables)
        
        browserUseManager.$state
            .sink { [weak self] state in
                if case let .error(message) = state {
                    self?.error = message
                }
            }
            .store(in: &cancellables)
        
        // Завантажуємо ключ API з UserDefaults, якщо він є
        loadAPIKey()
    }
    
    // Функція для тестування підключення Python
    func testPythonConnection() {
        isLoading = true
        
        // Перевіряємо, чи є API ключ
        if apiKey.isEmpty {
            isLoading = false
            let message = Message(role: .assistant, content: "⚠️ Не встановлено API ключ. Будь ласка, встановіть API ключ перед виконанням тесту.")
            messages.append(message)
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = self?.browserUseManager.testPythonConnection() ?? "Помилка тестування"
            
            DispatchQueue.main.async {
                self?.isLoading = false
                let message = Message(role: .assistant, content: "Результат тесту Python:\n\n\(result)")
                self?.messages.append(message)
            }
        }
    }
    
    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(role: .user, content: inputMessage)
        messages.append(userMessage)
        
        let storedInput = inputMessage
        inputMessage = ""
        
        // Перевіряємо, чи це команда для тестування Python або API ключа
        if storedInput.lowercased().contains("тест") && 
           (storedInput.lowercased().contains("python") || 
            storedInput.lowercased().contains("пайтон") || 
            storedInput.lowercased().contains("api") || 
            storedInput.lowercased().contains("key") || 
            storedInput.lowercased().contains("ключ")) {
            testPythonConnection()
            return
        }
        
        // Перевіряємо наявність API ключа
        if apiKey.isEmpty {
            let assistantMessage = Message(role: .assistant, content: "⚠️ Не встановлено API ключ. Будь ласка, натисніть на іконку ключа 🔑 у верхньому правому куті для встановлення API ключа.")
            messages.append(assistantMessage)
            return
        }
        
        // Визначаємо, чи потрібно виконувати дію в браузері або просто відповідати на повідомлення
        // У повній реалізації тут буде логіка аналізу повідомлення
        let isActionRequired = storedInput.lowercased().contains("відкрий") || 
                            storedInput.lowercased().contains("знайди") ||
                            storedInput.lowercased().contains("перейди")
        
        if isActionRequired && !browserUseManager.isAgentRunning {
            let assistantThinkingMessage = Message(role: .assistant, content: "Виконую завдання в браузері...")
            messages.append(assistantThinkingMessage)
            
            // Запускаємо browser-use агента
            browserUseManager.runAgent(
                task: storedInput,
                model: selectedModel,
                apiKey: apiKey,
                messages: Array(messages.dropLast())
            )
        } else {
            // В реальній реалізації тут буде виклик AI API для звичайної відповіді
            simulateAIResponse(to: storedInput)
        }
    }
    
    func stopAgent() {
        browserUseManager.stopAgent()
    }
    
    private func simulateAIResponse(to message: String) {
        isLoading = true
        
        // Імітуємо відповідь AI
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            let response: String
            if message.lowercased().contains("привіт") {
                response = "Привіт! Я ваш браузерний асистент. Чим можу допомогти сьогодні? Можу виконати дії в браузері за вашим запитом."
            } else {
                response = "Я зрозумів ваше повідомлення. Щоб я міг виконати дії в браузері, спробуйте використати команди типу 'відкрий', 'знайди' або 'перейди на сайт'."
            }
            
            let assistantMessage = Message(role: .assistant, content: response)
            self.messages.append(assistantMessage)
            self.isLoading = false
        }
    }
    
    // MARK: - API Key Management
    
    func saveAPIKey() {
        UserDefaults.standard.set(apiKey, forKey: "apiKey_\(selectedModel.provider.rawValue)")
    }
    
    func loadAPIKey() {
        if let savedKey = UserDefaults.standard.string(forKey: "apiKey_\(selectedModel.provider.rawValue)") {
            apiKey = savedKey
        }
    }
    
    func clearAPIKey() {
        apiKey = ""
        UserDefaults.standard.removeObject(forKey: "apiKey_\(selectedModel.provider.rawValue)")
    }
} 