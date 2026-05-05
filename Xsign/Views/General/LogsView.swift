import SwiftUI
import SwiftData

// MARK: - LogsView
// Based on Feather's log presentation
struct LogsView: View {
    @Query(sort: \AppLog.timestamp, order: .reverse) private var logs: [AppLog]
    @State private var searchText = ""
    @State private var selectedLevel: LogLevel?
    @State private var showingClearConfirmation = false
    
    var filteredLogs: [AppLog] {
        logs.filter { log in
            let matchesSearch = searchText.isEmpty ||
                log.message.localizedCaseInsensitiveContains(searchText) ||
                log.category.localizedCaseInsensitiveContains(searchText)
            let matchesLevel = selectedLevel == nil || log.level == selectedLevel
            return matchesSearch && matchesLevel
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and filter bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search logs...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    Menu {
                        Button("All Levels") { selectedLevel = nil }
                        Divider()
                        ForEach([LogLevel.info, .success, .warning, .error], id: \.self) { level in
                            Button(action: { selectedLevel = level }) {
                                Label(level.rawValue.capitalized, systemImage: iconForLevel(level))
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(selectedLevel == nil ? .secondary : XsignTheme.primary)
                    }
                }
                .padding(8)
                .background(XsignTheme.surface)
                .cornerRadius(8)
                .padding()
                
                if filteredLogs.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(filteredLogs) { log in
                            LogRow(log: log)
                                .listRowBackground(XsignTheme.surface)
                        }
                        .onDelete { indexSet in
                            deleteLogs(at: indexSet)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Logs")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(role: .destructive, action: { showingClearConfirmation = true }) {
                            Label("Clear All Logs", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .confirmationDialog(
                "Clear all logs?",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear All", role: .destructive) { clearAllLogs() }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Logs")
                .font(.headline)
                .foregroundColor(XsignTheme.textSecondary)
            if !searchText.isEmpty || selectedLevel != nil {
                Text("Try adjusting your filters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func deleteLogs(at indexSet: IndexSet) {
        for index in indexSet {
            if index < filteredLogs.count {
                let log = filteredLogs[index]
                PersistenceService.shared.context.delete(log)
            }
        }
        PersistenceService.shared.save()
    }
    
    private func clearAllLogs() {
        for log in logs {
            PersistenceService.shared.context.delete(log)
        }
        PersistenceService.shared.save()
        
        // Also clear the log file
        let logsURL = PersistenceService.shared.getLogsFileURL()
        try? FileManager.default.removeItem(at: logsURL)
        PersistenceService.shared.setupLogsFile()
    }
    
    private func iconForLevel(_ level: LogLevel) -> String {
        switch level {
        case .info: return "info.circle"
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        }
    }
}

// MARK: - LogRow
struct LogRow: View {
    let log: AppLog
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconForLevel(log.level))
                .foregroundColor(colorForLevel(log.level))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(log.category)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(XsignTheme.textSecondary)
                    Spacer()
                    Text(log.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(XsignTheme.textSecondary)
                }
                
                Text(log.message)
                    .font(.subheadline)
                    .foregroundColor(XsignTheme.textPrimary)
                    .lineLimit(3)
                
                if let details = log.details {
                    Text(details)
                        .font(.caption)
                        .foregroundColor(XsignTheme.textSecondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForLevel(_ level: LogLevel) -> String {
        switch level {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
    
    private func colorForLevel(_ level: LogLevel) -> Color {
        switch level {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
}
