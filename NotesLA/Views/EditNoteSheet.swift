import SwiftUI
import CoreData

struct EditNoteSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    // Note to edit and callback for when save completes
    let note: Note
    let onSave: (Note) -> Void
    
    // State for editing
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(note: Note, onSave: @escaping (Note) -> Void) {
        self.note = note
        self.onSave = onSave
        _title = State(initialValue: note.title ?? "")
        _content = State(initialValue: note.content ?? "")
    }
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Edit Note")) {
                    TextField("Title", text: $title)
                        .font(.headline)
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
                
                Section {
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
                        
                        Spacer()
                    }
                }
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
        
        // Get a fresh reference to the note from the context
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", note.id! as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            if let noteToUpdate = results.first {
                // Update the note properties
                noteToUpdate.title = title
                noteToUpdate.content = content
                noteToUpdate.updatedAt = Date()
                
                // Save the context
                try viewContext.save()
                
                // Call the callback with the updated note
                onSave(noteToUpdate)
            } else {
                alertMessage = "Could not find the note to update"
                showingAlert = true
            }
        } catch {
            alertMessage = "Failed to save note: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}
