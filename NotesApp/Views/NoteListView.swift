import SwiftUI
import CoreData

// Helper function to convert hex to Color - moved outside structs so it's accessible to all
fileprivate func getColorFromHex(_ hex: String) -> Color {
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

struct NoteListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest private var notes: FetchedResults<Note>
    @Binding var selectedNote: Note?
    @State private var noteToEdit: Note? = nil
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var noteToDelete: Note? = nil
    
    init(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor], selectedNote: Binding<Note?>) {
        _notes = FetchRequest<Note>(
            sortDescriptors: sortDescriptors,
            predicate: predicate,
            animation: .default
        )
        _selectedNote = selectedNote
    }
    
    var body: some View {
        List {
            ForEach(notes, id: \.id) { note in
                NoteRowView(note: note)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedNote = note
                    }
                    .background(selectedNote?.id == note.id ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(selectedNote?.id == note.id ? Color.accentColor : Color.clear, lineWidth: 1)
                    )
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 250)
        .alert("Delete Note", isPresented: $showingDeleteAlert, presenting: noteToDelete) { noteToDelete in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteNote(noteToDelete)
            }
        } message: { noteToDelete in
            Text("Are you sure you want to delete '\(noteToDelete.title ?? "Untitled")'? This action cannot be undone.")
        }
        .sheet(isPresented: $showingEditSheet, onDismiss: {
            noteToEdit = nil
        }) {
            if let note = noteToEdit {
                EditNoteView(note: note)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    private func deleteNote(_ note: Note) {
        withAnimation {
            if selectedNote == note {
                selectedNote = nil
            }
            
            viewContext.delete(note)
            
            do {
                try viewContext.save()
                
                // If we deleted the selected note, select another one if available
                if selectedNote == nil && !notes.isEmpty {
                    selectedNote = notes.first
                }
            } catch {
                print("Error deleting note: \(error)")
            }
        }
    }
}

struct NoteRowView: View {
    @ObservedObject var note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title ?? "Untitled")
                .font(.headline)
                .lineLimit(1)
            
            Text(note.content ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(formattedDate(note.updatedAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Category display has been removed as requested
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown date" }
        
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return "Today, \(formatter.string(from: date))"
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday, \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}
