import Foundation

struct CredentialExportBundle: Codable {
    let version: Int
    let exportedAt: Date
    let credentials: [CredentialExportItem]

    init(version: Int = 1, exportedAt: Date = Date(), credentials: [CredentialExportItem]) {
        self.version = version
        self.exportedAt = exportedAt
        self.credentials = credentials
    }
}

struct CredentialExportItem: Codable {
    let id: UUID
    let kind: CredentialKind
    let service: String
    let username: String
    let url: String
    let notes: String
    let createdAt: Date
    let updatedAt: Date
    let secret: String

    init(credential: Credential, secret: String) {
        id = credential.id
        kind = credential.kind
        service = credential.service
        username = credential.username
        url = credential.url
        notes = credential.notes
        createdAt = credential.createdAt
        updatedAt = credential.updatedAt
        self.secret = secret
    }

    var credential: Credential {
        Credential(
            id: id,
            kind: kind,
            service: service,
            username: username,
            url: url,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct CredentialImportSummary {
    let added: Int
    let updated: Int

    var total: Int { added + updated }
}

enum CredentialImportError: LocalizedError {
    case emptyImport
    case unsupportedVersion(Int)
    case emptySecret(String)

    var errorDescription: String? {
        switch self {
        case .emptyImport:
            return "Import file does not contain any credentials"
        case .unsupportedVersion(let version):
            return "Unsupported Sigil export version \(version)"
        case .emptySecret(let service):
            return "\(service) is missing its secret value"
        }
    }
}
