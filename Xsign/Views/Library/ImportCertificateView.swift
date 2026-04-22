import SwiftUI
import SwiftData

struct ImportCertificateView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @State private var name = ""

    var body: some View {
        Form {
            Section("Info") { TextField("Name", text: $name) }
            Button("Save") {
                let cert = Certificate(name: name, p12Data: Data(), type: .distribution, expiryDate: Date(), commonName: name, fingerprint: "", canSign: true)
                modelContext.insert(cert)
                dismiss()
            }
        }.navigationTitle("Import")
    }
}
