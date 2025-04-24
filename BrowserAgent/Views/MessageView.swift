import SwiftUI

struct MessageView: View {
    let message: Message
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            if message.role == .assistant {
                assistantAvatar
                bubbleContent
                Spacer(minLength: 64)
            } else {
                Spacer(minLength: 64)
                bubbleContent
                userAvatar
            }
        }
        .padding(.horizontal, 8)
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
    private var bubbleContent: some View {
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
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                MessageView(message: Message(role: .user, content: "Привіт! Як справи?"))
                MessageView(message: Message(role: .assistant, content: "Все чудово, дякую за запитання! Чим можу допомогти сьогодні?"))
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.light)
            
            VStack {
                MessageView(message: Message(role: .user, content: "Привіт! Як справи?"))
                MessageView(message: Message(role: .assistant, content: "Все чудово, дякую за запитання! Чим можу допомогти сьогодні?"))
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
        }
    }
} 