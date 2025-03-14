import Foundation
import CoreData
import SwiftUI

extension Note {
    
    func update(title: String, content: String, category: Category? = nil, subcategory: SubCategory? = nil, context: NSManagedObjectContext) {
        self.title = title
        self.content = content
        self.updatedAt = Date()
        
        // Update category if provided
        if let category = category {
            self.category = category
            
            // If subcategory is provided, ensure it belongs to the selected category
            if let subcategory = subcategory {
                if subcategory.parentCategory == category {
                    self.subcategory = subcategory
                } else {
                    self.subcategory = nil // Clear subcategory if it doesn't belong to the new category
                }
            }
        } else if category == nil && self.category == nil {
            // If no category is provided and note doesn't have a category, set subcategory to nil
            self.subcategory = nil
        }
        
        // Update subcategory if provided
        if let subcategory = subcategory {
            self.subcategory = subcategory
            
            // If the note doesn't have a category, set it to the subcategory's parent
            if self.category == nil {
                self.category = subcategory.parentCategory
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Error updating note: \(error)")
        }
    }
    
    static func fetchRequest(_ predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> NSFetchRequest<Note> {
        let request = NSFetchRequest<Note>(entityName: "Note")
        request.predicate = predicate
        
        if let sortDescriptors = sortDescriptors {
            request.sortDescriptors = sortDescriptors
        } else {
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)]
        }
        
        return request
    }
    
    static func fetchNotesInCategory(_ category: Category?, context: NSManagedObjectContext) -> [Note] {
        var predicate: NSPredicate?
        
        if let category = category {
            predicate = NSPredicate(format: "category == %@", category)
        } else {
            predicate = NSPredicate(format: "category == nil")
        }
        
        let request = fetchRequest(predicate)
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching notes in category: \(error)")
            return []
        }
    }
    
    static func fetchNotesInSubCategory(_ subcategory: SubCategory?, context: NSManagedObjectContext) -> [Note] {
        var predicate: NSPredicate?
        
        if let subcategory = subcategory {
            predicate = NSPredicate(format: "subcategory == %@", subcategory)
        } else {
            predicate = NSPredicate(format: "subcategory == nil")
        }
        
        let request = fetchRequest(predicate)
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching notes in subcategory: \(error)")
            return []
        }
    }
    
    static func searchNotes(searchText: String, category: Category? = nil, subcategory: SubCategory? = nil, context: NSManagedObjectContext) -> [Note] {
        let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", searchText)
        let contentPredicate = NSPredicate(format: "content CONTAINS[cd] %@", searchText)
        let searchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, contentPredicate])
        
        var predicates: [NSPredicate] = [searchPredicate]
        
        // Add category filter if provided
        if let category = category {
            let categoryPredicate = NSPredicate(format: "category == %@", category)
            predicates.append(categoryPredicate)
        }
        
        // Add subcategory filter if provided
        if let subcategory = subcategory {
            let subcategoryPredicate = NSPredicate(format: "subcategory == %@", subcategory)
            predicates.append(subcategoryPredicate)
        }
        
        // Combine all predicates with AND
        let predicate: NSPredicate
        if predicates.isEmpty {
            predicate = NSPredicate(value: true) // Match all notes if no predicates
        } else if predicates.count == 1 {
            predicate = predicates[0]
        } else {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        let request = fetchRequest(predicate)
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error searching notes: \(error)")
            return []
        }
    }
    
    var categoryName: String {
        return category?.name ?? "Uncategorized"
    }
    
    var subcategoryName: String {
        return subcategory?.name ?? "None"
    }
    
    var categoryColor: Color {
        if subcategory != nil {
            return Color.green
        } else if category != nil {
            return Color.blue
        } else {
            return Color.gray
        }
    }
}
