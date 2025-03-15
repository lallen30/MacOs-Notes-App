import SwiftUI
import CoreData
import Combine

// Import CategoryTag component

// MARK: - CategoryStore
/// Custom ObservableObject to manually manage category data
class CategoryStore: ObservableObject {
    @Published var categories: [Category] = []
    private var viewContext: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        loadCategories()
        
        // Setup improved notification handling
        NotificationCenter.default.publisher(for: NSNotification.Name("CategoryColorChanged"))
            .sink { [weak self] notification in
                print("DEBUG: CategoryStore - Received category change notification")
                
                // Reset the context to ensure we're getting fresh data
                self?.viewContext.reset()
                
                // Process category update info
                if let categoryID = notification.userInfo?["categoryID"] as? UUID {
                    print("DEBUG: CategoryStore - Processing notification for category \(categoryID)")
                    
                    if let colorHex = notification.userInfo?["colorHex"] as? String {
                        print("DEBUG: CategoryStore - Color update: \(colorHex)")
                    }
                    
                    if let name = notification.userInfo?["name"] as? String {
                        print("DEBUG: CategoryStore - Name update: \(name)")
                    }
                    
                    // Force a full reload - this is more reliable than partial updates
                    DispatchQueue.main.async {
                        self?.loadCategories()
                    }
                } else {
                    // If no specific category ID, do a full reload
                    print("DEBUG: CategoryStore - No specific category ID, doing full reload")
                    DispatchQueue.main.async {
                        self?.loadCategories()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Enhanced force refresh handler
        NotificationCenter.default.publisher(for: NSNotification.Name("ForceUIRefresh"))
            .sink { [weak self] notification in
                print("DEBUG: CategoryStore - Received force refresh notification")
                
                // Extra debug info
                if let source = notification.userInfo?["source"] as? String {
                    print("DEBUG: CategoryStore - Force refresh from source: \(source)")
                }
                
                // Reset context and force reload on main thread
                DispatchQueue.main.async {
                    self?.viewContext.reset()
                    self?.loadCategories()
                    // Force the UI to update by sending an objectWillChange notification
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadCategories() {
        print("DEBUG: CategoryStore - Starting full categories load with FORCED REFRESH")
        
        // CRITICAL: Force context to discard all objects and reload from persistent store
        viewContext.reset()
        
        let request = NSFetchRequest<Category>(entityName: "Category")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        
        do {
            // Perform fetch with refreshed options to guarantee we get fresh data
            let fetchedCategories = try viewContext.fetch(request)
            print("DEBUG: CategoryStore - Loaded \(fetchedCategories.count) categories")
            
            // Print detailed debug info for each category
            for category in fetchedCategories {
                print(">>> CATEGORY: \(category.name ?? "Unnamed")")
                print("    - ID: \(category.id?.uuidString ?? "nil")")
                print("    - Color: \(category.colorHex ?? "nil")")
                print("    - Updated: \(category.updatedAt ?? Date())")
            }
            
            // CRITICAL: Update on main thread with deliberate steps to force UI refresh
            DispatchQueue.main.async {
                // Step 1: Notify observers BEFORE changing the array
                self.objectWillChange.send()
                
                // Step 2: Create a FRESH ARRAY to prevent reference issues
                self.categories = []
                
                // Step 3: Refill with fetched categories after a tiny delay
                DispatchQueue.main.async {
                    self.categories = fetchedCategories
                    
                    // Step 4: Send another change notification to be sure
                    self.objectWillChange.send()
                    
                    print("DEBUG: CategoryStore - SUCCESSFULLY updated categories with forced refresh")
                }
            }
        } catch {
            print("ERROR: CategoryStore - Failed to fetch categories: \(error)")
        }
    }
    
    // Helper method to refresh a specific category
    func refreshSpecificCategory(_ categoryID: UUID) {
        print("DEBUG: CategoryStore - Refreshing specific category: \(categoryID)")
        
        // Reset context to ensure fresh data
        viewContext.reset()
        
        let request = NSFetchRequest<Category>(entityName: "Category")
        request.predicate = NSPredicate(format: "id == %@", categoryID as CVarArg)
        request.fetchLimit = 1
        
        do {
            if let updatedCategory = try viewContext.fetch(request).first {
                print("DEBUG: CategoryStore - Got updated category: \(updatedCategory.name ?? "Unnamed"), color: \(updatedCategory.colorHex ?? "nil")")
                
                // Find and update this category in our array
                DispatchQueue.main.async {
                    if let index = self.categories.firstIndex(where: { $0.id == categoryID }) {
                        // Replace the category at that index
                        self.categories[index] = updatedCategory
                        print("DEBUG: CategoryStore - Updated category at index \(index)")
                        self.objectWillChange.send()
                    } else {
                        // If not found, do a full reload
                        print("DEBUG: CategoryStore - Category not found in array, doing full reload")
                        self.loadCategories()
                    }
                }
            } else {
                print("DEBUG: CategoryStore - Category \(categoryID) not found, doing full reload")
                loadCategories()
            }
        } catch {
            print("ERROR: CategoryStore - Failed to refresh specific category: \(error)")
            loadCategories()
        }
    }
    
    func getCategoryColor(_ category: Category) -> Color {
        // Simple approach - just use the color directly from the category
        let hex = category.colorHex ?? "007AFF"
        return getColorFromHex(hex)
    }
    
    // Helper function to convert hex to Color
    func getColorFromHex(_ hex: String) -> Color {
        // Remove # if present and convert to uppercase for consistent comparison
        let cleanHex = hex.replacingOccurrences(of: "#", with: "").uppercased()
        
        // Direct mapping to SwiftUI system colors
        switch cleanHex {
        case "007AFF": return .blue
        case "FF0000": return .red
        case "00FF00": return .green
        case "FFA500": return .orange
        case "800080": return .purple
        case "FFC0CB": return .pink
        case "FFFF00": return .yellow
        case "808080": return .gray
        default:
            // For any other hex values, use blue as fallback
            return .blue
        }
    }
    
    // Helper method to get the most up-to-date category name directly from Core Data
    func getCategoryName(_ category: Category) -> String {
        guard let categoryID = category.id else {
            print("WARNING: CategoryStore - Called getCategoryName with category that has no ID")
            return category.name ?? "Unnamed"
        }
        
        // Reset context to clear any cached objects
        viewContext.reset()
        
        let request = NSFetchRequest<Category>(entityName: "Category")
        request.predicate = NSPredicate(format: "id == %@", categoryID as CVarArg)
        request.fetchLimit = 1
        
        do {
            if let freshCategory = try viewContext.fetch(request).first {
                return freshCategory.name ?? "Unnamed"
            }
        } catch {
            print("ERROR: CategoryStore - Failed to get fresh category name: \(error)")
        }
        
        // Fallback to the provided category's name
        return category.name ?? "Unnamed"
    }
}

public struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Custom observable store to manage categories
    @StateObject private var categoryStore: CategoryStore
    
    // Init to create the category store
    init() {
        // We need to use _categoryStore because @StateObject can't be set in init directly
        // This is a workaround for that limitation
        _categoryStore = StateObject(wrappedValue: CategoryStore(context: PersistenceController.shared.container.viewContext))
    }
    
    @State private var selectedCategory: Category?
    @State private var selectedSubcategory: SubCategory?
    @State private var selectedNote: Note?
    @State private var showingCreateCategorySheet = false
    @State private var showingCreateSubcategorySheet = false
    @State private var showingCreateNoteSheet = false
    @State private var searchText = ""
    @State private var isSearchFieldFocused = false
    
    // Force refresh flag to ensure UI updates when category colors change
    @State private var forceRefresh: UUID = UUID()
    
    // Add notification observer for category color changes
    init() {
        // Listen for category color changes
        NotificationCenter.default.addObserver(forName: NSNotification.Name("CategoryColorChanged"), object: nil, queue: .main) { [self] _ in
            print("HomeView received CategoryColorChanged notification")
            // Force UI refresh by changing the UUID
            DispatchQueue.main.async {
                self.forceRefresh = UUID()
                // Also reload categories to ensure fresh data
                self.categoryStore.loadCategories()
            }
        }
    }
    
    var body: some View {
        NavigationView {
            // Using id modifier with forceRefresh UUID to ensure complete redraw when needed
            VStack {
                // This Text is invisible but forces the view to refresh when forceRefresh changes
                Text("")
                    .frame(width: 0, height: 0)
                    .opacity(0)
                    .id(forceRefresh)
                // Search field
                TextField("Search notes...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .focused($isSearchFieldFocused)
                
                // Categories and subcategories list
                List {
                    Section(header: Text("All Notes")) {
                        NavigationLink(destination: NoteListView(
                            predicate: nil,
                            sortDescriptors: [NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)],
                            selectedNote: $selectedNote
                        )) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundColor(.blue)
                                Text("All Notes")
                                Spacer()
                                Text("\(totalNoteCount)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tag(nil as Category?)
                    }
                    
                    Section(header: HStack {
                        Text("Categories")
                        Spacer()
                        Button(action: {
                            showingCreateCategorySheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.caption)
                        }
                    }) {
                        if categoryStore.categories.isEmpty {
                            Text("No categories")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(categoryStore.categories, id: \.id) { category in
                                DisclosureGroup {
                                    // Subcategories
                                    if let subcategories = category.subcategories as? Set<SubCategory>, !subcategories.isEmpty {
                                        ForEach(Array(subcategories).sorted(by: { ($0.name ?? "") < ($1.name ?? "") }), id: \.id) { subcategory in
                                            NavigationLink(destination: NoteListView(
                                                predicate: NSPredicate(format: "subcategory == %@", subcategory),
                                                sortDescriptors: [NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)],
                                                selectedNote: $selectedNote
                                            )) {
                                                HStack {
                                                    // Get the hex value and convert to a color using our utility
                                                    let subHexValue = subcategory.colorHex ?? "007AFF"
                                                    
                                                    // Use our local color utility
                                                    let subColor = categoryStore.getColorFromHex(subHexValue)
                                                    
                                                    Circle()
                                                        .fill(subColor)
                                                        .frame(width: 10, height: 10)
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(subcategory.name ?? "Unnamed")
                                                        Text("Color: \(subcategory.colorHex ?? "nil")")
                                                            .font(.system(size: 9))
                                                            .foregroundColor(.gray)
                                                    }
                                                    Spacer()
                                                    Text("\(subcategory.noteCount)")
                                                        .foregroundColor(.secondary)
                                                }
                                                .padding(.leading, 10)
                                            }
                                            .tag(subcategory)
                                        }
                                    }
                                    
                                    // Add subcategory button
                                    Button(action: {
                                        selectedCategory = category
                                        showingCreateSubcategorySheet = true
                                    }) {
                                        Label("Add Subcategory", systemImage: "plus")
                                            .font(.caption)
                                    }
                                    .padding(.leading, 10)
                                    .buttonStyle(.plain)
                                } label: {
                                    NavigationLink(destination: NoteListView(
                                        predicate: NSPredicate(format: "category == %@", category),
                                        sortDescriptors: [NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)],
                                        selectedNote: $selectedNote
                                    )) {
                                        HStack {
                                            // Get the color directly from the category object
                                            // This ensures we're using the actual current value
                                            let colorHex = category.colorHex ?? "007AFF"
                                            Circle()
                                                .fill(categoryStore.getColorFromHex(colorHex))
                                                .frame(width: 12, height: 12)
                                                // Add an ID to force refresh when the forceRefresh UUID changes
                                                .id("circle-\(category.id?.uuidString ?? UUID().uuidString)-\(forceRefresh)")
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(category.name ?? "Unnamed")
                                                    // Add an ID that includes both the category ID and our forceRefresh UUID
                                                    .id("category-\(category.id?.uuidString ?? UUID().uuidString)-\(forceRefresh)")
                                                Text("Color: \(colorHex)")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.red)
                                                    .bold()
                                                    // Add an ID that includes both the category ID, color, and our forceRefresh UUID
                                                    .id("color-\(category.id?.uuidString ?? UUID().uuidString)-\(colorHex)-\(forceRefresh)")
                                            }
                                            Spacer()
                                            Text("\(category.totalNoteCount)")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .tag(category)
                                }
                            }
                            .onDelete(perform: deleteCategories)
                        }
                    }
                    
                    Section {
                        Button(action: {
                            showingCreateNoteSheet = true
                        }) {
                            Label("New Note", systemImage: "square.and.pencil")
                        }
                    }
                }
                .listStyle(SidebarListStyle())
            }
            .frame(minWidth: 250)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        showingCreateCategorySheet = true
                    }) {
                        Label("Add Category", systemImage: "folder.badge.plus")
                    }
                }
            }
            
