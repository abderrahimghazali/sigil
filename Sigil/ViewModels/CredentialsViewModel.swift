import Foundation
import Combine

@MainActor
final class CredentialsViewModel: ObservableObject {
    @Published var credentials: [Credential] = []
    @Published var searchText = ""
    @Published var error: String?

    private let store = CredentialStore.shared

    var filteredCredentials: [Credential] {
        guard !searchText.isEmpty else { return credentials }
        let q = searchText.lowercased()
        return credentials.filter {
            $0.service.lowercased().contains(q) ||
            $0.username.lowercased().contains(q) ||
            $0.url.lowercased().contains(q) ||
            $0.kind.displayName.lowercased().contains(q)
        }
    }

    init() {
        credentials = store.loadCredentials().sorted { $0.service.lowercased() < $1.service.lowercased() }
    }

    func addCredential(kind: CredentialKind, service: String, username: String, secret: String, url: String = "", notes: String = "") throws {
        guard !secret.isEmpty else { throw ValidationError.emptySecret }

        let credential = Credential(kind: kind, service: service, username: username, url: url, notes: notes)
        try KeychainService.save(password: secret, for: credential.id)
        credentials.append(credential)
        credentials.sort { $0.service.lowercased() < $1.service.lowercased() }
        do {
            try store.saveCredentials(credentials)
        } catch {
            credentials.removeAll { $0.id == credential.id }
            try? KeychainService.delete(for: credential.id)
            throw error
        }
    }

    func updateCredential(_ credential: Credential, secret: String?) throws {
        if let idx = credentials.firstIndex(where: { $0.id == credential.id }) {
            let previousCredentials = credentials
            let previousSecret = secret == nil ? nil : try? KeychainService.load(for: credential.id)

            if let secret, !secret.isEmpty {
                try KeychainService.save(password: secret, for: credential.id)
            }
            var updated = credential
            updated.updatedAt = Date()
            credentials[idx] = updated
            credentials.sort { $0.service.lowercased() < $1.service.lowercased() }
            do {
                try store.saveCredentials(credentials)
            } catch {
                credentials = previousCredentials
                if let previousSecret {
                    try? KeychainService.save(password: previousSecret, for: credential.id)
                }
                throw error
            }
        }
    }

    func deleteCredential(_ credential: Credential) throws {
        let previousCredentials = credentials
        let previousSecret = try? KeychainService.load(for: credential.id)
        try KeychainService.delete(for: credential.id)
        credentials.removeAll { $0.id == credential.id }
        do {
            try store.saveCredentials(credentials)
        } catch {
            credentials = previousCredentials
            if let previousSecret {
                try? KeychainService.save(password: previousSecret, for: credential.id)
            }
            throw error
        }
    }

    func secret(for credential: Credential) -> String? {
        try? KeychainService.load(for: credential.id)
    }

    func exportData() throws -> Data {
        let items = try credentials.map { credential in
            let secret = try KeychainService.load(for: credential.id)
            return CredentialExportItem(credential: credential, secret: secret)
        }
        let bundle = CredentialExportBundle(credentials: items)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(bundle)
    }

    func importCredentials(from data: Data) throws -> CredentialImportSummary {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let bundle = try decoder.decode(CredentialExportBundle.self, from: data)

        guard bundle.version == 1 else {
            throw CredentialImportError.unsupportedVersion(bundle.version)
        }
        guard !bundle.credentials.isEmpty else {
            throw CredentialImportError.emptyImport
        }

        let previousCredentials = credentials
        var nextCredentials = credentials
        var snapshotIDs = Set<UUID>()
        var previousSecrets: [UUID: String] = [:]
        var added = 0
        var updated = 0

        do {
            for item in bundle.credentials {
                guard !item.secret.isEmpty else {
                    throw CredentialImportError.emptySecret(item.service)
                }

                if !snapshotIDs.contains(item.id) {
                    snapshotIDs.insert(item.id)
                    if let previousSecret = try? KeychainService.load(for: item.id) {
                        previousSecrets[item.id] = previousSecret
                    }
                }

                try KeychainService.save(password: item.secret, for: item.id)

                if let index = nextCredentials.firstIndex(where: { $0.id == item.id }) {
                    nextCredentials[index] = item.credential
                    updated += 1
                } else {
                    nextCredentials.append(item.credential)
                    added += 1
                }
            }

            nextCredentials.sort { $0.service.lowercased() < $1.service.lowercased() }
            credentials = nextCredentials
            try store.saveCredentials(credentials)
            return CredentialImportSummary(added: added, updated: updated)
        } catch {
            credentials = previousCredentials
            for id in snapshotIDs {
                if let previousSecret = previousSecrets[id] {
                    try? KeychainService.save(password: previousSecret, for: id)
                } else {
                    try? KeychainService.delete(for: id)
                }
            }
            throw error
        }
    }
}

enum ValidationError: LocalizedError {
    case emptySecret
    case missingFields

    var errorDescription: String? {
        switch self {
        case .emptySecret: return "Secret cannot be empty"
        case .missingFields: return "All required fields must be filled"
        }
    }
}
