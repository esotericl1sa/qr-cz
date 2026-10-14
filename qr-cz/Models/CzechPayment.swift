import Foundation

struct CzechPayment: Equatable {
    let iban: String
    let recipientName: String?
    let bic: String?
    let amount: String?
    let currency: String?
    let variableSymbol: String?
    let message: String?

    var rows: [(String, String)] {
        var result = [("IBAN", iban)]
        if let recipientName { result.insert(("Recipient name", recipientName), at: 0) }
        if let bic { result.append(("SWIFT / BIC", bic)) }
        if let amount { result.append(("Amount", amount)) }
        if let currency { result.append(("Currency", currency)) }
        if let variableSymbol { result.append(("Variable symbol", variableSymbol)) }
        if let message { result.append(("Payment message", message)) }
        return result
    }
}
