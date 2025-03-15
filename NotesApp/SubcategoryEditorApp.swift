import SwiftUI
import CoreData

// A standalone app for editing subcategories
@main
struct SubcategoryEditorApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            if let subcategoryIDString = CommandLine.arguments.dropFirst().first,
               let subcategoryID = NSManagedObjectID.fromString(subcategoryIDString) {
                SubcategoryEditView(subcategoryID: subcategoryID)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                Text("No subcategory ID provided")
            }
        }
    }
}

// View for editing a subcategory
struct SubcategoryEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let subcategoryID: NSManagedObjectID
    
    @State private var name: String = ""
    @State private var selectedColorIndex: Int = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingDeleteAlert = false
    
    // Define standard colors directly - same as category colors for consistency
    private var colorOptions: [(name: String, color: Color, hex: String)] = [
        ("Blue", .blue, "007AFF"),
        ("Red", .red, "FF0000"),
        ("Green", .green, "00FF00"),
        ("Orange", .orange, "FFA500"),
        ("Purple", .purple, "800080"),
        ("Pink", .pink, "FFC0CB"),
        ("Yellow", .yellow, "FFFF00"),
        ("Gray", .gray, "808080")
    ]
    
    init(subcategoryID: NSManagedObjectID) {
        self.subcategoryID = subcategoryID
    }
    
    var body: some View {
        VStack {
            Text("Edit Subcategory")
                .font(.headline)
                .padding()
            
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Text("Color")
                .font(.subheadline)
                .padding(.top)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                ForEach(0..<colorOptions.count, id: \\.self) { index in
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
            .padding()
            
            Spacer()
            
            HStack {
                Button("Delete") {
                    showingDeleteAlert = true
                }
                .foregroundColor(.red)
                .padding()
                
                Spacer()
                
                Button("Cancel") {
                    NSApplication.shared.terminate(nil)
                }
                .padding()
                
                Button("Save") {
                    saveChanges()
                }
                .padding()
                .disabled(name.isEmpty)
            }
            .padding(.horizontal)
        }
        .frame(width: 350, height: 350)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Subcategory"),
                message: Text("Are you sure you want to delete this subcategory? All notes in this subcategory will be moved to the parent category."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteSubcategory()
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            loadSubcategoryData()
        }
    }
    
    private func loadSubcategoryData() {
        do {
            if let subcategory = try viewContext.existingObject(with: subcategoryID) as? SubCategory {
                self.name = subcategory.name ?? ""
                
                // Find the index of the color that matches the subcategory's colorHex
                if let colorHex = subcategory.colorHex {
                    // Clean the hex for consistent comparison
                    let cleanHex = colorHex.replacingOccurrences(of: "#", with: "").uppercased()
                    
                    // Try to find the matching color in our predefined options
                    for (i, option) in colorOptions.enumerated() {
                        let optionHex = option.hex.uppercased()
                        if optionHex == cleanHex {
                            self.selectedColorIndex = i
                            break
                        }
                    }
                }
            }
        } catch {
            print("Error loading subcategory: \(error)")
            alertMessage = "Error loading subcategory: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func saveChanges() {
        guard !name.isEmpty else { return }
        
        do {
            if let subcategory = try viewContext.existingObject(with: subcategoryID) as? SubCategory {
                // Get the selected color information
                let selectedColor = colorOptions[selectedColorIndex]
                let hexValue = selectedColor.hex
                
                // Update the subcategory
                subcategory.name = self.name
                subcategory.colorHex = hexValue
                subcategory.updatedAt = Date()
                
                // Save the changes
                try viewContext.save()
                
                // Exit the app
                NSApplication.shared.terminate(nil)
            }
        } catch {
            alertMessage = "Failed to save subcategory: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func deleteSubcategory() {
        do {
            if let subcategory = try viewContext.existingObject(with: subcategoryID) as? SubCategory {
                // Get all notes in this subcategory
                let fetchRequest = NSFetchRequest<Note>(entityName: "Note")
                fetchRequest.predicate = NSPredicate(format: "subcategory == %@", subcategory)
                let notes = try viewContext.fetch(fetchRequest)
                
                // Get the parent category
                let parentCategory = subcategory.parentCategory
                
                // Update each note to remove the subcategory but keep the parent category
                for note in notes {
                    note.subcategory = nil
                    note.category = parentCategory  // Move notes to parent category
                    note.updatedAt = Date()
                }
                
                // Delete the subcategory
                viewContext.delete(subcategory)
                
                // Save the changes
                try viewContext.save()
                
                // Exit the app
                NSApplication.shared.terminate(nil)
            }
        } catch {
            alertMessage = "Failed to delete subcategory: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// Extension to convert NSManagedObjectID to/from string
extension NSManagedObjectID {
    static func fromString(_ string: String) -> NSManagedObjectID? {
        let url = URL(string: string)
        return url.flatMap { PersistenceController.shared.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: $0) }
    }
    
    func toString() -> String {
        return self.uriRepresentation().absoluteString
    }
}
