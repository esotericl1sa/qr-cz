import Foundation

enum SPDParser {
    enum ParseError: LocalizedError {
        case unsupportedFormat, missingIBAN, invalidIBAN

        var errorDescription: String? {
            switch self {
            case .unsupportedFormat: "Usupported QR code."
            case .missingIBAN: "The payment code doesn't include an IBAN."
            case .invalidIBAN: "Invalid IBAN."
            }
        }
    }

    static func parse(_ input: String) throws -> CzechPayment {
        let parts = input.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "*", omittingEmptySubsequences: true).map(String.init)
        guard parts.count >= 2, parts[0] == "SPD", parts[1] == "1.0" else {
            throw ParseError.unsupportedFormat
        }

        var fields: [String: String] = [:]
        for part in parts.dropFirst(2) {
            guard let separator = part.firstIndex(of: ":") else { continue }
            let key = String(part[..<separator]).uppercased()
            let value = String(part[part.index(after: separator)...])
            fields[key] = value.removingPercentEncoding ?? value
        }

        guard let account = fields["ACC"], !account.isEmpty else { throw ParseError.missingIBAN }
        let accountParts = account.split(separator: "+", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        guard let rawIBAN = accountParts.first else { throw ParseError.missingIBAN }
        let iban = rawIBAN.filter { !$0.isWhitespace }.uppercased()
        guard isValidIBAN(iban) else { throw ParseError.invalidIBAN }
        let bic = accountParts.count > 1 && !accountParts[1].isEmpty ? accountParts[1] : nil

        return CzechPayment(iban: iban, recipientName: fields["RN"].flatMap { $0.isEmpty ? nil : $0 }, bic: bic,
                            amount: fields["AM"], currency: fields["CC"],
                            variableSymbol: fields["X-VS"], message: fields["MSG"])
    }

    static func isValidIBAN(_ iban: String) -> Bool {
        let value = iban.uppercased().filter { !$0.isWhitespace }
        guard (15...34).contains(value.count),
              value.prefix(2).allSatisfy(\.isLetter),
              value.dropFirst(2).prefix(2).allSatisfy(\.isNumber),
              value.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber) }) else { return false }

        let rearranged = String(value.dropFirst(4)) + String(value.prefix(4))
        var remainder = 0
        for character in rearranged {
            let digits = character.isLetter ? String(character.asciiValue! - 55) : String(character)
            for digit in digits {
                guard let number = digit.wholeNumberValue else { return false }
                remainder = (remainder * 10 + number) % 97
            }
        }
        return remainder == 1
    }
}
