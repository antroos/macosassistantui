import Foundation
import Combine

enum BrowserUseState {
    case idle
    case running
    case error(String)
}

class BrowserUseManager: ObservableObject {
    private let pythonBridge = PythonBridge.shared
    
    @Published var state: BrowserUseState = .idle
    @Published var isAgentRunning = false
    
    private var task: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    // Функція для перевірки балансу та лімітів OpenAI API
    func checkOpenAIAPIStatus(apiKey: String) -> String {
        let pythonCode = """
        import os
        import json
        import sys
        
        try:
            from openai import OpenAI
            
            api_key = "\(apiKey)"
            if not api_key:
                print("API ключ не вказано")
                exit(1)
            
            client = OpenAI(api_key=api_key)
            
            try:
                # Перевірка доступу до моделей
                models = client.models.list()
                model_count = len(models.data)
                
                # Перевірка лімітів та балансу (якщо можливо)
                # На жаль, OpenAI API не надає прямого доступу до інформації про баланс
                
                # Створюємо повідомлення про успіх
                result = f"✅ API ключ працює!\\n"
                result += f"Доступно {model_count} моделей\\n"
                
                # Список доступних моделей GPT
                gpt_models = [model.id for model in models.data if "gpt" in model.id.lower()]
                gpt_models = sorted(gpt_models)
                result += f"\\nДоступні моделі GPT:\\n"
                for model in gpt_models[:10]:  # Обмежуємо список до 10 моделей
                    result += f"• {model}\\n"
                
                if len(gpt_models) > 10:
                    result += f"...та ще {len(gpt_models) - 10} моделей\\n"
                
                print(result)
                exit(0)
            except Exception as e:
                error_message = str(e)
                print(f"❌ Помилка при перевірці API: {error_message}")
                exit(1)
        except ImportError as e:
            print(f"❌ Помилка імпорту модуля: {str(e)}")
            exit(1)
        """
        
        let result = pythonBridge.runPythonCode(code: pythonCode)
        
        return result
    }
    
    // Функція для тестування підключення Python та API ключа
    func testPythonConnection() -> String {
        let testCode = """
        import sys
        import os
        
        print(f"Python version: {sys.version}")
        
        try:
            import browser_use
            print(f"browser-use: Успішно імпортовано, версія {browser_use.__version__}")
            
            # Тестуємо OpenAI API ключ
            from langchain_openai import ChatOpenAI
            api_key = os.environ.get("OPENAI_API_KEY", "")
            if api_key:
                print(f"OpenAI API Key: {api_key[:5]}...{api_key[-5:]}")
                try:
                    llm = ChatOpenAI(model="gpt-3.5-turbo", api_key=api_key)
                    response = llm.invoke("Say hello")
                    print(f"OpenAI API тест: успішно - {response.content[:30]}...")
                except Exception as e:
                    print(f"OpenAI API тест: помилка - {e}")
            else:
                print("OpenAI API Key не встановлено")
        except ImportError as e:
            print(f"browser-use: Помилка імпорту - {e}")
            
        try:
            import patchright
            print(f"patchright: Успішно імпортовано")
        except ImportError as e:
            print(f"patchright: Помилка імпорту - {e}")
            
        print("Тест завершено")
        """
        
        return pythonBridge.runPythonCode(code: testCode)
    }
    
    func runAgent(task: String, model: AIModel, apiKey: String, messages: [Message]) {
        guard !isAgentRunning else { return }
        
        isAgentRunning = true
        state = .running
        
        // Створюємо Python код для запуску агента
        let pythonCode = generatePythonCode(task: task, model: model, apiKey: apiKey, messages: messages)
        
        // В реальній реалізації тут буде асинхронний запуск Python коду
        self.task = Task {
            do {
                // Імітуємо виконання
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 секунди
                
                // Реальна реалізація викликатиме PythonBridge.runPythonCode
                _ = pythonBridge.runPythonCode(code: pythonCode)
                
                await MainActor.run {
                    self.isAgentRunning = false
                    self.state = .idle
                }
            } catch {
                await MainActor.run {
                    self.isAgentRunning = false
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
    
    func stopAgent() {
        task?.cancel()
        isAgentRunning = false
        state = .idle
    }
    
    private func generatePythonCode(task: String, model: AIModel, apiKey: String, messages: [Message]) -> String {
        // Генеруємо Python код для запуску browser-use агента
        // і забезпечуємо правильне встановлення API ключа
        
        var code = """
        from langchain_openai import ChatOpenAI
        from browser_use import Agent
        import asyncio
        import os
        
        # Явно встановлюємо API ключ
        api_key = "\(apiKey)"
        os.environ["\(model.provider.envVariableName)"] = api_key
        
        async def main():
            try:
                # Явно передаємо API ключ в конструктор ChatOpenAI
                llm = ChatOpenAI(model="\(model.id)", api_key=api_key)
                
                # Створюємо агента
                agent = Agent(
                    task="\(task)",
                    llm=llm,
                )
                
                # Запускаємо агента
                await agent.run()
            except Exception as e:
                print(f"Помилка: {e}")
        
        asyncio.run(main())
        """
        
        return code
    }
} 