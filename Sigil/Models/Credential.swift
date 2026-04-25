import Foundation

struct Credential: Identifiable, Codable, Equatable {
    let id: UUID
    var service: String
    var username: String
    var url: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        service: String,
        username: String,
        url: String = "",
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.service = service
        self.username = username
        self.url = url
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
