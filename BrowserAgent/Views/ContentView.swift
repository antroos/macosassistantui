import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Заголовок чату
                headerView
                
                // Розділювач
                Divider()
                    .background(Color.primary.opacity(0.2))
                
                // Чат або стартовий екран
                if viewModel.messages.isEmpty {
                    emptyStateView
                } else {
                    chatScrollView
                }
                
                // Розділювач
                Divider()
                    .background(Color.primary.opacity(0.2))
                
                // Поле вводу
                messageInputBar
            }
        }
        .alert(item: alertBinding) { alertInfo in
            Alert(
                title: Text(alertInfo.title),
                message: Text(alertInfo.message),
                dismissButton: .default(Text("OK")) {
                    viewModel.error = nil
                }
            )
        }
    }
    
    // Фоновий градієнт
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(
                colors: colorScheme == .dark 
                    ? [Color(red: 0.18, green: 0.18, blue: 0.20), Color(red: 0.12, green: 0.12, blue: 0.14)]
                    : [Color(red: 0.95, green: 0.95, blue: 0.97), Color(red: 0.92, green: 0.92, blue: 0.94)]
            ),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // Заголовок чату
    private var headerView: some View {
        HStack {
            Text("AI Асистент")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: { /* Можливі налаштування */ }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary.opacity(0.7))
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // Стартовий екран, коли чат порожній
    private var emptyStateView: some View {
        ScrollView {
            VStack {
                Spacer(minLength: 60)
                
                // Заголовок
                emptyStateHeader
                
                // Поле вводу
                emptyStateInputField
                
                // Пропозиції
                emptyStateSuggestions
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .background(colorScheme == .dark ? Color.black.opacity(0.1) : Color.white.opacity(0.3))
    }
    
    // Заголовок для порожнього стану
    private var emptyStateHeader: some View {
        Text("З чого почнемо?")
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .foregroundColor(.primary)
            .multilineTextAlignment(.center)
            .padding(.bottom, 50)
    }
    
    // Поле вводу для порожнього стану
    private var emptyStateInputField: some View {
        HStack(spacing: 16) {
            // Текстове поле
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white)
                )
                .frame(height: 54)
                .overlay(
                    HStack {
                        Text("Запитайте що завгодно")
                            .foregroundColor(.gray)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .padding(.leading, 16)
                        Spacer()
                    }
                )
            
            // Кнопка мікрофона
            Circle()
                .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                )
        }
        .padding(.bottom, 30)
    }
    
    // Секція пропозицій для порожнього стану
    private var emptyStateSuggestions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Спробуйте:")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            suggestionButton("Відкрий Google та знайди відгуки про iPhone 15")
            suggestionButton("Зайди на сайт Wikipedia і знайди інформацію про Київ")
            suggestionButton("Знайди розклад кінотеатрів у моєму місті")
        }
    }
    
    // Кнопка з пропозицією запиту
    private func suggestionButton(_ text: String) -> some View {
        Button(action: {
            viewModel.inputMessage = text
            viewModel.sendMessage()
        }) {
            Text(text)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.primary)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
                        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                )
        }
    }
    
    // Прокручуваний чат
    private var chatScrollView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        chatBubble(for: message)
                            .id(message.id)
                    }
                    
                    // Активний індикатор завантаження
                    if viewModel.isLoading {
                        loadingIndicator
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .animation(.easeOut(duration: 0.2), value: viewModel.messages.count)
            }
            .onChange(of: viewModel.messages.count) { oldCount, newCount in
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(colorScheme == .dark ? Color.black.opacity(0.1) : Color.white.opacity(0.3))
    }
    
    // Чат бульбашка
    private func chatBubble(for message: Message) -> some View {
        HStack {
            if message.role == .assistant {
                assistantAvatar
                bubbleContent(for: message)
                Spacer(minLength: 64)
            } else {
                Spacer(minLength: 64)
                bubbleContent(for: message)
                userAvatar
            }
        }
    }
    
    // Аватар асистента
    private var assistantAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
            
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    // Аватар користувача
    private var userAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.green, .teal]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
            
            Image(systemName: "person.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    // Вміст бульбашки
    private func bubbleContent(for message: Message) -> some View {
        Text(message.content)
            .font(.system(size: 15, weight: .regular, design: .rounded))
            .foregroundColor(message.role == .user ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        message.role == .user
                        ? LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                        : LinearGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1),
                                colorScheme == .dark ? Color.gray.opacity(0.25) : Color.gray.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // Індикатор завантаження
    private var loadingIndicator: some View {
        HStack {
            assistantAvatar
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .scaleEffect(viewModel.isLoading ? 1.0 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 0.4)
                                .repeatForever()
                                .delay(0.2 * Double(index)),
                            value: viewModel.isLoading
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark 
                          ? Color.gray.opacity(0.3) 
                          : Color.gray.opacity(0.1))
            )
            
            Spacer(minLength: 64)
        }
    }
    
    // Панель вводу повідомлень
    private var messageInputBar: some View {
        HStack(spacing: 12) {
            // Поле вводу
            ZStack(alignment: .trailing) {
                TextField("Напишіть повідомлення...", text: $viewModel.inputMessage)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .padding(.trailing, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(colorScheme == .dark
                                  ? Color.gray.opacity(0.3)
                                  : Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .accentColor(.clear)
                    .tint(.gray)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        if !viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            viewModel.sendMessage()
                        }
                    }
                    .submitLabel(.send)
                
                // Кнопка очищення
                if !viewModel.inputMessage.isEmpty {
                    Button(action: {
                        viewModel.inputMessage = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing, 12)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            
            // Кнопка відправки
            Button(action: {
                withAnimation {
                    viewModel.sendMessage()
                }
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            .disabled(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && viewModel.isLoading)
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // Обгортка для показу сповіщень про помилки
    private var alertBinding: Binding<AlertInfo?> {
        Binding<AlertInfo?>(
            get: {
                if let error = viewModel.error {
                    return AlertInfo(title: "Помилка", message: error)
                }
                return nil
            },
            set: { _ in viewModel.error = nil }
        )
    }
}

// Модель для відображення сповіщень
struct AlertInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .preferredColorScheme(.light)
            
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
} 