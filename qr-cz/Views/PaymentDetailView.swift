import SwiftUI

struct PaymentDetailView: View {
    let payment: CzechPayment
    @State private var copiedToastID: UUID?
    @State private var copiedRowIndices = Set<Int>()
    @State private var copiedRowIDs: [Int: UUID] = [:]

    var body: some View {
        List {
            ForEach(Array(payment.rows.enumerated()), id: \.offset) { index, row in
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(row.0).font(.caption).foregroundStyle(.secondary)
                        Text(row.1).font(.body).textSelection(.enabled)
                    }
                    Spacer(minLength: 8)
                    Button {
                        UIPasteboard.general.string = row.1
                        showCopiedToast(for: index)
                    } label: {
                        Image(systemName: copiedRowIndices.contains(index) ? "checkmark" : "doc.on.doc")
                            .foregroundStyle(copiedRowIndices.contains(index) ? .green : .primary)
                            .frame(width: 40, height: 40)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(copiedRowIndices.contains(index) ? "Copied \(row.0)" : "Copy \(row.0)")
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("Payment details")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if copiedToastID != nil {
                Text("Copied!")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
    }

    private func showCopiedToast(for rowIndex: Int) {
        let toastID = UUID()
        let rowCopyID = UUID()
        withAnimation(.easeOut(duration: 0.1)) {
            copiedToastID = toastID
            copiedRowIndices.insert(rowIndex)
            copiedRowIDs[rowIndex] = rowCopyID
        }

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            guard copiedRowIDs[rowIndex] == rowCopyID else { return }
            withAnimation(.easeOut(duration: 0.1)) {
                copiedRowIndices.remove(rowIndex)
                copiedRowIDs[rowIndex] = nil
            }
        }

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            guard copiedToastID == toastID else { return }
            withAnimation(.easeOut(duration: 0.1)) {
                copiedToastID = nil
            }
        }
    }
}
