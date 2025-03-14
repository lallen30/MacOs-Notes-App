import SwiftUI
import CoreData
import Combine

struct ContentView: View {
    // Helper function to convert hex to Color
    private func getColorFromHex(_ hex: String) -> Color {
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
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedNote: Note?
    @State private var selectedCategory: Category?
    @State private var showingCreateSheet = false
    @State private var showingEditSheet = false
    @State private var showingCreateCategorySheet = false
    @State private var showingEditCategorySheet = false
    @State private var searchText = ""
    @State private var sortField = "updatedAt"
    @State private var sortAscending = false
    @State private var refreshCategoryList = false
    @State private var showUnlistedCategory = false
    
    var body: some View {
        NavigationView {
            // Left sidebar - Either Categories list or Notes list for selected category
            if selectedCategory != nil || showUnlistedCategory {
                // Notes list for selected category
                VStack {
                    // Category header with separate lines for back button and title
                    VStack(spacing: 2) {
                        // Back button on first line
                        HStack {
                            Button(action: {
                                selectedCategory = nil
                                showUnlistedCategory = false
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .help("Back to categories")
                            
                            Spacer()
                        }
                        
                        // Category title on second line
                        if let category = selectedCategory {
                            HStack {
                                Circle()
                                    .fill(getColorFromHex(category.colorHex ?? "007AFF")) // Use actual category color
                                    .frame(width: 16, height: 16)
                                
                                Text(category.name ?? "Unnamed")
                                    .font(.headline)
                                
                                Button(action: {
                                    showingEditCategorySheet = true
                                }) {
                                    Image(systemName: "pencil")
                                        .font(.caption)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .help("Edit category")
                                
                                Spacer()
                            }
                        } else if showUnlistedCategory {
                            HStack {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 16, height: 16)
                                
                                Text("Unlisted Notes")
                                    .font(.headline)
                                
                                Spacer()
                            }
                        }
                        
                        // Sort label on its own line
                        HStack {
                            Text("Sort by:")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Spacer()
                        }
                        
                        // Sort dropdowns and add button
                        HStack {
                            // Sort options
                            HStack(spacing: 8) {
                                Picker("", selection: $sortField) {
                                    Text("Last Updated").tag("updatedAt")
                                    Text("Date Created").tag("createdAt")
                                    Text("Title").tag("title")
                                    Text("Content").tag("content")
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(width: 140)
                                
                                Picker("", selection: $sortAscending) {
                                    Text("Descending").tag(false)
                                    Text("Ascending").tag(true)
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(width: 120)
                            }
                            
                            Spacer()
                            
                            // Add note button
                            Button(action: {
                                showingCreateSheet = true
                            }) {
                                Image(systemName: "plus")
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .help("Create a new note")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 2)
                    
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Notes list - filtered by selected category or unlisted
                    NoteListView(
                        predicate: createNotePredicate(),
                        sortDescriptors: [createSortDescriptor()],
                        selectedNote: $selectedNote
                    )
                }
            } else {
                // Categories list
                VStack {
                    HStack {
                        Text("Categories")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            showingCreateCategorySheet = true
                        }) {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .help("Create a new category")
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Category list
                    List {
                        // This is just to force a refresh when refreshCategoryList changes
                        if refreshCategoryList { EmptyView() }
                        
                        // Unlisted category option
                        HStack {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 12, height: 12)
                            
                            Text("Unlisted")
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(countUnlistedNotes())")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCategory = nil
                            showUnlistedCategory = true
                        }
                        .background(showUnlistedCategory ? Color.accentColor.opacity(0.1) : Color.clear)
                        
                        // Regular categories
                        ForEach(fetchCategories(), id: \.self) { category in
                            HStack {
                                Circle()
                                    .fill(getColorFromHex(category.colorHex ?? "007AFF")) // Convert hex to Color
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
                                showUnlistedCategory = false
                            }
                            .background(selectedCategory == category && !showUnlistedCategory ? Color.accentColor.opacity(0.1) : Color.clear)
                        }
                        .onDelete(perform: deleteCategories)
                    }
                    .listStyle(SidebarListStyle())
                }
            }
            
            // Right side - Note detail view
            if selectedNote != nil {
                NoteDetailView(note: selectedNote!)
            } else {
                Text("Select a note to view details")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .navigationTitle("Notes")
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CreateNewNote"))) { _ in
            showingCreateSheet = true
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateNoteView()
        }
        .sheet(isPresented: $showingCreateCategorySheet, onDismiss: {
            // Refresh the category list when the sheet is dismissed
            refreshCategoryList.toggle()
        }) {
            CreateCategorySheet()
        }
        .sheet(isPresented: $showingEditCategorySheet, onDismiss: {
            // Refresh the category list when the sheet is dismissed
            refreshCategoryList.toggle()
        }) {
            if let category = selectedCategory {
                EditCategorySheet(category: category)
            }
        }
    }
    
    // MARK: - Category Management Functions
    
    private func fetchCategories() -> [Category] {
        let request = NSFetchRequest<Category>(entityName: "Category")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching categories: \(error.localizedDescription)")
            return []
        }
    }
    
    private func countUnlistedNotes() -> Int {
        let request = NSFetchRequest<Note>(entityName: "Note")
        request.predicate = NSPredicate(format: "category == nil")
        
        do {
            return try viewContext.count(for: request)
        } catch {
            print("Error counting unlisted notes: \(error.localizedDescription)")
            return 0
        }
    }
    
    private func createSortDescriptor() -> NSSortDescriptor {
        switch sortField {
        case "title":
            return NSSortDescriptor(key: "title", ascending: sortAscending)
        case "createdAt":
            return NSSortDescriptor(key: "createdAt", ascending: sortAscending)
        case "content":
            return NSSortDescriptor(key: "content", ascending: sortAscending)
        default: // updatedAt
            return NSSortDescriptor(key: "updatedAt", ascending: sortAscending)
        }
    }
    
    private func createNotePredicate() -> NSPredicate? {
        var predicates: [NSPredicate] = []
        
        // Category filter
        if let category = selectedCategory {
            predicates.append(NSPredicate(format: "category == %@", category))
        } else if showUnlistedCategory {
            predicates.append(NSPredicate(format: "category == nil"))
        }
        
        // Search text filter
        if !searchText.isEmpty {
            let searchPredicate = NSPredicate(format: "title CONTAINS[cd] %@ OR content CONTAINS[cd] %@", searchText, searchText)
            predicates.append(searchPredicate)
        }
        
        // Combine predicates
        if predicates.isEmpty {
            return nil
        } else if predicates.count == 1 {
            return predicates[0]
        } else {
            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
    }
    
    private func deleteCategories(offsets: IndexSet) {
        withAnimation {
            let categories = fetchCategories()
            offsets.map { categories[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
                // Reset selected category if it was deleted
                if let selectedCategory = selectedCategory, 
                   !fetchCategories().contains(where: { $0.id == selectedCategory.id }) {
                    self.selectedCategory = nil
                }
            } catch {
                print("Error deleting category: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Edit Category Sheet
struct EditCategorySheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    var category: Category
    
    @State private var name: String = ""
    @State private var selectedColorIndex: Int = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Define standard colors directly
    private var colorOptions: [(name: String, color: Color, hex: String)] {
        return [
            ("Blue", .blue, "007AFF"),
            ("Red", .red, "FF0000"),
            ("Green", .green, "00FF00"),
            ("Orange", .orange, "FFA500"),
            ("Purple", .purple, "800080"),
            ("Pink", .pink, "FFC0CB"),
            ("Yellow", .yellow, "FFFF00"),
            ("Gray", .gray, "808080")
        ]
    }
    
    init(category: Category) {
        self.category = category
        _name = State(initialValue: category.name ?? "")
        
        // Find the index of the color that matches the category's colorHex
        var index = 0
        if let colorHex = category.colorHex {
            print("DEBUG: EditCategorySheet - Category color hex: \(colorHex)")
            
            // Clean the hex for consistent comparison
            let cleanHex = colorHex.replacingOccurrences(of: "#", with: "").uppercased()
            
            // Try to find the matching color in our predefined options
            for (i, option) in colorOptions.enumerated() {
                let optionHex = option.hex.uppercased()
                if optionHex == cleanHex {
                    print("DEBUG: EditCategorySheet - Found matching color at index \(i): \(option.name)")
                    index = i
                    break
                }
            }
            
            if index == 0 && cleanHex != colorOptions[0].hex.uppercased() {
                print("DEBUG: EditCategorySheet - No matching color found, using default (0)")
            }
        } else {
            print("DEBUG: EditCategorySheet - No color hex in category, using default (0)")
        }
        
        _selectedColorIndex = State(initialValue: index)
    }
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Edit Category")) {
                    TextField("Name", text: $name)
                        .padding(.vertical, 4)
                    
                    Text("Color")
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    // Color presets
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(0..<colorOptions.count, id: \.self) { index in
                            Circle()
                                .fill(colorOptions[index].color)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColorIndex == index ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColorIndex = index
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button("Save") {
                    updateCategory()
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(name.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 300)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func updateCategory() {
        guard !name.isEmpty else { return }
        
        // Get the selected color information
        let selectedColor = colorOptions[selectedColorIndex]
        let hexValue = selectedColor.hex
        
        // Create a clean hex value with proper formatting
        let cleanHexValue = hexValue.replacingOccurrences(of: "#", with: "").uppercased()
        
        // Simple direct approach - modify the category directly
        category.name = self.name
        category.colorHex = cleanHexValue
        category.updatedAt = Date()
        
        do {
            try viewContext.save()
            print("Category updated successfully")
            
            // Send a simple notification
            if let categoryID = category.id {
                NotificationCenter.default.post(
                    name: NSNotification.Name("CategoryColorChanged"),
                    object: nil,
                    userInfo: [
                        "categoryID": categoryID,
                        "colorHex": cleanHexValue,
                        "name": self.name
                    ]
                )
            }
            
            // Dismiss the sheet
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error updating category: \(error)")
            alertMessage = "Error updating category: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// MARK: - Create Category Sheet
struct CreateCategorySheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var name: String = ""
    @State private var selectedColor: Color = .blue
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Predefined colors
    private let colors: [Color] = [
        .blue, .red, .green, .orange, .purple, .pink, .yellow, .gray
    ]
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Category Details")) {
                    TextField("Name", text: $name)
                        .padding(.vertical, 4)
                    
                    ColorPicker("Color", selection: $selectedColor)
                        .padding(.vertical, 4)
                    
                    // Color presets
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor.description == color.description ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("Save") {
                    saveCategory()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(name.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 300)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func saveCategory() {
        if name.isEmpty {
            alertMessage = "Please enter a name for your category."
            showingAlert = true
            return
        }
        
        // Convert Color to hex string
        // For simplicity, we'll use predefined colors with their hex values
        let colorHex: String
        switch selectedColor {
        case .blue: colorHex = "#007AFF"
        case .red: colorHex = "#FF3B30"
        case .green: colorHex = "#34C759"
        case .orange: colorHex = "#FF9500"
        case .purple: colorHex = "#AF52DE"
        case .pink: colorHex = "#FF2D55"
        case .yellow: colorHex = "#FFCC00"
        case .gray: colorHex = "#8E8E93"
        default: colorHex = "#007AFF" // Default blue
        }
        
        // Create the category directly
        let category = Category(context: viewContext)
        category.id = UUID()
        category.name = name
        category.colorHex = colorHex
        category.createdAt = Date()
        category.updatedAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            alertMessage = "Error creating category: \(error.localizedDescription)"
            showingAlert = true
            return
        }
        
        // Dismiss the sheet
        presentationMode.wrappedValue.dismiss()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
