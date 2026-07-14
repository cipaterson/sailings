import Foundation

/// A voyage. Named for the UI term; the Rails side calls it a Sailing.
struct Voyage: Decodable, Identifiable, Hashable {
    let id: Int
    let purpose: String
    let displayName: String
    let sailingType: String?
    let status: String
    let training: String?
    let departsAt: Date?
    let returnsAt: Date?
    let voyageDates: String
    let master: String?
    let engineer: String?
    let lnContact: String?
    let comments: String?
    let additionalDetails: String?
    let participantsCount: Int
    /// Present on /sailings responses; absent when a voyage is nested inside a
    /// registration, where it would be redundant.
    let myRegistration: RegistrationRef?
}

struct RegistrationRef: Decodable, Hashable {
    let id: Int
    let status: String
}

struct Registration: Decodable, Identifiable, Hashable {
    let id: Int
    let status: String
    let comment: String?
    let climbing: String?
    let attended: Bool
    let createdAt: Date?
    let sailing: Voyage
}

struct Profile: Decodable, Hashable {
    let id: Int
    let emailAddress: String
    let firstName: String?
    let lastName: String?
    let fullName: String
    let membershipType: String?
    let dateJoined: Date?
    let roles: [String]
    let skills: [String]
    let sailingRecord: SailingRecord
    let qualifications: [Qualification]
    let training: [TrainingRecord]
}

struct SailingRecord: Decodable, Hashable {
    let daysSailed: Int
    let lastSailed: Date?
    let sailingClass: String?
}

struct Qualification: Decodable, Identifiable, Hashable {
    let key: String
    let label: String
    let value: String?
    let issuedOn: Date?
    let expiresOn: Date?

    var id: String { key }

    /// Drives the "am I current?" colouring on the profile screen.
    enum Standing {
        case none, expired, expiringSoon, current
    }

    func standing(asOf now: Date = .now) -> Standing {
        guard let expiresOn else { return value?.isEmpty == false ? .current : .none }
        if expiresOn < now { return .expired }
        if expiresOn < now.addingTimeInterval(60 * 24 * 60 * 60) { return .expiringSoon }
        return .current
    }
}

struct TrainingRecord: Decodable, Identifiable, Hashable {
    let key: String
    let label: String
    let completedOn: Date?

    var id: String { key }
}

struct LoginResponse: Decodable {
    let token: String
    let user: Profile
}

/// Registration status values as Rails defines them (SailingParticipant::STATUSES).
enum RegistrationStatus {
    static let eoi = "EOI"
    static let accepted = "Accepted"
    static let notRequired = "Not-required"
}
