import SwiftUI
import CoreData

struct StandaloneSubcategoryEditor: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    // State for the editor
    @State private var subcategoryName: String
    @State private var selectedColorIndex: Int
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingDeleteAlert = false
    
    // The subcategory being edited
    private let subcategoryID: NSManagedObjectID
    private var onUpdate: () -> Void
    
    // Color options for the subcategory
    private let colorOptions: [(name: String, color: Color, hex: String)] = [
        ("Blue", .blue, "007AFF"),
        ("Red", .red, "FF0000"),
        ("Green", .green, "00FF00"),
        ("Orange", .orange, "FFA500"),
        ("Purple", .purple, "800080"),
        ("Pink", .pink, "FFC0CB"),
        ("Yellow", .yellow, "FFFF00"),
        ("Gray", .gray, "808080")
    ]
    
    init(subcategoryID: NSManagedObjectID, initialName: String, initialColorHex: String?, onUpdate: @escaping () -> Void) {
        self.subcategoryID = subcategoryID
        self.onUpdate = onUpdate
        
        // Initialize state variables
        _subcategoryName = State(initialValue: initialName)
        
        // Find the index of the color that matches the subcategory's colorHex
        var index = 0
        if let colorHex = initialColorHex {
            // Clean the hex for consistent comparison
            let cleanHex = colorHex.replacingOccurrences(of: "#", with: "").uppercased()
            
            // Try to find the matching color in our predefined options
            for (i, option) in colorOptions.enumerated() {
                let optionHex = option.hex.uppercased()
                if optionHex == cleanHex {
                    index = i
                    break
                }
            }
        }
        
        _selectedColorIndex = State(initialValue: index)
    }
    
    var body: some View {
        VStack {
            Text("Edit Subcategory")
                .font(.headline)
                .padding()
            
            TextField("Name", text: $subcategoryName)
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
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
                
                Button("Save") {
                    saveChanges()
                }
                .padding()
                .disabled(subcategoryName.isEmpty)
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
    }
    
    private func getSubcategory() -> SubCategory? {
        do {
            return try viewContext.existingObject(with: subcategoryID) as? SubCategory
        } catch {
            print("Error fetching subcategory: \(error)")
            return nil
        }
    }
    
    private func saveChanges() {
        guard !subcategoryName.isEmpty else { return }
        guard let subcategory = getSubcategory() else {
            alertMessage = "Could not find subcategory"
            showingAlert = true
            return
        }
        
        // Get the selected color information
        let selectedColor = colorOptions[selectedColorIndex]
        let hexValue = selectedColor.hex
        
        // Update the subcategory
        subcategory.name = subcategoryName
        subcategory.colorHex = hexValue
        subcategory.updatedAt = Date()
        
        // Save the changes
        do {
            try viewContext.save()
            onUpdate()
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "Failed to save subcategory: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func deleteSubcategory() {
        guard let subcategory = getSubcategory() else {
            alertMessage = "Could not find subcategory"
            showingAlert = true
            return
        }
        
        // Get all notes in this subcategory
        let fetchRequest = NSFetchRequest<Note>(entityName: "Note")
        fetchRequest.predicate = NSPredicate(format: "subcategory == %@", subcategory)
        
        do {
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
            
            try viewContext.save()
            onUpdate()
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "Failed to delete subcategory: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// Helper view to present the StandaloneSubcategoryEditor
struct SubcategoryEditorPresenter: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool
    let subcategoryID: NSManagedObjectID
    let onUpdate: () -> Void
    
    var body: some View {
        if let subcategory = try? viewContext.existingObject(with: subcategoryID) as? SubCategory {
            StandaloneSubcategoryEditor(
                subcategoryID: subcategoryID,
                initialName: subcategory.name ?? "",
                initialColorHex: subcategory.colorHex,
                onUpdate: onUpdate
            )
        } else {
            Text("Subcategory not found")
                .onAppear {
                    isPresented = false
                }
        }
    }
}
