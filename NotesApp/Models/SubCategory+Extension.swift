import Foundation
import CoreData
import SwiftUI

extension SubCategory {
    static func fetchRequest(_ predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) -> NSFetchRequest<SubCategory> {
        let request = NSFetchRequest<SubCategory>(entityName: "SubCategory")
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors.isEmpty ? [NSSortDescriptor(keyPath: \SubCategory.name, ascending: true)] : sortDescriptors
        return request
    }
    
    static func create(name: String, parentCategory: Category, colorHex: String? = nil, context: NSManagedObjectContext) -> SubCategory {
        let subcategory = SubCategory(context: context)
        subcategory.id = UUID()
        subcategory.name = name
        subcategory.colorHex = colorHex ?? parentCategory.colorHex // Inherit parent color if not specified
        subcategory.parentCategory = parentCategory
        subcategory.createdAt = Date()
        subcategory.updatedAt = Date()
        
        do {
            try context.save()
            return subcategory
        } catch {
            print("Error creating subcategory: \(error)")
            return subcategory
        }
    }
    
    func update(name: String, colorHex: String? = nil, context: NSManagedObjectContext) {
        self.name = name
        if let colorHex = colorHex {
            self.colorHex = colorHex
        }
        self.updatedAt = Date()
        
        do {
            try context.save()
        } catch {
            print("Error updating subcategory: \(error)")
        }
    }
    
    var color: Color {
        // Direct mapping from hex to SwiftUI colors
        let hexToUse = colorHex ?? parentCategory?.colorHex ?? "#007AFF"
        
        switch hexToUse {
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
    
    var parentCategoryName: String {
        return parentCategory?.name ?? "Uncategorized"
    }
}
