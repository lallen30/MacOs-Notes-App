import SwiftUI
import CoreData

struct NotesList: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // FetchRequest properties
    var predicate: NSPredicate?
    var sortDescriptors: [NSSortDescriptor]
    
    // Selection state
    @Binding var selectedNoteID: UUID?
    var onEdit: (UUID) -> Void
    
    // For fetching notes
    @FetchRequest private var notes: FetchedResults<Note>
    
    init(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor], selectedNoteID: Binding<UUID?>, onEdit: @escaping (UUID) -> Void) {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self._selectedNoteID = selectedNoteID
        self.onEdit = onEdit
        
        // Initialize the fetch request
        _notes = FetchRequest<Note>(
            sortDescriptors: sortDescriptors,
            predicate: predicate
        )
    }
    
    var body: some View {
        List {
            ForEach(notes, id: \\.id) { note in
                NoteRow(
                    title: note.title ?? "Untitled",
                    content: note.content ?? "",
                    date: note.updatedAt ?? Date(),
                    isSelected: note.id == selectedNoteID
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedNoteID = note.id
                }
                .contextMenu {
                    Button(action: {
                        if let id = note.id {
                            onEdit(id)
                        }
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        deleteNote(note)
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onDelete(perform: deleteNotes)
        }
    }
    
    private func deleteNotes(offsets: IndexSet) {
        withAnimation {
            offsets.map { notes[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
                // If the deleted note was selected, clear the selection
                if let selectedID = selectedNoteID, 
                   !notes.contains(where: { $0.id == selectedID }) {
                    selectedNoteID = notes.first?.id
                }
            } catch {
                print("Error deleting note: \(error)")
            }
        }
    }
    
    private func deleteNote(_ note: Note) {
        withAnimation {
            viewContext.delete(note)
            
            do {
                try viewContext.save()
                // If the deleted note was selected, clear the selection
                if note.id == selectedNoteID {
                    selectedNoteID = notes.first?.id
                }
            } catch {
                print("Error deleting note: \(error)")
            }
        }
    }
}

struct NoteRow: View {
    let title: String
    let content: String
    let date: Date
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .lineLimit(1)
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text(formattedDate(date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
