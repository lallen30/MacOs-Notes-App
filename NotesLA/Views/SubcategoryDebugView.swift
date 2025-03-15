import SwiftUI
import CoreData

struct SubcategoryDebugView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var category: Category
    @Binding var refreshTrigger: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Subcategory Debug")
                .font(.headline)
            
            Text("Category: \(category.name ?? "unnamed")")
                .font(.subheadline)
            
            Text("ID: \(category.id?.uuidString ?? "nil")")
                .font(.caption)
            
            let subcategories = fetchSubcategoriesForCategory(category)
            
            Text("Found \(subcategories.count) subcategories")
                .foregroundColor(subcategories.isEmpty ? .red : .green)
            
            Button("Create Test Subcategory") {
                createTestSubcategory()
            }
            .buttonStyle(.borderedProminent)
            
            if !subcategories.isEmpty {
                Text("Subcategories:")
                    .font(.headline)
                    .padding(.top, 8)
                
                ForEach(subcategories, id: \\.self) { subcategory in
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                        Text("\(subcategory.name ?? "unnamed")")
                        Spacer()
                        Text("ID: \(subcategory.id?.uuidString ?? "nil")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func fetchSubcategoriesForCategory(_ category: Category) -> [SubCategory] {
        let request = NSFetchRequest<SubCategory>(entityName: "SubCategory")
        request.predicate = NSPredicate(format: "parentCategory == %@", category)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \\SubCategory.name, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching subcategories: \(error.localizedDescription)")
            return []
        }
    }
    
    private func createTestSubcategory() {
        let subcategory = SubCategory.create(
            name: "Test Subcategory \(Int(Date().timeIntervalSince1970))",
            parentCategory: category,
            colorHex: "#FF0000",
            context: viewContext
        )
        
        print("Created subcategory: \(subcategory.name ?? "unnamed") with ID \(subcategory.id?.uuidString ?? "nil")")
        refreshTrigger.toggle()
    }
}
