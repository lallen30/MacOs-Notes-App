import Foundation
import CoreData
import SwiftUI

struct ImportUtility {
    
    // Main import function that reads a JSON file and imports all categories and notes
    static func importData(from url: URL, context: NSManagedObjectContext, completion: @escaping (Bool, Error?) -> Void) {
        do {
            // Read the file
            let data = try Data(contentsOf: url)
            
            // Parse JSON
            guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                completion(false, NSError(domain: "ImportUtility", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"]))
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
            completion(true, nil)
            
        } catch {
            print("Error importing data: \(error)")
            completion(false, error)
        }
    }
    
    // Import a category and its notes and subcategories
    private static func importCategory(from dict: [String: Any], context: NSManagedObjectContext) {
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
                for noteDict in notes {
                    importNote(from: noteDict, category: category, subcategory: nil, context: context)
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
    private static func importSubcategory(from dict: [String: Any], parentCategory: Category, context: NSManagedObjectContext) {
        guard let name = dict["name"] as? String else { return }
        
        // Check if subcategory already exists
        let fetchRequest: NSFetchRequest<SubCategory> = SubCategory.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@ AND category == %@", name, parentCategory)
        
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
                subcategory.category = parentCategory
                
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
                    importNote(from: noteDict, category: parentCategory, subcategory: subcategory, context: context)
                }
            }
            
        } catch {
            print("Error fetching subcategory: \(error)")
        }
    }
    
    // Import a note
    private static func importNote(from dict: [String: Any], category: Category?, subcategory: SubCategory?, context: NSManagedObjectContext) {
        guard let title = dict["title"] as? String else { return }
        let content = dict["content"] as? String ?? ""
        
        // For notes, we don't check for duplicates - we'll create a new note each time
        // This is because notes with the same title might have different content
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
    }
    
    // Function to present an open dialog and import the selected file
    static func openImportFile(completion: @escaping (URL?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.title = "Import Notes"
        openPanel.message = "Choose a notes export file to import"
        
        openPanel.begin { result in
            if result == .OK, let url = openPanel.url {
                completion(url)
            } else {
                completion(nil)
            }
        }
    }
}

// Extension to support UTType for macOS
extension UTType {
    static var json: UTType {
        UTType(filenameExtension: "json")!
    }
}
