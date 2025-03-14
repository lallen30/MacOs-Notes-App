import SwiftUI
import UniformTypeIdentifiers
import CoreData
import Foundation

@main
struct NotesAppApp: App {
    let persistenceController = PersistenceController.shared
    @State private var isExporting = false
    @State private var exportError: String? = nil
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .alert("Export Error", isPresented: Binding<Bool>(
                    get: { exportError != nil },
                    set: { if !$0 { exportError = nil } }
                )) {
                    Button("OK", role: .cancel) { exportError = nil }
                } message: {
                    Text(exportError ?? "Unknown error occurred during export")
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Note") {
                    NotificationCenter.default.post(name: NSNotification.Name("CreateNewNote"), object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(after: .newItem) {
                Divider()
                Button("Search") {
                    NotificationCenter.default.post(name: NSNotification.Name("FocusSearch"), object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
            }
            
            CommandMenu("File") {
                Button("Export All Notes...") {
                    exportAllNotes()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }
    }
    
    private func exportAllNotes() {
        isExporting = true
        
        // Export data directly without using a separate utility class
        exportAllData(context: persistenceController.container.viewContext) { fileURL, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.exportError = "Failed to export notes: \(error.localizedDescription)"
                    self.isExporting = false
                }
                return
            }
            
            guard let fileURL = fileURL else {
                DispatchQueue.main.async {
                    self.exportError = "Failed to create export file"
                    self.isExporting = false
                }
                return
            }
            
            self.saveExportedFile(sourceURL: fileURL) { success in
                DispatchQueue.main.async {
                    if !success {
                        self.exportError = "Failed to save export file"
                    }
                    self.isExporting = false
                }
            }
        }
    }
    
    // Main export function that creates a JSON file with all categories and notes
    private func exportAllData(context: NSManagedObjectContext, completion: @escaping (URL?, Error?) -> Void) {
        // Create a dictionary to hold all the data
        var exportData: [String: Any] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "categories": [],
            "unlistedNotes": []
        ]
        
        // Fetch all categories
        let categoryRequest = Category.fetchRequest()
        categoryRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        
        do {
            let categories = try context.fetch(categoryRequest)
            var categoriesArray: [[String: Any]] = []
            
            // Process each category
            for category in categories {
                var categoryDict: [String: Any] = [
                    "id": category.id?.uuidString ?? UUID().uuidString,
                    "name": category.name ?? "Unnamed Category",
                    "colorHex": category.colorHex ?? "#007AFF",
                    "createdAt": ISO8601DateFormatter().string(from: category.createdAt ?? Date()),
                    "updatedAt": ISO8601DateFormatter().string(from: category.updatedAt ?? Date()),
                    "notes": [],
                    "subcategories": []
                ]
                
                // Add notes for this category
                if let notes = category.notes as? Set<Note> {
                    categoryDict["notes"] = notes.map { self.noteToDict($0) }
                }
                
                // Add subcategories for this category
                if let subcategories = category.subcategories as? Set<SubCategory> {
                    var subcategoriesArray: [[String: Any]] = []
                    
                    for subcategory in subcategories {
                        var subcategoryDict: [String: Any] = [
                            "id": subcategory.id?.uuidString ?? UUID().uuidString,
                            "name": subcategory.name ?? "Unnamed Subcategory",
                            "colorHex": subcategory.colorHex ?? category.colorHex ?? "#007AFF",
                            "createdAt": ISO8601DateFormatter().string(from: subcategory.createdAt ?? Date()),
                            "updatedAt": ISO8601DateFormatter().string(from: subcategory.updatedAt ?? Date()),
                            "notes": []
                        ]
                        
                        // Add notes for this subcategory
                        if let subNotes = subcategory.notes as? Set<Note> {
                            subcategoryDict["notes"] = subNotes.map { self.noteToDict($0) }
                        }
                        
                        subcategoriesArray.append(subcategoryDict)
                    }
                    
                    categoryDict["subcategories"] = subcategoriesArray
                }
                
                categoriesArray.append(categoryDict)
            }
            
            exportData["categories"] = categoriesArray
            
            // Fetch unlisted notes (notes without a category)
            let unlistedRequest = Note.fetchRequest(NSPredicate(format: "category == nil"))
            let unlistedNotes = try context.fetch(unlistedRequest)
            exportData["unlistedNotes"] = unlistedNotes.map { self.noteToDict($0) }
            
            // Convert to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            
            // Create a temporary file
            let temporaryDirectory = FileManager.default.temporaryDirectory
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateString = dateFormatter.string(from: Date())
            let fileName = "NotesExport_\(dateString).json"
            let fileURL = temporaryDirectory.appendingPathComponent(fileName)
            
            // Write to file
            try jsonData.write(to: fileURL)
            completion(fileURL, nil)
            
        } catch {
            print("Error exporting data: \(error)")
            completion(nil, error)
        }
    }
    
    // Helper function to convert a Note to a dictionary
    private func noteToDict(_ note: Note) -> [String: Any] {
        return [
            "id": note.id?.uuidString ?? UUID().uuidString,
            "title": note.title ?? "Untitled Note",
            "content": note.content ?? "",
            "createdAt": ISO8601DateFormatter().string(from: note.createdAt ?? Date()),
            "updatedAt": ISO8601DateFormatter().string(from: note.updatedAt ?? Date())
        ]
    }
    
    // Function to present a save dialog and save the exported file
    private func saveExportedFile(sourceURL: URL, completion: @escaping (Bool) -> Void) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType(filenameExtension: "json")!]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Save Notes Export"
        savePanel.message = "Choose a location to save your notes export"
        savePanel.nameFieldLabel = "Export file name:"
        savePanel.nameFieldStringValue = sourceURL.lastPathComponent
        
        savePanel.begin { result in
            if result == .OK, let targetURL = savePanel.url {
                do {
                    if FileManager.default.fileExists(atPath: targetURL.path) {
                        try FileManager.default.removeItem(at: targetURL)
                    }
                    try FileManager.default.copyItem(at: sourceURL, to: targetURL)
                    completion(true)
                } catch {
                    print("Error saving file: \(error)")
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
}
