import SwiftUI
import SwiftData

struct CertificateManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Certificate.name) private var certificates: [Certificate]
    @State private var showingImport = false

    var body: some View {
        NavigationStack {
            ZStack {
                XsignTheme.background.ignoresSafeArea()

                if certificates.isEmpty {
                    ContentUnavailableView("No Certificates", systemImage: "checkmark.seal", description: Text("Import a .p12 and .mobileprovision to start signing."))
                } else {
                    List {
                        ForEach(certificates) { cert in
                            CertificateRow(cert: cert)
                                .listRowBackground(XsignTheme.surface)
                        }
                        .onDelete(perform: deleteCertificates)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Certificates")
            .toolbar {
                Button(action: { showingImport = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingImport) {
                NavigationStack {
                    ImportCertificateView()
                }
            }
        }
    }

    private func deleteCertificates(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(certificates[index])
        }
    }
}

struct CertificateRow: View {
    let cert: Certificate

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(cert.name)
                    .font(.headline)
                    .foregroundColor(XsignTheme.textPrimary)
                Spacer()
                Text(cert.type.rawValue.capitalized)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(XsignTheme.primary.opacity(0.2))
                    .foregroundColor(XsignTheme.primary)
                    .cornerRadius(4)
            }

            Text(cert.commonName)
                .font(.caption)
                .foregroundColor(XsignTheme.textSecondary)

            HStack {
                Label(cert.expiryDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                Spacer()
                Text(cert.fingerprint.prefix(12) + "...")
            }
            .font(.system(size: 10))
            .foregroundColor(XsignTheme.textSecondary)
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
}
