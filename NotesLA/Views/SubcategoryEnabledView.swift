import SwiftUI
import CoreData

struct SubcategoryEnabledView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedCategory: Category?
    @State private var selectedSubcategory: SubCategory?
    @State private var selectedNote: Note?
    @State private var showingCreateCategorySheet = false
    @State private var showingCreateSubcategorySheet = false
    @State private var showingCreateNoteSheet = false
    @State private var refreshCategoryList = false
    @State private var searchText = ""
    
    // MARK: - Color Utility
    private func getColorFromHex(_ hex: String) -> Color {
        // Remove # if present and convert to uppercase for consistent comparison
        let cleanHex = hex.replacingOccurrences(of: "#", with: "").uppercased()
        
        // Direct mapping to SwiftUI system colors
        switch cleanHex {
        case "007AFF": return .blue
        case "FF0000", "FF3B30": return .red
        case "00FF00", "34C759": return .green
        case "FFA500", "FF9500": return .orange
        case "800080", "AF52DE": return .purple
        case "FFC0CB", "FF2D55": return .pink
        case "FFFF00", "FFCC00": return .yellow
        case "808080", "8E8E93": return .gray
        default:
            // For any other hex values, use blue as fallback
            return .blue
        }
    }
    
    var body: some View {
        NavigationView {
            // Left sidebar with categories and subcategories
            List {
                // Header with create button
                HStack {
                    Text("Categories")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        showingCreateCategorySheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 8)
                
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.bottom, 8)
                
                // Categories with subcategories
                ForEach(fetchCategories(), id: \\.self) { category in
                    DisclosureGroup {
                        // Subcategories
                        if let subcategories = category.subcategories as? Set<SubCategory>, !subcategories.isEmpty {
                            ForEach(Array(subcategories).sorted(by: { ($0.name ?? "") < ($1.name ?? "") }), id: \\.self) { subcategory in
                                HStack {
                                    Circle()
                                        .fill(getColorFromHex(subcategory.colorHex ?? "007AFF"))
                                        .frame(width: 10, height: 10)
                                    
                                    Text(subcategory.name ?? "Unnamed")
                                        .lineLimit(1)
                                        .font(.system(size: 13))
                                    
                                    Spacer()
                                    
                                    // Count notes in this subcategory
                                    Text("\\(subcategory.notes?.count ?? 0)")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(.leading, 10)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCategory = category
                                    selectedSubcategory = subcategory
                                    selectedNote = nil
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
                            Circle()
                                .fill(getColorFromHex(category.colorHex ?? "007AFF"))
                                .frame(width: 12, height: 12)
                            
                            Text(category.name ?? "Unnamed")
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\\(category.notes?.count ?? 0)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCategory = category
                            selectedSubcategory = nil
                            selectedNote = nil
                        }
                        .background(selectedCategory == category && selectedSubcategory == nil ? Color.accentColor.opacity(0.1) : Color.clear)
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 220)
            
            // Middle pane - Notes list for selected category or subcategory
            if let category = selectedCategory {
                VStack {
                    // Header with category/subcategory name and create note button
                    HStack {
                        if let subcategory = selectedSubcategory {
                            Text(subcategory.name ?? "Unnamed Subcategory")
                                .font(.headline)
                        } else {
                            Text(category.name ?? "Unnamed Category")
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingCreateNoteSheet = true
                        }) {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 8)
                    
                    // Notes list
                    List {
                        ForEach(fetchNotes(), id: \\.self) { note in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(note.title ?? "Untitled")
                                        .font(.headline)
                                        .lineLimit(1)
                                    
                                    Text(note.content ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                                
                                if let updatedAt = note.updatedAt {
                                    Text(updatedAt, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedNote = note
                            }
                            .background(selectedNote == note ? Color.accentColor.opacity(0.1) : Color.clear)
                        }
                    }
                }
                .frame(minWidth: 250)
                .padding()
            } else {
                // No category selected
                VStack {
                    Text("Select a category or subcategory")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(minWidth: 250)
            }
            
            // Right pane - Note detail
            if let note = selectedNote {
                NoteDetailView(note: note)
                    .frame(minWidth: 400)
            } else {
                // No note selected
                VStack {
                    Text("Select a note to view details")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(minWidth: 400)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: $showingCreateCategorySheet) {
            CreateCategorySheet()
                .environment(\\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingCreateSubcategorySheet) {
            if let category = selectedCategory {
                CreateSubcategoryView(parentCategory: category)
                    .environment(\\.managedObjectContext, viewContext)
            }
        }
        .sheet(isPresented: $showingCreateNoteSheet) {
            // Create note sheet with category/subcategory pre-selected
            if let category = selectedCategory {
                CreateNoteView(category: category, subcategory: selectedSubcategory)
                    .environment(\\.managedObjectContext, viewContext)
            }
        }
    }
    
    // MARK: - Data Fetching
    private func fetchCategories() -> [Category] {
        let request = NSFetchRequest<Category>(entityName: "Category")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \\Category.name, ascending: true)]
        
        // Filter by search text if provided
        if !searchText.isEmpty {
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", searchText)
        }
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching categories: \\(error)")
            return []
        }
    }
    
    private func fetchNotes() -> [Note] {
        let request = NSFetchRequest<Note>(entityName: "Note")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \\Note.updatedAt, ascending: false)]
        
        // Filter by selected category/subcategory
        if let subcategory = selectedSubcategory {
            request.predicate = NSPredicate(format: "subcategory == %@", subcategory)
        } else if let category = selectedCategory {
            request.predicate = NSPredicate(format: "category == %@ AND subcategory == nil", category)
        }
        
        // Additional filter by search text if provided
        if !searchText.isEmpty {
            let searchPredicate = NSPredicate(format: "title CONTAINS[cd] %@ OR content CONTAINS[cd] %@", searchText, searchText)
            
            if request.predicate != nil {
                // Combine with existing predicate
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [request.predicate!, searchPredicate])
            } else {
                request.predicate = searchPredicate
            }
        }
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching notes: \\(error)")
            return []
        }
    }
}

// MARK: - Create Note View
struct CreateNoteView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    var category: Category?
    var subcategory: SubCategory?
    
    @State private var title = ""
    @State private var content = ""
    
    var body: some View {
        VStack {
            Text("Create Note")
                .font(.headline)
                .padding()
            
            Form {
                TextField("Title", text: $title)
                
                TextEditor(text: $content)
                    .frame(height: 200)
                
                HStack {
                    Spacer()
                    
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    
                    Button("Create") {
                        createNote()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .padding()
        }
        .frame(width: 500, height: 400)
    }
    
    private func createNote() {
        let note = Note(context: viewContext)
        note.id = UUID()
        note.title = title
        note.content = content
        note.createdAt = Date()
        note.updatedAt = Date()
        note.category = category
        note.subcategory = subcategory
        
        do {
            try viewContext.save()
        } catch {
            print("Error creating note: \\(error)")
        }
    }
}

struct SubcategoryEnabledView_Previews: PreviewProvider {
    static var previews: some View {
        SubcategoryEnabledView()
            .environment(\\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
