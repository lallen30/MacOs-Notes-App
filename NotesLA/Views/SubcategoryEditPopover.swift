import SwiftUI
import CoreData

struct SubcategoryEditPopover: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    let subcategory: SubCategory
    
    @State private var name: String
    @State private var selectedColorIndex: Int = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingDeleteAlert = false
    
    // Define standard colors directly - same as category colors for consistency
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
    
    init(subcategory: SubCategory) {
        self.subcategory = subcategory
        _name = State(initialValue: subcategory.name ?? "")
        
        // Find the index of the color that matches the subcategory's colorHex
        var index = 0
        if let colorHex = subcategory.colorHex {
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
                    presentationMode.wrappedValue.dismiss()
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
    }
    
    private func saveChanges() {
        guard !name.isEmpty else { return }
        
        // Get the selected color information
        let selectedColor = colorOptions[selectedColorIndex]
        let hexValue = selectedColor.hex
        
        // Update the subcategory
        subcategory.name = self.name
        subcategory.colorHex = hexValue
        subcategory.updatedAt = Date()
        
        // Save the changes
        do {
            try viewContext.save()
            
            // Post a notification that the subcategory was updated
            NotificationCenter.default.post(name: NSNotification.Name("SubcategoryUpdated"), object: nil)
            
            // Dismiss the sheet
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "Failed to save subcategory: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func deleteSubcategory() {
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
            
            // Save the changes
            try viewContext.save()
            
            // Post a notification that the subcategory was deleted
            NotificationCenter.default.post(name: NSNotification.Name("SubcategoryDeleted"), object: nil)
            
            // Dismiss the sheet
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "Failed to delete subcategory: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}
