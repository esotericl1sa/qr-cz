import Foundation
import Combine
import Vision

@MainActor
final class PaymentFlowController: ObservableObject {
    @Published var payment: CzechPayment?
    @Published var errorMessage: String?

    @discardableResult
    func decode(_ payload: String) -> Bool {
        do {
            payment = try SPDParser.parse(payload)
            errorMessage = nil
            return true
        }
        catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func decodeQRCode(imageData: Data) async {
        let payload = await Task.detached(priority: .userInitiated) { () -> String? in
            let request = VNDetectBarcodesRequest()
            request.symbologies = [.qr]
            do {
                try VNImageRequestHandler(data: imageData).perform([request])
                return request.results?.first?.payloadStringValue
            }
            catch {
                return nil
            }
        }.value

        guard let payload else {
            errorMessage = "No readable QR code found in the image."
            return
        }
        decode(payload)
    }

    func scanAnother() {
        payment = nil
        errorMessage = nil
    }
}
