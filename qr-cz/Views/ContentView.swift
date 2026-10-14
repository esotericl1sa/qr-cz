import PhotosUI
import SwiftUI

struct ContentView: View {
    @StateObject private var controller = PaymentFlowController()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var scannerID = UUID()
    @State private var scannerMessage: String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                LiveQRScanner(onCode: controller.decode, onStatus: { scannerMessage = $0 })
                    .ignoresSafeArea()
                    .id(scannerID)

                VStack(spacing: 14) {
                    Text("Scan a Czech payment QR code")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.regularMaterial, in: Capsule())

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Upload QR code", systemImage: "photo")
                            .font(.body.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("QR code to Payment details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: Binding(
                get: { controller.payment != nil },
                set: {
                    if !$0 {
                        controller.scanAnother()
                        scannerID = UUID()
                    }
                }
            )) {
                if let payment = controller.payment {
                    PaymentDetailView(payment: payment)
                }
            }
            .overlay(alignment: .top) {
                if let scannerMessage {
                    Text(scannerMessage)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 32)
                        .padding(.top, 52)
                }
                else if let message = controller.errorMessage {
                    Text(message)
                        .font(.subheadline)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(.regularMaterial)
                        .padding(.horizontal, 16)
                        .padding(.top, 52)
                }
            }
            .onChange(of: selectedPhoto) { _, photo in
                guard let photo else { return }
                Task {
                    if let data = try? await photo.loadTransferable(type: Data.self) {
                        await controller.decodeQRCode(imageData: data)
                    }
                    else {
                        controller.errorMessage = "Couldn't open the image."
                    }
                    selectedPhoto = nil
                }
            }
        }
    }
}
