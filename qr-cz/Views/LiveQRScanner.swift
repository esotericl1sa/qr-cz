import SwiftUI
import VisionKit
import Vision
import AVFoundation

struct LiveQRScanner: UIViewControllerRepresentable {
    let onCode: (String) -> Bool
    let onStatus: (String?) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false
        )
        scanner.delegate = context.coordinator
        let coordinator = context.coordinator
        Task { @MainActor in await coordinator.start(scanner) }
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode, onStatus: onStatus) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onCode: (String) -> Bool
        private let onStatus: (String?) -> Void
        private var didScan = false

        init(onCode: @escaping (String) -> Bool, onStatus: @escaping (String?) -> Void) {
            self.onCode = onCode
            self.onStatus = onStatus
        }

        @MainActor
        func start(_ scanner: DataScannerViewController) async {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                break
            case .notDetermined:
                guard await AVCaptureDevice.requestAccess(for: .video) else {
                    onStatus("No camera access.\nAllow it in Settings or upload a QR code instead.")
                    return
                }
            default:
                onStatus("No camera access.\nAllow it in Settings or upload a QR code instead.")
                return
            }

            guard DataScannerViewController.isSupported, DataScannerViewController.isAvailable else {
                onStatus("Live scanning isn't available on this device.\nUpload a QR code instead.")
                return
            }

            do {
                try scanner.startScanning()
                onStatus(nil)
            }
            catch {
                onStatus("Couldn't start the camera scanner.\nUpload a QR code or try again.")
            }
        }

        func dataScanner(_ scanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !didScan,
                  let code = addedItems.compactMap({ item -> String? in
                      guard case .barcode(let barcode) = item else { return nil }
                      return barcode.payloadStringValue
                  }).first else { return }
            didScan = true
            scanner.stopScanning()
            Task { @MainActor in
                guard !onCode(code) else { return }
                didScan = false
                do {
                    try scanner.startScanning()
                }
                catch {
                    onStatus("Couldn't restart the scanner.\nUpload a QR code or try again.")
                }
            }
        }
    }
}