            // Default view when no note is selected
            Text("Select a category or note")
                .font(.title)
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $showingCreateCategorySheet) {
            CreateCategoryView()
        }
        .sheet(isPresented: $showingCreateSubcategorySheet) {
            if let category = selectedCategory {
                CreateSubcategoryView(parentCategory: category)
            }
        }
        .sheet(isPresented: $showingCreateNoteSheet) {
            CreateNoteView(onSave: { newNote in
                selectedNote = newNote
            })
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CreateNewNote"))) { _ in
            showingCreateNoteSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FocusSearch"))) { _ in
            isSearchFieldFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ForceUIRefresh"))) { _ in
            print("DEBUG: HomeView - Received ForceUIRefresh notification")
            DispatchQueue.main.async {
                // Force refresh the UI
                self.forceRefresh = UUID()
                print("DEBUG: HomeView - Updated forceRefresh to new UUID")
            }
        }
        .id(forceRefresh) // This forces a complete redraw of the view hierarchy when forceRefresh changes
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CategoryColorChanged"))) { notification in
            print("DEBUG: HomeView received CategoryColorChanged notification")
            
            // Extract the category ID from the notification if available
            if let categoryID = notification.userInfo?["categoryID"] as? UUID {
                print("DEBUG: HomeView notification for specific category ID: \(categoryID)")
                
                // Force a refresh of the colors
                forceColorRefresh()
                
                DispatchQueue.main.async {
                    print("DEBUG: HomeView forcing complete UI refresh with new UUID")
                    self.forceRefresh = UUID()
                    
                    // If this is the currently selected category, also refresh it specifically
                    if selectedCategory?.id == categoryID {
                        print("DEBUG: HomeView also refreshing selected category")
                        let tempCategory = selectedCategory
                        selectedCategory = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            selectedCategory = tempCategory
                        }
                    }
                }
            } else {
                // General refresh if no specific category ID
                print("DEBUG: HomeView forcing general refresh (no category ID)")
                
                // Force a refresh of colors
                forceColorRefresh()
                
                DispatchQueue.main.async {
                    // Update forceRefresh to generate a new UUID and force a complete redraw
                    self.forceRefresh = UUID()
                }
            }
        }
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        withAnimation {
            offsets.map { categories[$0] }.forEach { category in
                viewContext.delete(category)
            }
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting categories: \(error)")
            }
        }
    }
    
    private var totalNoteCount: Int {
        let request = Note.fetchRequest()
        do {
            return try viewContext.count(for: request)
        } catch {
            print("Error counting notes: \(error)")
            return 0
        }
    }
    
    // Force a UI refresh using CategoryStore
    private func forceColorRefresh() {
        print("DEBUG: HomeView - Forcing color refresh through CategoryStore")
        DispatchQueue.main.async {
            // Reload categories from Core Data
            categoryStore.loadCategories()
            // Also force a complete view refresh
            self.forceRefresh = UUID()
        }
    }
    
    // Helper function to directly map hex strings to SwiftUI colors
    // This function is no longer needed as we're using ColorUtility
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
