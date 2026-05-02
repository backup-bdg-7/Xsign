import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \AppFile.creationDate, order: .reverse) private var appFiles: [AppFile]
    @Query private var categories: [Category]
    @State private var showingImportPicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                XsignTheme.background.ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(appFiles) { file in
                            NavigationLink(destination: AppDetailView(appFile: file)) { AppFileCard(appFile: file) }
                        }
                    }.padding()
                }
            }
            .navigationTitle("Library")
            .toolbar { 
                Button(action: { showingImportPicker = true }) { 
                    Image(systemName: "plus") 
                } 
            }
            .fileImporter(isPresented: $showingImportPicker, allowedContentTypes: [.item]) { result in
                handleFileImport(result)
            }
        }
    }
    
    private func handleFileImport(_ result: Result<URL, Error>) {
        if let url = try? result.get() {
            Task { try? await FileService.shared.importFile(at: url) }
        }
    }
}
