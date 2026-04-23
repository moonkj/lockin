import Foundation

struct InterceptEvent: Codable, Equatable, Identifiable {
    enum EventType: String, Codable {
        case returned
        case interceptRequested
    }

    enum SubjectKind: String, Codable {
        case application
        case category
        case webDomain
    }

    let id: UUID
    let timestamp: Date
    let type: EventType
    let subjectKind: SubjectKind

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: EventType,
        subjectKind: SubjectKind
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.subjectKind = subjectKind
    }
}
