import SwiftUI
import CoreData

struct CreateNoteView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedCategory: Category?
    @State private var selectedSubcategory: SubCategory?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)])
    private var categories: FetchedResults<Category>
    
    @State private var availableSubcategories: [SubCategory] = []
    
    var onSave: ((Note) -> Void)?
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Note Details")) {
                    TextField("Title", text: $title)
                        .padding(.vertical, 4)
                    
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("Content")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                    }
                }
                
                Section(header: Text("Organization")) {
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as Category?)
                        ForEach(categories, id: \.id) { category in
                            Text(category.name ?? "Unnamed")
                                .tag(category as Category?)
                        }
                    }
                    .onChange(of: selectedCategory) { newCategory in
                        // Reset subcategory when category changes
                        selectedSubcategory = nil
                        updateAvailableSubcategories()
                    }
                    
                    if !availableSubcategories.isEmpty {
                        Picker("Subcategory", selection: $selectedSubcategory) {
                            Text("None").tag(nil as SubCategory?)
                            ForEach(availableSubcategories, id: \.id) { subcategory in
                                Text(subcategory.name ?? "Unnamed")
                                    .tag(subcategory as SubCategory?)
                            }
                        }
                    }
                }
            }
            .padding()
            .onAppear {
                updateAvailableSubcategories()
            }
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("Save") {
                    saveNote()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(title.isEmpty)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func saveNote() {
        if title.isEmpty {
            alertMessage = "Please enter a title for your note."
            showingAlert = true
            return
        }
        
        // Create a new note with all required properties
        let newNote = Note(context: viewContext)
        newNote.id = UUID()
        newNote.title = title
        newNote.content = content
        newNote.createdAt = Date()
        newNote.updatedAt = Date()
        newNote.category = selectedCategory
        newNote.subcategory = selectedSubcategory
        
        do {
            // Save the context to persist changes
            try viewContext.save()
            
            // Notify the parent view about the new note
            onSave?(newNote)
            
            // Dismiss the sheet
            DispatchQueue.main.async {
                presentationMode.wrappedValue.dismiss()
            }
        } catch {
            alertMessage = "Could not save note: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func updateAvailableSubcategories() {
        if let category = selectedCategory, let subcategories = category.subcategories as? Set<SubCategory> {
            availableSubcategories = Array(subcategories).sorted { ($0.name ?? "") < ($1.name ?? "") }
        } else {
            availableSubcategories = []
        }
    }
}
