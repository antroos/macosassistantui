import Foundation

enum AIProvider: String, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case deepSeek = "DeepSeek"
    case gemini = "Google Gemini"
    case grok = "Grok"
    case novita = "Novita"
    
    var id: String { self.rawValue }
    
    var models: [AIModel] {
        switch self {
        case .openAI:
            return [
                AIModel(id: "gpt-4o", name: "GPT-4o", provider: self),
                AIModel(id: "gpt-4", name: "GPT-4", provider: self),
                AIModel(id: "gpt-3.5-turbo", name: "GPT-3.5 Turbo", provider: self)
            ]
        case .anthropic:
            return [
                AIModel(id: "claude-3-opus", name: "Claude 3 Opus", provider: self),
                AIModel(id: "claude-3-sonnet", name: "Claude 3 Sonnet", provider: self),
                AIModel(id: "claude-3-haiku", name: "Claude 3 Haiku", provider: self)
            ]
        case .deepSeek:
            return [
                AIModel(id: "deepseek-v3", name: "DeepSeek V3", provider: self)
            ]
        case .gemini:
            return [
                AIModel(id: "gemini-pro", name: "Gemini Pro", provider: self),
                AIModel(id: "gemini-ultra", name: "Gemini Ultra", provider: self)
            ]
        case .grok:
            return [
                AIModel(id: "grok-1", name: "Grok 1", provider: self)
            ]
        case .novita:
            return [
                AIModel(id: "novita-v1", name: "Novita V1", provider: self)
            ]
        }
    }
    
    var envVariableName: String {
        switch self {
        case .openAI: return "OPENAI_API_KEY"
        case .anthropic: return "ANTHROPIC_API_KEY"
        case .deepSeek: return "DEEPSEEK_API_KEY"
        case .gemini: return "GEMINI_API_KEY"
        case .grok: return "GROK_API_KEY"
        case .novita: return "NOVITA_API_KEY"
        }
    }
}

struct AIModel: Identifiable {
    let id: String
    let name: String
    let provider: AIProvider
    
    static var defaultModel: AIModel {
        AIProvider.openAI.models.first!
    }
}

extension AIModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(provider.rawValue)
    }
}

extension AIModel: Equatable {
    static func == (lhs: AIModel, rhs: AIModel) -> Bool {
        return lhs.id == rhs.id && lhs.provider == rhs.provider
    }
} 