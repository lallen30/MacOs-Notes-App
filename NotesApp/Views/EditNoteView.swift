import SwiftUI
import CoreData

struct EditNoteView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    // Use ObservedObject to track the note directly
    @ObservedObject var note: Note
    
    // Use separate state for editing
    @State private var editedTitle: String
    @State private var editedContent: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(note: Note) {
        self.note = note
        _editedTitle = State(initialValue: note.title ?? "")
        _editedContent = State(initialValue: note.content ?? "")
    }
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Edit Note")) {
                    TextField("Title", text: $editedTitle)
                        .padding(.vertical, 4)
                    
                    ZStack(alignment: .topLeading) {
                        if editedContent.isEmpty {
                            Text("Content")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        
                        TextEditor(text: $editedContent)
                            .frame(minHeight: 200)
                    }
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
                    saveNote()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(editedTitle.isEmpty)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func saveNote() {
        if editedTitle.isEmpty {
            alertMessage = "Please enter a title for your note."
            showingAlert = true
            return
        }
        
        // Update the note properties directly
        note.title = editedTitle
        note.content = editedContent
        note.updatedAt = Date()
        
        // Save the context
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "Failed to save note: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}
