import SwiftUI
import SwiftData

struct LogsView: View {
    @Query(sort: \AppLog.timestamp, order: .reverse) private var logs: [AppLog]
    @State private var selectedLevel: LogLevel? = nil
    @State private var searchText = ""
    
    var filteredLogs: [AppLog] {
        var result = logs
        
        if let level = selectedLevel {
            result = result.filter { $0.level == level }
        }
        
        if !searchText.isEmpty {
            result = result.filter { log in
                log.message.localizedCaseInsensitiveContains(searchText) ||
                log.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            XsignTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Filter buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: selectedLevel == nil) {
                            selectedLevel = nil
                        }
                        
                        ForEach(LogLevel.allCases, id: \.self) { level in
                            FilterChip(
                                title: level.rawValue.capitalized,
                                isSelected: selectedLevel == level,
                                color: colorForLevel(level)
                            ) {
                                selectedLevel = level
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                Divider()
                
                // Logs list
                if filteredLogs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "text.badge.xmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No logs found")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredLogs) { log in
                            LogRowView(log: log)
                                .listRowBackground(XsignTheme.surface)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Logs")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search logs...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Export Logs") {
                        exportLogs()
                    }
                    Button("Clear Logs", role: .destructive) {
                        clearLogs()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    private func colorForLevel(_ level: LogLevel) -> Color {
        switch level {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .debug: return .gray
        }
    }
    
    private func exportLogs() {
        let logsURL = PersistenceService.shared.getLogsFileURL()
        // Share the logs file
        // Implementation depends on UIKit integration
    }
    
    private func clearLogs() {
        for log in logs {
            PersistenceService.shared.context.delete(log)
        }
        PersistenceService.shared.save()
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? color : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct LogRowView: View {
    let log: AppLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(log.level.rawValue.capitalized)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(colorForLevel(log.level))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(colorForLevel(log.level).opacity(0.1))
                    .cornerRadius(4)
                
                Text(log.category)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(log.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(log.message)
                .font(.caption)
                .foregroundColor(XsignTheme.textPrimary)
            
            if let details = log.details {
                Text(details)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorForLevel(_ level: LogLevel) -> Color {
        switch level {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .debug: return .gray
        }
    }
}

#Preview {
    LogsView()
}
