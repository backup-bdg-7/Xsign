import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Query(sort: \Category.name) private var categories: [Category]
    var body: some View {
        NavigationStack {
            ZStack {
                XsignTheme.background.ignoresSafeArea()
                if categories.isEmpty { ContentUnavailableView("No Categories", systemImage: "square.grid.2x2") }
                else {
                    List(categories) { category in
                        HStack {
                            Image(systemName: category.icon).foregroundColor(Color(hex: category.color))
                            Text(category.name).foregroundColor(XsignTheme.textPrimary)
                        }.listRowBackground(XsignTheme.surface)
                    }.listStyle(.insetGrouped)
                }
            }.navigationTitle("Categories")
        }
    }
}
