import Foundation

enum TOTPAlgorithm: String, Codable, CaseIterable {
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha512 = "SHA512"
}

struct Account: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var issuer: String
    var secret: String
    var algorithm: TOTPAlgorithm
    var digits: Int
    var period: Int

    init(
        id: UUID = UUID(),
        name: String,
        issuer: String = "",
        secret: String,
        algorithm: TOTPAlgorithm = .sha1,
        digits: Int = 6,
        period: Int = 30
    ) {
        self.id = id
        self.name = name
        self.issuer = issuer
        self.secret = secret.uppercased().replacingOccurrences(of: " ", with: "")
        self.algorithm = algorithm
        self.digits = digits
        self.period = period
    }

    var displayTitle: String {
        issuer.isEmpty ? name : "\(issuer) (\(name))"
    }
}