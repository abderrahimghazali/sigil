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
            $0.url.lowercased().contains(q)
        }
    }

    init() {
        credentials = store.loadCredentials().sorted { $0.service.lowercased() < $1.service.lowercased() }
    }

    func addCredential(service: String, username: String, password: String, url: String = "", notes: String = "") throws {
        guard !password.isEmpty else { throw ValidationError.emptyPassword }

        let credential = Credential(service: service, username: username, url: url, notes: notes)
        try KeychainService.save(password: password, for: credential.id)
        credentials.append(credential)
        credentials.sort { $0.service.lowercased() < $1.service.lowercased() }
        store.saveCredentials(credentials)
    }

    func updateCredential(_ credential: Credential, password: String?) throws {
        if let password, !password.isEmpty {
            try KeychainService.save(password: password, for: credential.id)
        }
        if let idx = credentials.firstIndex(where: { $0.id == credential.id }) {
            var updated = credential
            updated.updatedAt = Date()
            credentials[idx] = updated
            credentials.sort { $0.service.lowercased() < $1.service.lowercased() }
            store.saveCredentials(credentials)
        }
    }

    func deleteCredential(_ credential: Credential) {
        try? KeychainService.delete(for: credential.id)
        credentials.removeAll { $0.id == credential.id }
        store.saveCredentials(credentials)
    }

    func password(for credential: Credential) -> String? {
        try? KeychainService.load(for: credential.id)
    }
}

enum ValidationError: LocalizedError {
    case emptyPassword
    case missingFields

    var errorDescription: String? {
        switch self {
        case .emptyPassword: return "Password cannot be empty"
        case .missingFields: return "All required fields must be filled"
        }
    }
}
