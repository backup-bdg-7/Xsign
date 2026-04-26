import SwiftUI

struct DylibsView: View {
    @Query private var dylibs: [AppFile]
    
    init() {
        let dylibRawValue = FileType.dylib.rawValue
        let predicate = #Predicate<AppFile> { file in
            file.type.rawValue == dylibRawValue
        }
        _dylibs = Query(filter: predicate, sort: \AppFile.name)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                XsignTheme.background.ignoresSafeArea()
                if dylibs.isEmpty { 
                    ContentUnavailableView("No Dylibs", systemImage: "bolt.fill") 
                }
                else {
                    List(dylibs) { dylib in
                        NavigationLink(destination: AppDetailView(appFile: dylib)) {
                            HStack {
                                Image(systemName: "bolt.horizontal.circle.fill").foregroundColor(XsignTheme.primary)
                                Text(dylib.name).foregroundColor(XsignTheme.textPrimary)
                            }
                        }.listRowBackground(XsignTheme.surface)
                    }.listStyle(.plain)
                }
            }.navigationTitle("Dylibs")
        }
    }
}
