import SwiftUI
import CoreData
import Combine

// No need for special imports

// ContentView.swift contains all necessary views for the app

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
    @State private var selectedSubcategory: SubCategory?
    @State private var showingCreateSheet = false
    @State private var showingEditSheet = false
    @State private var showingCreateCategorySheet = false
    @State private var showingEditCategorySheet = false
    @State private var showingCreateSubcategorySheet = false
    @State private var showingEditSubcategorySheet = false
    @State private var selectedSubcategoryForEdit: SubCategory?
    @State private var subcategoryEditName = ""
    @State private var selectedSubcategoryColorIndex: Int = 0
    
    // Define standard colors directly - same as category edit
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
    @State private var searchText = ""
    @State private var sortField = "updatedAt"
    @State private var sortAscending = false
    @State private var refreshCategoryList = false
    @State private var refreshNotesList = UUID() // Add a trigger for refreshing notes list
    @State private var showUnlistedCategory = false
    
    // Setup notification observers for note changes
    private func setupNotificationObservers() {
        // Listen for note changes
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NoteDeleted"), object: nil, queue: .main) { _ in
            // Refresh the notes list when a note is deleted
            self.refreshNotesList = UUID()
        }
        
        // Listen for Core Data changes
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: viewContext, queue: .main) { _ in
            // Refresh the notes list when Core Data changes
            self.refreshNotesList = UUID()
        }
    }
    
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
                                
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showingEditCategorySheet = true
                            }
                            .help("Click to edit this category")
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
                    VStack {
                        if let category = selectedCategory, selectedSubcategory == nil, !showUnlistedCategory {
                            // Hierarchical view for category with subcategories
                            ScrollView {
                                VStack(alignment: .leading, spacing: 12) {
                                    // Section for notes directly in the category
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Spacer().frame(width: 8) // Add left padding to Notes header
                                            Text("Notes")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 2)
                                        
                                        // Notes directly assigned to this category - Direct implementation
                                        VStack {
                                            // This is just to force a refresh when refreshNotesList changes
                                            // Force view refresh when UUID changes
                                            Text("").frame(width: 0, height: 0).id(refreshNotesList)
                                            
                                            // Fetch notes for this category
                                            let directNotes = Note.fetchNotesInCategory(category, context: viewContext).filter { $0.subcategory == nil }
                                            
                                            // Display notes directly - Completely revised implementation
                                            VStack(alignment: .leading, spacing: 0) {
                                                if directNotes.isEmpty {
                                                    Text("No notes in this category")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                        .padding(.vertical, 0)
                                                } else {
                                                    
                                                    ForEach(directNotes, id: \.id) { note in
                                                        HStack {
                                                            Spacer().frame(width: 16)
                                                            Button(action: {
                                                            selectedNote = note
                                                            print("Selected note: \(note.title ?? "Untitled")")
                                                        }) {
                                                            HStack(alignment: .top) {
                                                                Spacer().frame(width: 6) // Add a few pixels of inside padding
                                                                VStack(alignment: .leading, spacing: 0) {
                                                                    Text(note.title ?? "Untitled")
                                                                        .font(.headline)
                                                                        .foregroundColor(.primary)
                                                                        .lineLimit(1)
                                                                    
                                                                    if let content = note.content, !content.isEmpty {
                                                                        Text(content)
                                                                            .font(.subheadline)
                                                                            .foregroundColor(.secondary)
                                                                            .lineLimit(2)
                                                                    }
                                                                }
                                                                Spacer()
                                                            }
                                                            .padding(.vertical, 1) // Reduced padding
                                                            .frame(maxWidth: .infinity, alignment: .leading)
                                                            .background(selectedNote?.id == note.id ? Color.accentColor.opacity(0.2) : Color(NSColor.windowBackgroundColor))
                                                            .cornerRadius(4)
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 4)
                                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                            )
                                                        }
                                                        .buttonStyle(PlainButtonStyle())
                                                        }
                                                    }
                                                }
                                            }
                                            .frame(minHeight: 0)
                                        }
                                    }
                                    
                                    // Subcategory section header
                                    HStack {
                                        Spacer().frame(width: 8) // Add left padding to Subcategories header
                                        Text("Subcategories")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        
                                        Button(action: {
                                            showingCreateSubcategorySheet = true
                                        }) {
                                            Label("Add Subcategory", systemImage: "plus")
                                                .font(.caption)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 1)
                                    .padding(.top, 0)
                                    
                                    // Fetch subcategories directly
                                    let subcategories = fetchSubcategoriesForCategory(category)
                                    
                                    // Also try to get subcategories directly from the relationship
                                    let directSubcategories = category.subcategories as? Set<SubCategory> ?? []
                                    
                                    if subcategories.isEmpty && directSubcategories.isEmpty {
                                        HStack {
                                            Spacer().frame(width: 20) // Added left spacing
                                            Text("No subcategories found")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 2)
                                        .padding(.top, 0)
                                    } else {
                                        // Try both sources of subcategories
                                        let combinedSubcategories = subcategories.isEmpty ? Array(directSubcategories) : subcategories
                                        ForEach(combinedSubcategories, id: \.self) { subcategory in
                                            VStack(alignment: .leading, spacing: 0) {
                                                HStack {
                                                    // Left margin for subcategory titles
                                                    Spacer().frame(width: 16)
                                                    
                                                    Circle()
                                                        .fill(getColorFromHex(subcategory.colorHex ?? "007AFF"))
                                                        .frame(width: 10, height: 10)
                                                    Text(subcategory.name ?? "Unnamed")
                                                        .font(.headline)
                                                        .foregroundColor(.primary)
                                                        .onTapGesture {
                                                            selectedSubcategoryForEdit = subcategory
                                                            subcategoryEditName = subcategory.name ?? ""
                                                            
                                                            // Find the matching color index
                                                            let colorHex = subcategory.colorHex ?? "007AFF"
                                                            let cleanHex = colorHex.replacingOccurrences(of: "#", with: "").uppercased()
                                                            
                                                            // Find matching color in our options
                                                            var index = 0 // Default to blue
                                                            for (i, option) in colorOptions.enumerated() {
                                                                if option.hex.uppercased() == cleanHex {
                                                                    index = i
                                                                    break
                                                                }
                                                            }
                                                            
                                                            selectedSubcategoryColorIndex = index
                                                            showingEditSubcategorySheet = true
                                                        }
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
                                                .padding(.horizontal, 2)
                                                .padding(.bottom, 2) // Add padding below subcategory
                                                
                                                // Notes for this subcategory - Direct implementation
                                                VStack {
                                                    // This is just to force a refresh when refreshNotesList changes
                                                    // Force view refresh when UUID changes
                                                    Text("").frame(width: 0, height: 0).id(refreshNotesList)
                                                    
                                                    // Fetch notes for this subcategory
                                                    let subcategoryNotes = Note.fetchNotesInSubCategory(subcategory, context: viewContext)
                                                    
                                                    // Display notes directly - Completely revised implementation
                                                    VStack(alignment: .leading, spacing: 1) {
                                                        if subcategoryNotes.isEmpty {
                                                            HStack {
                                                                Spacer().frame(width: 20) // Added left spacing
                                                                Text("No notes in this subcategory")
                                                                    .font(.caption)
                                                                    .foregroundColor(.secondary)
                                                                Spacer()
                                                            }
                                                            .padding(.vertical, 0)
                                                        } else {
                                                            
                                                            ForEach(subcategoryNotes, id: \.id) { note in
                                                                Button(action: {
                                                                    selectedNote = note
                                                                    print("Selected note: \(note.title ?? "Untitled")")
                                                                }) {
                                                                    HStack(spacing: 0) {
                                                                        // Left margin outside the note background
                                                                        Spacer().frame(width: 20)
                                                                        
                                                                        // Note content with background
                                                                        HStack(alignment: .top) {
                                                                            VStack(alignment: .leading, spacing: 0) {
                                                                                Text(note.title ?? "Untitled")
                                                                                    .font(.headline)
                                                                                    .foregroundColor(.primary)
                                                                                    .lineLimit(1)
                                                                                
                                                                                if let content = note.content, !content.isEmpty {
                                                                                    Text(content)
                                                                                        .font(.subheadline)
                                                                                        .foregroundColor(.secondary)
                                                                                        .lineLimit(2)
                                                                                }
                                                                            }
                                                                            .padding(.leading, 4) // Add a few pixels of padding inside
                                                                            Spacer()
                                                                        }
                                                                        .padding(.vertical, 4) // Increased vertical padding
                                                                        .padding(.horizontal, 2) // Add horizontal padding
                                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                                        .background(selectedNote?.id == note.id ? Color.accentColor.opacity(0.2) : Color(NSColor.windowBackgroundColor))
                                                                        .cornerRadius(4)
                                                                        .overlay(
                                                                            RoundedRectangle(cornerRadius: 4)
                                                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                                        )
                                                                    }
                                                                }
                                                                .buttonStyle(PlainButtonStyle())
                                                            }
                                                        }
                                                    }
                                                    .frame(minHeight: 0)
                                                }
                                            }
                                            .padding(.top, 0)
                                        }
                                    }
                                }
                                .padding(.vertical, 0)
                            }
                        } else {
                            // Display subcategory header if a subcategory is selected
                            if let subcategory = selectedSubcategory {
                                // Subcategory header with back button
                                HStack(spacing: 4) {
                                    // Back button to parent category
                                    if let parentCategory = subcategory.parentCategory {
                                        Button(action: {
                                            // Go back to parent category view
                                            selectedSubcategory = nil
                                            selectedCategory = parentCategory
                                        }) {
                                            Image(systemName: "chevron.left")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    
                                    // Subcategory circle and title
                                    Circle()
                                        .fill(getColorFromHex(subcategory.colorHex ?? "007AFF"))
                                        .frame(width: 12, height: 12)
                                    Text("\(subcategory.name ?? "Unnamed")") 
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(.horizontal, 2)
                                .padding(.bottom, 2)
                            }
                            
                            // Standard note list for subcategory or unlisted views
                            NoteListView(
                                predicate: createNotePredicate(),
                                sortDescriptors: [createSortDescriptor()],
                                selectedNote: $selectedNote
                            )
                        }
                    }
                }
            } else {
                // Categories list
                VStack {
                    HStack {
                        Text("Categories Content")
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
                        
                        // Regular categories with subcategories
                        ForEach(fetchCategories(), id: \.self) { category in
                            // Custom DisclosureGroup with separate clickable areas
                            DisclosureGroup {
                                // Subcategories
                                if let subcategories = category.subcategories as? Set<SubCategory>, !subcategories.isEmpty {
                                    ForEach(Array(subcategories).sorted(by: { ($0.name ?? "") < ($1.name ?? "") }), id: \.self) { subcategory in
                                        HStack {
                                            Circle()
                                                .fill(getColorFromHex(subcategory.colorHex ?? "007AFF"))
                                                .frame(width: 10, height: 10)
                                            
                                            Text(subcategory.name ?? "Unnamed")
                                                .lineLimit(1)
                                                .font(.system(size: 13))
                                            
                                            Spacer()
                                            
                                            // Count notes in this subcategory
                                            Text("\(countNotesInSubcategory(subcategory))")
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                        }
                                        .padding(.leading, 10)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedCategory = category
                                            selectedSubcategory = subcategory
                                            showUnlistedCategory = false
                                        }
                                        .background(selectedSubcategory == subcategory ? Color.accentColor.opacity(0.1) : Color.clear)
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
                                HStack {
                                    // Make the circle and title clickable for selection or editing
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(getColorFromHex(category.colorHex ?? "007AFF"))
                                            .frame(width: 12, height: 12)
                                        
                                        Text(category.name ?? "Unnamed")
                                            .lineLimit(1)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        // If we're already on this category's screen, clicking opens edit sheet
                                        if selectedCategory == category && selectedSubcategory == nil && !showUnlistedCategory {
                                            showingEditCategorySheet = true
                                        } else {
                                            // Otherwise, just select the category
                                            selectedCategory = category
                                            selectedSubcategory = nil
                                            showUnlistedCategory = false
                                        }
                                    }
                                    .help(selectedCategory == category && selectedSubcategory == nil && !showUnlistedCategory ? 
                                          "Click to edit this category" : 
                                          "Click to select this category")
                                    
                                    Spacer()
                                    
                                    // Count only notes directly assigned to this category (not in subcategories)
                                    Text("\(countNotesInCategory(category))")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                        // Make the count area clickable for selection
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            // Clicking on the count selects the category
                                            selectedCategory = category
                                            selectedSubcategory = nil
                                            showUnlistedCategory = false
                                        }
                                }
                                .background(selectedCategory == category && selectedSubcategory == nil && !showUnlistedCategory ? Color.accentColor.opacity(0.1) : Color.clear)
                                .contextMenu {
                                    // Only show edit option if we're on this category's screen
                                    if selectedCategory == category && selectedSubcategory == nil && !showUnlistedCategory {
                                        Button("Edit Category") {
                                            showingEditCategorySheet = true
                                        }
                                    } else {
                                        Button("Select Category") {
                                            selectedCategory = category
                                            selectedSubcategory = nil
                                            showUnlistedCategory = false
                                        }
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteCategories)
                    }
                    .listStyle(SidebarListStyle())
                }
            }
            
            // Right side - Note detail view
            if selectedNote != nil {
                HStack(alignment: .top, spacing: 0) {
                    // Left margin spacer
                    Spacer().frame(width: 16)
                    
                    // Note detail view
                    NoteDetailView(note: selectedNote!)
                }
            } else {
                VStack {
                    if let category = selectedCategory {
                        if let subcategory = selectedSubcategory {
                            Text("Select a note from \(subcategory.name ?? "Unnamed") subcategory")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Select a note from \(category.name ?? "Unnamed") category")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    } else if showUnlistedCategory {
                        Text("Select a note from Unlisted category")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Select a note to view details")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            setupNotificationObservers()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Spacer().frame(width: 8) // Reduced left padding by half
                    Text("Notes")
                        .font(.title2) // Using title2 to match macOS standard title size
                        .fontWeight(.semibold) // Adding semibold weight for better visibility
                        .foregroundColor(.primary)
                    Spacer() // Push the title to the left
                }
            }
        }
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
        .sheet(isPresented: $showingCreateSubcategorySheet, onDismiss: {
            // Refresh the category list when the sheet is dismissed
            refreshCategoryList.toggle()
        }) {
            if let category = selectedCategory {
                CreateSubcategorySheet(parentCategory: category)
            }
        }
        .sheet(isPresented: $showingEditSubcategorySheet, onDismiss: {
            refreshNotesList = UUID()
        }) {
            VStack(spacing: 20) {
                // Title
                Text("Edit Subcategory")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 10)
                    .padding(.horizontal)
                
                // Name field
                HStack {
                    Text("Name")
                        .frame(width: 60, alignment: .leading)
                    TextField("", text: $subcategoryEditName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // Color section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Color")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Color grid - 4x2 layout
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                        ForEach(0..<colorOptions.count, id: \.self) { index in
                            Circle()
                                .fill(colorOptions[index].color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedSubcategoryColorIndex == index ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedSubcategoryColorIndex = index
                                }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Buttons
                HStack {
                    Button(action: {
                        // Delete subcategory
                        if let subcategory = selectedSubcategoryForEdit {
                            viewContext.delete(subcategory)
                            do {
                                try viewContext.save()
                                showingEditSubcategorySheet = false
                            } catch {
                                print("Error deleting subcategory: \(error)")
                            }
                        }
                    }) {
                        Text("Delete")
                            .frame(width: 80)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button(action: {
                        showingEditSubcategorySheet = false
                    }) {
                        Text("Cancel")
                            .frame(width: 80)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.escape, modifiers: [])
                    
                    Button(action: {
                        if let subcategory = selectedSubcategoryForEdit, !subcategoryEditName.isEmpty {
                            // Update subcategory
                            subcategory.name = subcategoryEditName
                            
                            // Get selected color hex from the options array
                            let colorHex = colorOptions[selectedSubcategoryColorIndex].hex
                            subcategory.colorHex = colorHex
                            subcategory.updatedAt = Date()
                            
                            // Save changes
                            do {
                                try viewContext.save()
                                showingEditSubcategorySheet = false
                            } catch {
                                print("Error saving subcategory: \(error)")
                            }
                        }
                    }) {
                        Text("Save")
                            .frame(width: 80)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.return, modifiers: [])
                    .disabled(subcategoryEditName.isEmpty)
                }
                .padding()
            }
            .frame(width: 400, height: 350)
            .background(Color(.darkGray).opacity(0.2))
            .cornerRadius(10)
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
    
    private func fetchSubcategoriesForCategory(_ category: Category) -> [SubCategory] {
        let request = NSFetchRequest<SubCategory>(entityName: "SubCategory")
        request.predicate = NSPredicate(format: "parentCategory == %@", category)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SubCategory.name, ascending: true)]
        
        print("DEBUG: Fetching subcategories for category ID: \(category.id?.uuidString ?? "nil"), name: \(category.name ?? "unnamed")")
        
        // Debug function to check all notes in the database
        printAllNotes()
        
        do {
            let results = try viewContext.fetch(request)
            print("DEBUG: Found \(results.count) subcategories")
            
            // Log each subcategory for debugging
            for (index, subcategory) in results.enumerated() {
                print("DEBUG: Subcategory \(index+1): \(subcategory.name ?? "unnamed") (ID: \(subcategory.id?.uuidString ?? "nil"))")
            }
            
            // Also check if there are any subcategories in Core Data at all
            let allRequest = NSFetchRequest<SubCategory>(entityName: "SubCategory")
            let allSubcategories = try viewContext.fetch(allRequest)
            print("DEBUG: Total subcategories in database: \(allSubcategories.count)")
            
            return results
        } catch {
            print("ERROR: Error fetching subcategories: \(error.localizedDescription)")
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
    
    private func countNotesInCategory(_ category: Category) -> Int {
        let request = NSFetchRequest<Note>(entityName: "Note")
        request.predicate = NSPredicate(format: "category == %@ AND subcategory == nil", category)
        
        do {
            return try viewContext.count(for: request)
        } catch {
            print("Error counting notes in category: \(error.localizedDescription)")
            return 0
        }
    }
    
    private func countNotesInSubcategory(_ subcategory: SubCategory) -> Int {
        let request = NSFetchRequest<Note>(entityName: "Note")
        request.predicate = NSPredicate(format: "subcategory == %@", subcategory)
        
        do {
            return try viewContext.count(for: request)
        } catch {
            print("Error counting notes in subcategory: \(error.localizedDescription)")
            return 0
        }
    }
    
    // Debug function to print all notes in the database
    private func printAllNotes() {
        let request = NSFetchRequest<Note>(entityName: "Note")
        
        do {
            let allNotes = try viewContext.fetch(request)
            print("\n==== DEBUG: ALL NOTES IN DATABASE (\(allNotes.count) total) ====\n")
            
            if allNotes.isEmpty {
                print("No notes found in the database!")
            } else {
                for (index, note) in allNotes.enumerated() {
                    print("Note \(index+1): \(note.title ?? "Untitled")")
                    print("  - ID: \(note.id?.uuidString ?? "nil")")
                    print("  - Content: \(note.content?.prefix(30) ?? "")...")
                    print("  - Category: \(note.category?.name ?? "nil")")
                    print("  - Subcategory: \(note.subcategory?.name ?? "nil")")
                    print("  - Created: \(note.createdAt?.description ?? "nil")")
                    print("")
                }
            }
            
            print("==== END DEBUG NOTES ====\n")
        } catch {
            print("Error fetching all notes: \(error)")
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
        
        // Category and subcategory filter
        if let subcategory = selectedSubcategory {
            // Filter by subcategory
            predicates.append(NSPredicate(format: "subcategory == %@", subcategory))
        } else if let category = selectedCategory {
            // Filter by category (but not in any subcategory)
            predicates.append(NSPredicate(format: "category == %@ AND (subcategory == nil)", category))
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
    @State private var showingDeleteAlert = false
    
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
                // Delete button on the left
                Button("Delete") {
                    showingDeleteAlert = true
                }
                .foregroundColor(.red)
                .keyboardShortcut(.delete, modifiers: [])
                
                Spacer()
                
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
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
                    
                    Text("Color")
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

// MARK: - Create Subcategory Sheet
struct CreateSubcategorySheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    let parentCategory: Category
    
    @State private var name: String = ""
    @State private var selectedColorIndex: Int = 0
    @State private var inheritParentColor: Bool = true
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
    
    // Helper function to convert hex to Color (duplicated from ContentView)
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
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Subcategory Details")) {
                    TextField("Name", text: $name)
                        .padding(.vertical, 4)
                    
                    Toggle("Use parent category color", isOn: $inheritParentColor)
                        .padding(.vertical, 4)
                    
                    if !inheritParentColor {
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
                
                Section(header: Text("Parent Category")) {
                    HStack {
                        Circle()
                            .fill(getColorFromHex(parentCategory.colorHex ?? "007AFF"))
                            .frame(width: 12, height: 12)
                        Text(parentCategory.name ?? "Unnamed")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button("Save") {
                    saveSubcategory()
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(name.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 350)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func saveSubcategory() {
        if name.isEmpty {
            alertMessage = "Please enter a name for your subcategory."
            showingAlert = true
            return
        }
        
        var colorHex: String? = nil
        
        if !inheritParentColor {
            // Get the selected color information
            let selectedColor = colorOptions[selectedColorIndex]
            colorHex = selectedColor.hex
        }
        
        // Create the subcategory directly instead of using the extension method
        let subcategory = SubCategory(context: viewContext)
        subcategory.id = UUID()
        subcategory.name = name
        subcategory.colorHex = colorHex ?? parentCategory.colorHex // Inherit parent color if not specified
        subcategory.parentCategory = parentCategory
        subcategory.createdAt = Date()
        subcategory.updatedAt = Date()
        
        do {
            try viewContext.save()
            // Dismiss the sheet
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "Error creating subcategory: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}





struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
