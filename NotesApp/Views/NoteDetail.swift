import SwiftUI
import CoreData

struct NoteDetail: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let noteID: UUID
    @State private var showingEditSheet = false
    
    // Use a fetch request to get the note by ID
    @FetchRequest private var noteRequest: FetchedResults<Note>
    
    init(noteID: UUID) {
        self.noteID = noteID
        
        // Create a fetch request for this specific note
        let predicate = NSPredicate(format: "id == %@", noteID as CVarArg)
        _noteRequest = FetchRequest<Note>(
            sortDescriptors: [],
            predicate: predicate
        )
    }
    
    var body: some View {
        if let note = noteRequest.first {
            VStack(alignment: .leading) {
                HStack {
                    Text(note.title ?? "Untitled")
                        .font(.title)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Text("Edit")
                    }
                    .keyboardShortcut("e", modifiers: .command)
                    .padding(.horizontal)
                }
                .padding(.top)
                
                Divider()
                
                ScrollView {
                    Text(note.content ?? "")
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
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
            .sheet(isPresented: $showingEditSheet) {
                EditNoteSheet(noteID: noteID, onDismiss: {
                    showingEditSheet = false
                })
            }
        } else {
            Text("Note not found")
                .font(.title)
                .foregroundColor(.secondary)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
