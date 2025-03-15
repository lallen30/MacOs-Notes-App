import SwiftUI

struct SubcategoryEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    var subcategory: SubCategory
    var onDismiss: () -> Void
    
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
    
    init(subcategory: SubCategory, onDismiss: @escaping () -> Void) {
        self.subcategory = subcategory
        self.onDismiss = onDismiss
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
            HStack {
                Text("Edit Subcategory")
                    .font(.headline)
                Spacer()
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Name")
                    .font(.subheadline)
                
                TextField("Subcategory Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
                
                Text("Color")
                    .font(.subheadline)
                
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
            }
            .padding()
            
            Spacer()
            
            Divider()
            
            HStack {
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Text("Delete")
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
                .keyboardShortcut(.delete, modifiers: [])
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                    onDismiss()
                }) {
                    Text("Cancel")
                }
                .buttonStyle(BorderlessButtonStyle())
                .keyboardShortcut(.escape, modifiers: [])
                
                Button(action: {
                    updateSubcategory()
                }) {
                    Text("Save")
                }
                .buttonStyle(BorderlessButtonStyle())
                .keyboardShortcut(.return, modifiers: [])
                .disabled(name.isEmpty)
            }
            .padding()
        }
        .frame(width: 350, height: 300)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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
    
    private func updateSubcategory() {
        guard !name.isEmpty else { return }
        
        // Get the selected color information
        let selectedColor = colorOptions[selectedColorIndex]
        let hexValue = selectedColor.hex
        
        // Create a clean hex value with proper formatting
        let cleanHexValue = hexValue.replacingOccurrences(of: "#", with: "").uppercased()
        
        // Modify the subcategory directly
        subcategory.name = self.name
        subcategory.colorHex = cleanHexValue
        subcategory.updatedAt = Date()
        
        do {
            try viewContext.save()
            print("Subcategory updated successfully")
            
            // Dismiss the sheet
            presentationMode.wrappedValue.dismiss()
            onDismiss()
        } catch {
            print("Error updating subcategory: \(error)")
            alertMessage = "Error updating subcategory: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func deleteSubcategory() {
        // Get all notes in this subcategory
        let notes = Note.fetchNotesInSubCategory(subcategory, context: viewContext)
        
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
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
            onDismiss()
        } catch {
            alertMessage = "Failed to delete subcategory: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}
