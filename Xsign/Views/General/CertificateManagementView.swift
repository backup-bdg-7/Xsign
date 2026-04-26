import SwiftUI
import SwiftData

struct CertificateManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Certificate.name) private var certificates: [Certificate]
    @State private var showingImport = false

    var body: some View {
        ZStack {
            XsignTheme.background.ignoresSafeArea()
            if certificates.isEmpty {
                VStack {
                    LottieView(name: "no_data", loopMode: .loop)
                        .frame(width: 200, height: 200)
                    Text("No Certificates Found")
                        .font(.headline)
                        .foregroundColor(XsignTheme.textSecondary)
                    Button("Import One") { showingImport = true }
                        .padding()
                        .background(XsignTheme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                List {
                    ForEach(certificates) { cert in
                        CertificateRow(cert: cert)
                            .listRowBackground(XsignTheme.surface)
                    }
                    .onDelete(perform: deleteCertificates)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Certificates")
        .toolbar {
            Button(action: { showingImport = true }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(XsignTheme.primary)
            }
        }
        .sheet(isPresented: $showingImport) {
            NavigationStack {
                ImportCertificateView()
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
                Text(cert.name).font(.headline).foregroundColor(XsignTheme.textPrimary)
                Spacer()
                Text(cert.type.rawValue.uppercased()).font(.system(size: 8, weight: .bold))
                    .padding(4).background(XsignTheme.primary.opacity(0.2)).foregroundColor(XsignTheme.primary).cornerRadius(4)
            }
            Text(cert.commonName).font(.caption).foregroundColor(XsignTheme.textSecondary)
            HStack {
                Label(cert.expiryDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                Spacer()
                Text(cert.fingerprint.prefix(10) + "...").font(.system(size: 8, design: .monospaced))
            }.font(.caption2).foregroundColor(XsignTheme.textSecondary)
        }.padding(.vertical, 4)
    }
}
