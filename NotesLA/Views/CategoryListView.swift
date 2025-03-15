import SwiftUI
import CoreData

struct CategoryListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Use a state variable to trigger refresh
    @State private var refreshID = UUID()
    
    // Create the fetch request using a function to allow refreshing
    private var categoriesFetchRequest: FetchRequest<Category>
    private var categories: FetchedResults<Category> {
        categoriesFetchRequest.wrappedValue
    }
    
    @Binding var selectedCategory: Category?
    
    init(selectedCategory: Binding<Category?>) {
        self._selectedCategory = selectedCategory
        self.categoriesFetchRequest = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
            animation: .default
        )
    }
    
    var body: some View {
        List {
            ForEach(categories, id: \.self) { category in
                HStack {
                    // Get the hex value and convert to a color directly
                    let hexValue = category.colorHex ?? "007AFF"
                    
                    // Print debug info for each category
                    print("DEBUG: CategoryListView - Category: \(category.name ?? "Unnamed"), colorHex: \(hexValue)")
                    
                    // Use the CategoryTag's color mapping for consistency
                    let color = CategoryTag.getColorFromHex(hexValue)
                    
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                    
                    Text(category.name ?? "Unnamed")
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("\(category.notes?.count ?? 0)")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedCategory = category
                }
                .background(selectedCategory == category ? Color.accentColor.opacity(0.1) : Color.clear)
            }
            .onDelete(perform: deleteCategories)
        }
        .listStyle(SidebarListStyle())
        .id(refreshID) // Force view to refresh when this ID changes
        .onAppear {
            // Force refresh when view appears
            refreshID = UUID()
            print("DEBUG: CategoryListView appeared, refreshing view")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CategoryColorChanged"))) { notification in
            print("DEBUG: Received CategoryColorChanged notification")
            
            // Extract information from the notification
            if let categoryID = notification.userInfo?["categoryID"] as? UUID,
               let colorHex = notification.userInfo?["colorHex"] as? String,
               let systemColorName = notification.userInfo?["systemColorName"] as? String {
                
                print("DEBUG: Notification for category ID: \(categoryID)")
                print("DEBUG: Notification includes colorHex: \(colorHex)")
                print("DEBUG: Notification includes systemColorName: \(systemColorName)")
                
                // Force refresh the view
                DispatchQueue.main.async {
                    // This is a more aggressive refresh that recreates the fetch request
                    self.categoriesFetchRequest = FetchRequest(
                        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
                        animation: .default
                    )
                    
                    self.refreshID = UUID()
                    print("DEBUG: Forced complete refresh with new ID: \(self.refreshID)")
                }
            } else if let categoryID = notification.userInfo?["categoryID"] as? UUID {
                print("DEBUG: Notification for category ID only: \(categoryID)")
                
                // Simple refresh
                DispatchQueue.main.async {
                    self.refreshID = UUID()
                    print("DEBUG: Simple refresh with new ID: \(self.refreshID)")
                }
            } else {
                // General refresh if no specific category ID
                DispatchQueue.main.async {
                    self.refreshID = UUID()
                    print("DEBUG: General refresh with new ID: \(self.refreshID)")
                }
            }
        }
    }
    
    private func deleteCategories(offsets: IndexSet) {
        withAnimation {
            offsets.map { categories[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Handle the error
                print("Error deleting category: \(error.localizedDescription)")
            }
        }
    }
    
    // Helper function to directly map hex strings to SwiftUI colors
    // We're now using CategoryTag's getColorFromHex for consistency
    

}

struct CategoryListView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryListView(selectedCategory: .constant(nil))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
