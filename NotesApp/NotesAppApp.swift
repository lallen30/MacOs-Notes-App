import SwiftUI
import UniformTypeIdentifiers
import CoreData
import Foundation
import SwiftUI

// MARK: - Main App

@main
struct NotesAppApp: App {
    let persistenceController = PersistenceController.shared
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportError: String? = nil
    @State private var importError: String? = nil
    @State private var importSuccess = false
    
    // FIXME: HomeView implementation
    // To implement HomeView:
    // 1. Make sure HomeView.swift is properly included in your Xcode project
    // 2. Uncomment the code below and replace ContentView() with HomeView()
    // 3. If you encounter build errors, you may need to fix import paths
    
    var body: some Scene {
        WindowGroup {
            // Using ContentView with subcategory support
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
                .alert("Import Error", isPresented: Binding<Bool>(
                    get: { importError != nil },
                    set: { if !$0 { importError = nil } }
                )) {
                    Button("OK", role: .cancel) { importError = nil }
                } message: {
                    Text(importError ?? "Unknown error occurred during import")
                }
                .alert("Import Successful", isPresented: $importSuccess) {
                    Button("OK", role: .cancel) { importSuccess = false }
                } message: {
                    Text("Notes have been successfully imported.")
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
                
                Button("Import Notes...") {
                    importNotes()
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            }
        }
    }
    
    private func exportAllNotes() {
        isExporting = true
        
        // Export data
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
    
    // Function to handle importing notes from a JSON file
    private func importNotes() {
        isImporting = true
        
        // Present open dialog to select import file
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType(filenameExtension: "json")!]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.title = "Import Notes"
        openPanel.message = "Choose a notes export file to import"
        
        openPanel.begin { result in
            if result == .OK, let url = openPanel.url {
                // Process the selected file
                self.processImportFile(url: url)
            } else {
                DispatchQueue.main.async {
                    self.isImporting = false
                }
            }
        }
    }
    
    // Process the imported file and add data to Core Data
    private func processImportFile(url: URL) {
        let context = persistenceController.container.viewContext
        
        do {
            // Read the file
            let data = try Data(contentsOf: url)
            
            // Parse JSON
            guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                DispatchQueue.main.async {
                    self.importError = "Invalid JSON format"
                    self.isImporting = false
                }
                return
            }
            
            // Process categories
            if let categories = jsonObject["categories"] as? [[String: Any]] {
                for categoryDict in categories {
                    importCategory(from: categoryDict, context: context)
                }
            }
            
            // Process unlisted notes
            if let unlistedNotes = jsonObject["unlistedNotes"] as? [[String: Any]] {
                for noteDict in unlistedNotes {
                    importNote(from: noteDict, category: nil, subcategory: nil, context: context)
                }
            }
            
            // Save changes
            try context.save()
            
            DispatchQueue.main.async {
                self.importSuccess = true
                self.isImporting = false
            }
            
        } catch {
            print("Error importing data: \(error)")
            DispatchQueue.main.async {
                self.importError = "Failed to import notes: \(error.localizedDescription)"
                self.isImporting = false
            }
        }
    }
    
