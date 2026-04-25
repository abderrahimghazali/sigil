import Foundation

final class CredentialStore {
    static let shared = CredentialStore()

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("com.sigil.desktop", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("credentials.json")
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadCredentials() -> [Credential] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? decoder.decode([Credential].self, from: data)) ?? []
    }

    func saveCredentials(_ credentials: [Credential]) throws {
        let data = try encoder.encode(credentials)
        try data.write(to: fileURL, options: .atomic)
    }
}
