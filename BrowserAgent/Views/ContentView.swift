import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingAPIKeySheet = false
    @State private var showModelSelector = false
    
    var body: some View {
        NavigationSplitView {
            Sidebar(viewModel: viewModel, showModelSelector: $showModelSelector)
        } detail: {
            VStack(spacing: 0) {
                // Чат
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.messages) { message in
                                MessageView(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastMessage = viewModel.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                
                // Роздільник
                Divider()
                
                // Текстове поле для введення повідомлення
                HStack {
                    TextField("Ваше повідомлення...", text: $viewModel.inputMessage, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .frame(minHeight: 40)
                    
                    if viewModel.isLoading {
                        Button(action: viewModel.stopAgent) {
                            Image(systemName: "stop.circle.fill")
                                .foregroundColor(.red)
                                .font(.title)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: viewModel.sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.accentColor)
                                .font(.title)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem {
                    Button(action: { showingAPIKeySheet.toggle() }) {
                        Label("API Key", systemImage: "key.fill")
                    }
                }
                
                ToolbarItem {
                    Button(action: { showModelSelector.toggle() }) {
                        Label("AI Model", systemImage: "cube.box.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAPIKeySheet) {
                APIKeyView(viewModel: viewModel)
            }
        }
        .navigationTitle("Browser Agent")
    }
}

// MARK: - Message View
struct MessageView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding()
                    .background(message.role == .user ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(formattedTimestamp)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.role == .assistant {
                Spacer()
            }
        }
        .transition(.opacity)
    }
    
    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: message.timestamp)
    }
}

// MARK: - Sidebar
struct Sidebar: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var showModelSelector: Bool
    
    var body: some View {
        List {
            Section("AI Моделі") {
                ForEach(AIProvider.allCases) { provider in
                    DisclosureGroup(provider.rawValue) {
                        ForEach(provider.models) { model in
                            HStack {
                                Text(model.name)
                                Spacer()
                                if model == viewModel.selectedModel {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectedModel = model
                                viewModel.loadAPIKey()
                                showModelSelector = false
                            }
                        }
                    }
                }
            }
            
            Section("Статус") {
                HStack {
                    Image(systemName: viewModel.apiKey.isEmpty ? "xmark.circle" : "checkmark.circle")
                        .foregroundColor(viewModel.apiKey.isEmpty ? .red : .green)
                    Text("API Key")
                }
                
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("Browser Use")
                }
                
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("Patchright")
                }
            }
        }
        .listStyle(.sidebar)
    }
}

// MARK: - API Key View
struct APIKeyView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss
    @State private var tempApiKey: String = ""
    @State private var isValidatingKey: Bool = false
    @State private var isCheckingStatus: Bool = false
    @State private var validationResult: String? = nil
    @State private var apiStatus: String? = nil
    @State private var errorDetails: String? = nil
    
    var body: some View {
        VStack(spacing: 15) {
            Text("API Key для \(viewModel.selectedModel.provider.rawValue)")
                .font(.headline)
            
            SecureField("Введіть API Key", text: $tempApiKey)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            HStack(spacing: 10) {
                Button("Перевірити") {
                    validateApiKey()
                }
                .buttonStyle(.bordered)
                .disabled(tempApiKey.isEmpty || isValidatingKey || isCheckingStatus)
            }
            
            if isValidatingKey || isCheckingStatus {
                ProgressView()
                    .padding()
            }
            
            if let result = validationResult {
                Text(result)
                    .foregroundColor(result.contains("успішно") ? .green : .red)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            HStack {
                Button("Скасувати") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Зберегти") {
                    viewModel.apiKey = tempApiKey
                    viewModel.saveAPIKey()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(tempApiKey.isEmpty || isValidatingKey || isCheckingStatus)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 400, height: 300)
        .onAppear {
            tempApiKey = viewModel.apiKey
        }
    }
    
    private func validateApiKey() {
        isValidatingKey = true
        validationResult = nil
        errorDetails = nil
        
        // Зберігаємо поточне значення API ключа
        let previousKey = viewModel.apiKey
        
        // Тимчасово встановлюємо новий API ключ для валідації
        viewModel.apiKey = tempApiKey
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Виконуємо перевірку ключа
            let testCode = """
            import os
            import json
            import sys
            
            api_key = r"\(tempApiKey)".strip()
            
            if not api_key or len(api_key) < 20:
                print(f"ERROR: API ключ закороткий або порожній. Довжина: {len(api_key)}")
                exit(1)
            
            if not api_key.startswith('sk-'):
                print(f"ERROR: API ключ має неправильний формат. Ключ має починатись з 'sk-'")
                print(f"Початок ключа: {api_key[:5]}...")
                exit(1)
            
            try:
                from langchain_openai import ChatOpenAI
                
                # Перевіряємо наявність зайвих символів
                cleaned_key = api_key.strip()
                if cleaned_key != api_key:
                    print(f"WARNING: API ключ містить зайві пробіли")
                    api_key = cleaned_key
                
                print(f"DEBUG: Довжина ключа: {len(api_key)}, Початок: {api_key[:5]}...")
                llm = ChatOpenAI(model="gpt-3.5-turbo", api_key=api_key)
                response = llm.invoke("Say test")
                print("SUCCESS: API ключ працює")
                exit(0)
            except Exception as e:
                error_str = str(e)
                print(f"ERROR: {error_str}")
                
                # Більш детальна діагностика
                if "Incorrect API key" in error_str:
                    print("HINT: Ключ має неправильний формат або був відкликаний")
                elif "exceeded" in error_str and "quota" in error_str:
                    print("HINT: Закінчилися кошти на рахунку OpenAI")
                elif "rate limit" in error_str:
                    print("HINT: Перевищено ліміт запитів до API")
                    
                exit(1)
            """
            
            let pythonBridge = PythonBridge.shared
            let result = pythonBridge.runPythonCode(code: testCode)
            
            DispatchQueue.main.async {
                if result.contains("SUCCESS: API ключ працює") {
                    validationResult = "✅ API ключ перевірено успішно!"
                } else {
                    validationResult = "❌ API ключ недійсний"
                    errorDetails = result.replacingOccurrences(of: "ERROR: ", with: "")
                    
                    // Показуємо підказки, якщо вони є
                    if result.contains("HINT:") {
                        let hintStart = result.range(of: "HINT:")?.upperBound
                        if let start = hintStart {
                            let hintText = String(result[start...]).trimmingCharacters(in: .whitespacesAndNewlines)
                            validationResult = "❌ API ключ недійсний: \(hintText)"
                        }
                    }
                    
                    // Показуємо інформацію про відладку, якщо вона є
                    if result.contains("DEBUG:") {
                        print("Debug info: \(result)")
                    }
                }
                
                // Повертаємо попереднє значення API ключа
                viewModel.apiKey = previousKey
                isValidatingKey = false
            }
        }
    }
    
    private func checkAPIStatus() {
        guard !tempApiKey.isEmpty else { return }
        
        isCheckingStatus = true
        apiStatus = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            let browserUseManager = BrowserUseManager()
            let result = browserUseManager.checkOpenAIAPIStatus(apiKey: tempApiKey)
            
            DispatchQueue.main.async {
                apiStatus = result
                isCheckingStatus = false
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 