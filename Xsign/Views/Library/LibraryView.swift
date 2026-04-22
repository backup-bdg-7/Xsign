import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \AppFile.creationDate, order: .reverse) private var appFiles: [AppFile]
    @Query private var categories: [Category]
    @State private var searchText = ""
    @State private var selectedCategory: Category?
    @State private var isGridView = true
    @State private var showingImportPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                XsignTheme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryChip(name: "All", isSelected: selectedCategory == nil) { selectedCategory = nil }
                            ForEach(categories) { category in
                                CategoryChip(name: category.name, isSelected: selectedCategory?.id == category.id) { selectedCategory = category }
                            }
                        }.padding()
                    }

                    if isGridView {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(appFiles) { file in
                                    NavigationLink(destination: AppDetailView(appFile: file)) {
                                        AppFileCard(appFile: file)
                                    }
                                }
                            }.padding()
                        }
                    } else {
                        List(appFiles) { file in
                            NavigationLink(destination: AppDetailView(appFile: file)) {
                                AppFileListRow(appFile: file)
                            }.listRowBackground(XsignTheme.surface)
                        }.listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                Button(action: { showingImportPicker = true }) { Image(systemName: "plus") }
            }
            .fileImporter(isPresented: $showingImportPicker, allowedContentTypes: [.item]) { result in
                if let url = try? result.get().first {
                    Task { try? await FileService.shared.importFile(at: url) }
                }
            }
        }
    }
}

struct CategoryChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(name).padding(.horizontal).padding(.vertical, 8)
                .background(isSelected ? XsignTheme.primary : XsignTheme.surface)
                .foregroundColor(.white).cornerRadius(20)
        }
    }
}
