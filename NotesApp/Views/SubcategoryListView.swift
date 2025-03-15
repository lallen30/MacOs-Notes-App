import SwiftUI
import CoreData

struct SubcategoryListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedNote: Note?
    @Binding var selectedSubcategory: SubCategory?
    
    let category: Category
    let sortField: String
    let sortAscending: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Fetch subcategories for this category
            let subcategories = fetchSubcategoriesForCategory(category)
            
            if subcategories.isEmpty {
                Text("No subcategories found for this category")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(subcategories, id: \\.self) { subcategory in
                    SubcategoryItemView(
                        subcategory: subcategory,
                        selectedNote: $selectedNote,
                        selectedSubcategory: $selectedSubcategory,
                        sortField: sortField,
                        sortAscending: sortAscending
                    )
                }
            }
        }
    }
    
    private func fetchSubcategoriesForCategory(_ category: Category) -> [SubCategory] {
        let request = NSFetchRequest<SubCategory>(entityName: "SubCategory")
        request.predicate = NSPredicate(format: "parentCategory == %@", category)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \\SubCategory.name, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching subcategories: \\(error.localizedDescription)")
            return []
        }
    }
}

struct SubcategoryItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedNote: Note?
    @Binding var selectedSubcategory: SubCategory?
    
    let subcategory: SubCategory
    let sortField: String
    let sortAscending: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(getColorFromHex(subcategory.colorHex ?? "007AFF"))
                    .frame(width: 10, height: 10)
                Text("\\(subcategory.name ?? "Unnamed")")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                
                Button(action: {
                    selectedSubcategory = subcategory
                }) {
                    Text("View All")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .opacity(countNotesInSubcategory(subcategory) > 0 ? 1.0 : 0.0)
            }
            .padding(.horizontal)
            
            // Notes for this subcategory
            NoteListView(
                predicate: NSPredicate(format: "subcategory == %@", subcategory),
                sortDescriptors: [createSortDescriptor(field: sortField, ascending: sortAscending)],
                selectedNote: $selectedNote
            )
            .frame(height: countNotesInSubcategory(subcategory) > 0 ? nil : 50) // Minimum height if empty
        }
        .padding(.top, 8)
    }
    
    private func countNotesInSubcategory(_ subcategory: SubCategory) -> Int {
        let request = NSFetchRequest<Note>(entityName: "Note")
        request.predicate = NSPredicate(format: "subcategory == %@", subcategory)
        
        do {
            return try viewContext.count(for: request)
        } catch {
            print("Error counting notes in subcategory: \\(error.localizedDescription)")
            return 0
        }
    }
    
    private func createSortDescriptor(field: String, ascending: Bool) -> NSSortDescriptor {
        return NSSortDescriptor(key: field, ascending: ascending)
    }
    
    private func getColorFromHex(_ hex: String) -> Color {
        // Direct mapping from hex to SwiftUI colors
        switch hex {
        case "#FF0000": return .red
        case "#00FF00": return .green
        case "#0000FF": return .blue
        case "#FFFF00": return .yellow
        case "#FF00FF": return .purple
        case "#00FFFF": return .cyan
        case "#FFA500": return .orange
        case "#A52A2A": return .brown
        case "#808080": return .gray
        case "#000000": return .black
        default: return .blue
        }
    }
}