    // Import a category and its notes and subcategories
    private func importCategory(from dict: [String: Any], context: NSManagedObjectContext) {
        guard let name = dict["name"] as? String else { return }
        
        // Check if category already exists
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let existingCategories = try context.fetch(fetchRequest)
            let category: Category
            
            if let existingCategory = existingCategories.first {
                // Use existing category
                category = existingCategory
                
                // Update properties if needed
                if let colorHex = dict["colorHex"] as? String {
                    category.colorHex = colorHex
                }
                
                // Don't update timestamps for existing categories
            } else {
                // Create new category
                category = Category(context: context)
                category.id = UUID()
                category.name = name
                category.colorHex = dict["colorHex"] as? String ?? "#007AFF"
                
                // Set timestamps
                if let createdAtString = dict["createdAt"] as? String, 
                   let createdAt = ISO8601DateFormatter().date(from: createdAtString) {
                    category.createdAt = createdAt
                } else {
                    category.createdAt = Date()
                }
                
                if let updatedAtString = dict["updatedAt"] as? String,
                   let updatedAt = ISO8601DateFormatter().date(from: updatedAtString) {
                    category.updatedAt = updatedAt
                } else {
                    category.updatedAt = Date()
                }
            }
            
            // Import notes for this category
            if let notes = dict["notes"] as? [[String: Any]] {
                // First, collect all note titles from subcategories to avoid duplicates
                var subcategoryNoteTitles = Set<String>()
                if let subcategories = dict["subcategories"] as? [[String: Any]] {
                    for subcategoryDict in subcategories {
                        if let subcategoryNotes = subcategoryDict["notes"] as? [[String: Any]] {
                            for noteDict in subcategoryNotes {
                                if let title = noteDict["title"] as? String {
                                    subcategoryNoteTitles.insert(title)
                                }
                            }
                        }
                    }
                }
                
                // Only import notes that don't exist in subcategories
                for noteDict in notes {
                    if let title = noteDict["title"] as? String, !subcategoryNoteTitles.contains(title) {
                        importNote(from: noteDict, category: category, subcategory: nil, context: context)
                    }
                }
            }
            
            // Import subcategories for this category
            if let subcategories = dict["subcategories"] as? [[String: Any]] {
                for subcategoryDict in subcategories {
                    importSubcategory(from: subcategoryDict, parentCategory: category, context: context)
                }
            }
            
        } catch {
            print("Error fetching category: \(error)")
        }
    }
    
    // Import a subcategory and its notes
    private func importSubcategory(from dict: [String: Any], parentCategory: Category, context: NSManagedObjectContext) {
        guard let name = dict["name"] as? String else { return }
        
        // Check if subcategory already exists
        let fetchRequest: NSFetchRequest<SubCategory> = SubCategory.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@ AND parentCategory == %@", name, parentCategory)
        
        do {
            let existingSubcategories = try context.fetch(fetchRequest)
            let subcategory: SubCategory
            
            if let existingSubcategory = existingSubcategories.first {
                // Use existing subcategory
                subcategory = existingSubcategory
                
                // Update properties if needed
                if let colorHex = dict["colorHex"] as? String {
                    subcategory.colorHex = colorHex
                }
                
                // Don't update timestamps for existing subcategories
            } else {
                // Create new subcategory
                subcategory = SubCategory(context: context)
                subcategory.id = UUID()
                subcategory.name = name
                subcategory.colorHex = dict["colorHex"] as? String ?? parentCategory.colorHex ?? "#007AFF"
                subcategory.parentCategory = parentCategory
                
                // Set timestamps
                if let createdAtString = dict["createdAt"] as? String, 
                   let createdAt = ISO8601DateFormatter().date(from: createdAtString) {
                    subcategory.createdAt = createdAt
                } else {
                    subcategory.createdAt = Date()
                }
                
                if let updatedAtString = dict["updatedAt"] as? String,
                   let updatedAt = ISO8601DateFormatter().date(from: updatedAtString) {
                    subcategory.updatedAt = updatedAt
                } else {
                    subcategory.updatedAt = Date()
                }
            }
            
            // Import notes for this subcategory
            if let notes = dict["notes"] as? [[String: Any]] {
                for noteDict in notes {
                    // Pass nil for category when importing subcategory notes to prevent duplication
                    importNote(from: noteDict, category: nil, subcategory: subcategory, context: context)
                }
            }
            
        } catch {
            print("Error fetching subcategory: \(error)")
        }
    }
    
    // Import a note
    private func importNote(from dict: [String: Any], category: Category?, subcategory: SubCategory?, context: NSManagedObjectContext) {
        guard let title = dict["title"] as? String else { return }
        let content = dict["content"] as? String ?? ""
        
        // Check if a note with the same title and content already exists in the same category/subcategory
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        
        var predicates: [NSPredicate] = [NSPredicate(format: "title == %@", title)]
        
        // Add category predicate if applicable
        if let category = category {
            predicates.append(NSPredicate(format: "category == %@", category))
        } else {
            predicates.append(NSPredicate(format: "category == nil"))
        }
        
        // Add subcategory predicate if applicable
        if let subcategory = subcategory {
            predicates.append(NSPredicate(format: "subcategory == %@", subcategory))
        } else {
            predicates.append(NSPredicate(format: "subcategory == nil"))
        }
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        do {
            let existingNotes = try context.fetch(fetchRequest)
            
            // If a note with the same title already exists in this category/subcategory, skip creating a new one
            if !existingNotes.isEmpty {
                print("Note with title '\(title)' already exists in this location, skipping import")
                return
            }
            
            // Create new note if no duplicate was found
            let note = Note(context: context)
            note.id = UUID()
            note.title = title
            note.content = content
            note.category = category
            note.subcategory = subcategory
            
            // Set timestamps
            if let createdAtString = dict["createdAt"] as? String, 
               let createdAt = ISO8601DateFormatter().date(from: createdAtString) {
                note.createdAt = createdAt
            } else {
                note.createdAt = Date()
            }
            
            if let updatedAtString = dict["updatedAt"] as? String,
               let updatedAt = ISO8601DateFormatter().date(from: updatedAtString) {
                note.updatedAt = updatedAt
            } else {
                note.updatedAt = Date()
            }
        } catch {
            print("Error checking for duplicate notes: \(error)")
        }
    }
}
