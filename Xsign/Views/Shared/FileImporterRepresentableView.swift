import SwiftUI
import UniformTypeIdentifiers

// MARK: - FileImporterRepresentableView
// A UIKit-based file importer that properly handles file imports
// This is based on Feather's implementation for reliable file importing
public struct FileImporterRepresentableView: UIViewControllerRepresentable {
    public var allowedContentTypes: [UTType]
    public var allowsMultipleSelection: Bool = false
    public var onDocumentsPicked: ([URL]) -> Void
    
    public init(
        allowedContentTypes: [UTType],
        allowsMultipleSelection: Bool = false,
        onDocumentsPicked: @escaping ([URL]) -> Void
    ) {
        self.allowedContentTypes = allowedContentTypes
        self.allowsMultipleSelection = allowsMultipleSelection
        self.onDocumentsPicked = onDocumentsPicked
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentsPicked: onDocumentsPicked)
    }
    
    public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = allowsMultipleSelection
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    public class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onDocumentsPicked: ([URL]) -> Void
        
        init(onDocumentsPicked: @escaping ([URL]) -> Void) {
            self.onDocumentsPicked = onDocumentsPicked
        }
        
        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onDocumentsPicked(urls)
        }
        
        public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onDocumentsPicked([])
        }
    }
}

// MARK: - UTType Extensions for our file types
extension UTType {
    static let p12 = UTType(filenameExtension: "p12") ?? .data
    static let mobileprovision = UTType(filenameExtension: "mobileprovision") ?? .data
    static let ipa = UTType(filenameExtension: "ipa") ?? .data
    static let dylib = UTType(filenameExtension: "dylib") ?? .unixExecutable
    static let deb = UTType(filenameExtension: "deb") ?? .data
    static let tipa = UTType(filenameExtension: "tipa") ?? .data
}
