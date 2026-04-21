import SwiftUI

struct EntitlementEditorView: View {
    @Binding var entitlements: [String: Any]
    @Environment(\.dismiss) var dismiss

    @State private var newKey = ""
    @State private var newValue = ""
    @State private var keys: [String] = []

    init(entitlements: Binding<[String: Any]>) {
        self._entitlements = entitlements
        self._keys = State(initialValue: entitlements.wrappedValue.keys.sorted())
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Core Entitlements") {
                    ForEach(keys, id: \.self) { key in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(key)
                                    .font(.caption)
                                    .foregroundColor(XsignTheme.textSecondary)
                                EntitlementValueField(key: key, value: entitlements[key]) { newValue in
                                    entitlements[key] = newValue
                                }
                            }
                            Spacer()
                            Button(action: { removeKey(key) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(XsignTheme.error)
                            }
                        }
                        .listRowBackground(XsignTheme.surface)
                    }
                }

                Section("Add New") {
                    HStack {
                        TextField("Key", text: $newKey)
                        Button("Add") { addKey() }
                            .disabled(newKey.isEmpty)
                    }
                    .listRowBackground(XsignTheme.surface)
                }
            }
            .navigationTitle("Entitlement Editor")
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }

    private func addKey() {
        entitlements[newKey] = true
        keys = entitlements.keys.sorted()
        newKey = ""
    }

    private func removeKey(_ key: String) {
        entitlements.removeValue(forKey: key)
        keys = entitlements.keys.sorted()
    }
}

struct EntitlementValueField: View {
    let key: String
    let value: Any?
    let onChange: (Any) -> Void

    var body: some View {
        if let boolValue = value as? Bool {
            Toggle("", isOn: Binding(
                get: { boolValue },
                set: { onChange($0) }
            ))
            .labelsHidden()
        } else if let stringValue = value as? String {
            TextField("Value", text: Binding(
                get: { stringValue },
                set: { onChange($0) }
            ))
            .foregroundColor(XsignTheme.textPrimary)
        } else if let arrayValue = value as? [String] {
            Text(arrayValue.joined(separator: ", "))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(XsignTheme.textPrimary)
        } else {
            Text("Complex Value")
                .font(.caption)
                .italic()
        }
    }
}
