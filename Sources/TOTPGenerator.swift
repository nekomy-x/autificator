import Foundation
import CryptoKit

final class TOTPGenerator {

    static func generateCode(for account: Account) -> String? {
        guard let secretData = base32Decode(account.secret) else { return nil }
        return generateCode(secret: secretData, time: Date(), digits: account.digits, algorithm: account.algorithm)
    }

    static func generateCode(secret: Data, time: Date = Date(), digits: Int = 6, algorithm: TOTPAlgorithm = .sha1) -> String? {
        let counter = UInt64(time.timeIntervalSince1970) / UInt64(30)
        var counterBytes = counter.bigEndian
        let counterData = withUnsafeBytes(of: &counterBytes) { Data($0) }
        let key = SymmetricKey(data: secret)
        let hmac: Data

        switch algorithm {
        case .sha1:
            let digest = HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: key)
            hmac = Data(digest)
        case .sha256:
            let digest = HMAC<SHA256>.authenticationCode(for: counterData, using: key)
            hmac = Data(digest)
        case .sha512:
            let digest = HMAC<SHA512>.authenticationCode(for: counterData, using: key)
            hmac = Data(digest)
        }

        let offset = Int(hmac[hmac.count - 1] & 0x0f)
        let truncatedHash = hmac.subdata(in: offset..<(offset + 4))
        var number = truncatedHash.withUnsafeBytes { $0.load(as: UInt32.self) }
        number = UInt32(bigEndian: number)
        number &= 0x7fffffff

        let modulus = UInt32(pow(10, Double(digits)))
        let otp = number % modulus
        return String(format: "%0\(digits)d", otp)
    }

    static func remainingSeconds(period: Int = 30) -> Int {
        let now = Int(Date().timeIntervalSince1970)
        return period - (now % period)
    }

    static func progress(period: Int = 30) -> Double {
        Double(remainingSeconds(period: period)) / Double(period)
    }

    static func base32Decode(_ input: String) -> Data? {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        let cleanedInput = input.uppercased().filter { $0 != "=" && alphabet.contains($0) }
        var bits = ""
        for char in cleanedInput {
            guard let index = alphabet.firstIndex(of: char) else { return nil }
            let value = alphabet.distance(from: alphabet.startIndex, to: index)
            bits += String(value, radix: 2).padding(toLength: 5, withPad: "0", startingAt: 0)
        }
        var bytes = [UInt8]()
        for i in stride(from: 0, to: bits.count - 7, by: 8) {
            let startIndex = bits.index(bits.startIndex, offsetBy: i)
            let endIndex = bits.index(startIndex, offsetBy: 8)
            let byteString = String(bits[startIndex..<endIndex])
            if let byte = UInt8(byteString, radix: 2) {
                bytes.append(byte)
            }
        }
        return Data(bytes)
    }
}

extension String {
    func padding(toLength length: Int, withPad pad: String, startingAt index: Int) -> String {
        if self.count >= length { return self }
        let pads = String(repeating: pad, count: length - self.count)
        return pads + self
    }
}