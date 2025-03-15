import SwiftUI
import CoreData

struct NoteDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var note: Note
    
    @State private var isEditing = false
    @State private var editedTitle = ""
    @State private var editedContent = ""
    @State private var editedCategory: Category?
    @State private var editedSubcategory: SubCategory?
    @State private var availableSubcategories: [SubCategory] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingDeleteAlert = false
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)])
    private var categories: FetchedResults<Category>
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if isEditing {
                    TextField("Title", text: $editedTitle)
                        .font(.title)
                        .padding(.horizontal)
                } else {
                    Text(note.title ?? "")
                        .font(.title)
                        .padding(.horizontal)
                        .textSelection(.enabled)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {
                        if isEditing {
                            saveNote()
                        } else {
                            editedTitle = note.title ?? ""
                            editedContent = note.content ?? ""
                            editedCategory = note.category
                            editedSubcategory = note.subcategory
                            updateAvailableSubcategories()
                            isEditing = true
                        }
                    }) {
                        Text(isEditing ? "Save" : "Edit")
                    }
                    .keyboardShortcut("e", modifiers: .command)
                    
                    if !isEditing {
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Text("Delete")
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top)
            
            Divider()
            
            if isEditing {
                VStack {
                    // Category and subcategory pickers
                    HStack {
                        Picker("Category", selection: $editedCategory) {
                            Text("None").tag(nil as Category?)
                            ForEach(categories, id: \.id) { category in
                                Text(category.name ?? "Unnamed")
                                    .tag(category as Category?)
                            }
                        }
                        .frame(maxWidth: 200)
                        .onChange(of: editedCategory) { newCategory in
                            // Reset subcategory when category changes
                            if newCategory == nil {
                                // If category is set to None, subcategory must also be None
                                editedSubcategory = nil
                                availableSubcategories = []
                            } else if editedSubcategory?.parentCategory != newCategory {
                                // If new category doesn't match subcategory's parent, reset subcategory
                                editedSubcategory = nil
                                updateAvailableSubcategories()
                            } else {
                                updateAvailableSubcategories()
                            }
                        }
                        
                        // Only show subcategory picker if a category is selected
                        if editedCategory != nil {
                            Picker("Subcategory", selection: $editedSubcategory) {
                                Text("None").tag(nil as SubCategory?)
                                ForEach(availableSubcategories, id: \.id) { subcategory in
                                    Text(subcategory.name ?? "Unnamed")
                                        .tag(subcategory as SubCategory?)
                                }
                            }
                            .frame(maxWidth: 200)
                            .disabled(availableSubcategories.isEmpty)
                            .onChange(of: editedSubcategory) { newSubcategory in
                                // Print debug info
                                print("Selected subcategory: \(newSubcategory?.name ?? "None")")
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Content editor
                    HStack {
                        // Left margin
                        Spacer().frame(width: 16)
                        
                        // Editor
                        TextEditor(text: $editedContent)
                            .font(.body)
                            .padding()
                            .background(Color(.textBackgroundColor))
                            .cornerRadius(4)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    // Category and subcategory tags
                    if note.category != nil || note.subcategory != nil {
                        HStack {
                            if let category = note.category {
                                let hexValue = category.colorHex ?? "007AFF"
                                let color = getColorFromHex(hexValue)
                                
                                Text(category.name ?? "Unnamed")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(color.opacity(0.2))
                                    .foregroundColor(color)
                                    .cornerRadius(4)
                            }
                            
                            if let subcategory = note.subcategory {
                                let hexValue = subcategory.colorHex ?? "00FF00"
                                let color = getColorFromHex(hexValue)
                                
                                Text(subcategory.name ?? "Unnamed")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(color.opacity(0.2))
                                    .foregroundColor(color)
                                    .cornerRadius(4)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    // Content
                    HStack {
                        // Left margin
                        Spacer().frame(width: 16)
                        
                        // Note content
                        ScrollView {
                            Text(note.content ?? "")
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            
            Divider()
            
            HStack {
                if let updatedAt = note.updatedAt {
                    Text("Last updated: \(formattedDate(updatedAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let createdAt = note.createdAt {
                    Text("Created: \(formattedDate(createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .alert("Delete Note", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteNote()
            }
        } message: {
            Text("Are you sure you want to delete '\(note.title ?? "Untitled")'? This action cannot be undone.")
        }
    }
    
    private func saveNote() {
        if editedTitle.isEmpty {
            alertMessage = "Please enter a title for your note."
            showingAlert = true
            return
        }
        
        // Update note with all edited properties
        note.update(title: editedTitle, content: editedContent, category: editedCategory, subcategory: editedSubcategory, context: viewContext)
        
        // Explicitly save changes to ensure they're persisted
        do {
            try viewContext.save()
            
            // Force UI update by explicitly setting the note properties
            // This ensures SwiftUI detects the changes
            DispatchQueue.main.async {
                self.note.objectWillChange.send()
                isEditing = false
            }
        } catch {
            alertMessage = "Failed to save note: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func updateAvailableSubcategories() {
        if let category = editedCategory, let subcategories = category.subcategories as? Set<SubCategory> {
            availableSubcategories = Array(subcategories).sorted { ($0.name ?? "") < ($1.name ?? "") }
        } else {
            availableSubcategories = []
        }
    }
    
    private func deleteNote() {
        // Notify observers before deletion
        note.objectWillChange.send()
        
        // Use withAnimation to make the deletion visually smooth
        withAnimation {
            viewContext.delete(note)
            
            do {
                try viewContext.save()
                
                // Post a notification that a note was deleted
                // This will allow parent views to refresh their state
                NotificationCenter.default.post(name: NSNotification.Name("NoteDeleted"), object: nil)
            } catch {
                alertMessage = "Failed to delete note: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper function to convert hex to Color
    private func getColorFromHex(_ hex: String) -> Color {
        print("DEBUG: NoteDetailView - Converting hex to color: \(hex)")
        
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
            print("DEBUG: NoteDetailView - Unknown hex value: \(hex), using blue as fallback")
            return .blue
        }
    }
}

struct NoteDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        let newNote = Note(context: context)
        newNote.title = "Sample Note"
        newNote.content = "This is a sample note content for preview purposes."
        newNote.createdAt = Date()
        newNote.updatedAt = Date()
        
        return NoteDetailView(note: newNote)
            .environment(\.managedObjectContext, context)
    }
}
