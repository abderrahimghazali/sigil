import Foundation

enum CredentialKind: String, Codable, CaseIterable, Identifiable {
    case password
    case apiToken
    case accessToken
    case secret

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .password: return "Password"
        case .apiToken: return "API Token"
        case .accessToken: return "Access Token"
        case .secret: return "Secret"
        }
    }

    var shortName: String {
        switch self {
        case .password: return "Password"
        case .apiToken: return "API"
        case .accessToken: return "Access"
        case .secret: return "Secret"
        }
    }

    var servicePlaceholder: String {
        switch self {
        case .password: return "GitHub, Google, AWS..."
        case .apiToken: return "OpenAI, Stripe, Resend..."
        case .accessToken: return "GitLab, GitHub, Linear..."
        case .secret: return "AWS, Vercel, Database..."
        }
    }

    var accountLabel: String {
        switch self {
        case .password: return "USERNAME"
        case .apiToken, .accessToken: return "ACCOUNT / OWNER"
        case .secret: return "NAME / ACCOUNT"
        }
    }

    var accountPlaceholder: String {
        switch self {
        case .password: return "user@example.com"
        case .apiToken: return "project, org, or user"
        case .accessToken: return "user, group, or project"
        case .secret: return "production, personal, team..."
        }
    }

    var secretLabel: String {
        switch self {
        case .password: return "PASSWORD"
        case .apiToken: return "API TOKEN"
        case .accessToken: return "ACCESS TOKEN"
        case .secret: return "SECRET"
        }
    }

    var secretPlaceholder: String {
        switch self {
        case .password: return "Password"
        case .apiToken: return "sk-..."
        case .accessToken: return "glpat-..."
        case .secret: return "Secret value"
        }
    }

    var copyTitle: String {
        switch self {
        case .password: return "Copy Password"
        case .apiToken: return "Copy API Token"
        case .accessToken: return "Copy Access Token"
        case .secret: return "Copy Secret"
        }
    }
}

struct Credential: Identifiable, Codable, Equatable {
    let id: UUID
    var kind: CredentialKind
    var service: String
    var username: String
    var url: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        kind: CredentialKind = .password,
        service: String,
        username: String,
        url: String = "",
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.service = service
        self.username = username
        self.url = url
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, kind, service, username, url, notes, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        kind = try container.decodeIfPresent(CredentialKind.self, forKey: .kind) ?? .password
        service = try container.decode(String.self, forKey: .service)
        username = try container.decode(String.self, forKey: .username)
        url = try container.decode(String.self, forKey: .url)
        notes = try container.decode(String.self, forKey: .notes)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
