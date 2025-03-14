import Foundation
import CoreData
import SwiftUI

extension Category {
    static func fetchRequest(_ predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) -> NSFetchRequest<Category> {
        let request = NSFetchRequest<Category>(entityName: "Category")
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors.isEmpty ? [NSSortDescriptor(keyPath: \Category.name, ascending: true)] : sortDescriptors
        return request
    }
    
    static func create(name: String, colorHex: String? = nil, context: NSManagedObjectContext) -> Category {
        let category = Category(context: context)
        category.id = UUID()
        category.name = name
        category.colorHex = colorHex ?? "#007AFF" // Default blue color
        category.createdAt = Date()
        category.updatedAt = Date()
        
        do {
            try context.save()
            return category
        } catch {
            print("Error creating category: \(error)")
            return category
        }
    }
    
    func update(name: String, colorHex: String? = nil, context: NSManagedObjectContext) {
        print("DEBUG: Category.update() called")
        print("DEBUG: Current colorHex: \(self.colorHex ?? "nil")")
        
        self.name = name
        if let colorHex = colorHex {
            print("DEBUG: Setting new colorHex: \(colorHex)")
            self.colorHex = colorHex
        }
        self.updatedAt = Date()
        
        do {
            try context.save()
            print("DEBUG: Category saved successfully. New colorHex: \(self.colorHex ?? "nil")")
            
            // Verify the save by fetching the category again
            let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", self.id! as CVarArg)
            
            if let fetchedCategories = try? context.fetch(fetchRequest), let fetchedCategory = fetchedCategories.first {
                print("DEBUG: Fetched category after save. colorHex: \(fetchedCategory.colorHex ?? "nil")")
            }
            
        } catch {
            print("ERROR: Failed to update category: \(error)")
        }
    }
    
    var color: Color {
        // Direct mapping from hex to SwiftUI colors
        switch colorHex {
        case "#FF0000": return .red
        case "#00FF00": return .green
        case "#0000FF", "#007AFF": return .blue
        case "#FFA500": return .orange
        case "#800080": return .purple
        case "#FFC0CB": return .pink
        case "#FFFF00": return .yellow
        case "#808080": return .gray
        default: return .blue // Default to blue if no match
        }
    }
    
    var noteCount: Int {
        return notes?.count ?? 0
    }
    
    var subcategoryCount: Int {
        return subcategories?.count ?? 0
    }
    
    var totalNoteCount: Int {
        let directNotes = noteCount
        let subcategoryNotes = (subcategories as? Set<SubCategory>)?.reduce(0) { $0 + ($1.notes?.count ?? 0) } ?? 0
        return directNotes + subcategoryNotes
    }
}

// Color extension is now in Extensions/Color+Extension.swift
