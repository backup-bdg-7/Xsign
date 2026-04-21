import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AppFile.creationDate, order: .reverse) private var appFiles: [AppFile]
    @Query private var categories: [Category]

    @State private var searchText = ""
    @State private var selectedCategory: Category? = nil
    @State private var isGridView = true
    @State private var showingImportPicker = false

    var filteredFiles: [AppFile] {
        appFiles.filter { file in
            let matchesSearch = searchText.isEmpty || file.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || file.category?.id == selectedCategory?.id
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                XsignTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Category Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryChip(name: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }

                            ForEach(categories) { category in
                                CategoryChip(name: category.name, isSelected: selectedCategory?.id == category.id) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }

                    if filteredFiles.isEmpty {
                        VStack {
                            Spacer()
                            Image(systemName: "tray.fill")
                                .font(.system(size: 60))
                                .foregroundColor(XsignTheme.textSecondary)
                            Text("No apps found")
                                .font(.headline)
                                .foregroundColor(XsignTheme.textSecondary)
                                .padding(.top, 8)
                            Spacer()
                        }
                    } else {
                        if isGridView {
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                    ForEach(filteredFiles) { file in
                                        NavigationLink(destination: AppDetailView(appFile: file)) {
                                            AppFileCard(appFile: file)
                                        }
                                    }
                                }
                                .padding()
                            }
                        } else {
                            List {
                                ForEach(filteredFiles) { file in
                                    NavigationLink(destination: AppDetailView(appFile: file)) {
                                        AppFileListRow(appFile: file)
                                    }
                                    .listRowBackground(XsignTheme.surface)
                                }
                            }
                            .listStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isGridView.toggle() }) {
                        Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingImportPicker = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search IPAs...")
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        Task {
                            try? await FileService.shared.importFile(at: url)
                        }
                    }
                case .failure(let error):
                    print("Import failed: \(error.localizedDescription)")
                }
            }
        }
        .accentColor(XsignTheme.primary)
    }
}

struct CategoryChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? XsignTheme.primary : XsignTheme.surface)
                .foregroundColor(isSelected ? .white : XsignTheme.textSecondary)
                .cornerRadius(20)
        }
    }
}
