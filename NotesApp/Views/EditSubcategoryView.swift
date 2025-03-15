import SwiftUI
import CoreData

struct EditSubcategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var subcategory: SubCategory
    @State private var name: String
    @State private var selectedColorIndex: Int = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingDeleteAlert = false
    
    // Define standard colors directly - same as category edit
    private var colorOptions: [(name: String, color: Color, hex: String)] {
        return [
            ("Blue", .blue, "007AFF"),
            ("Red", .red, "FF0000"),
            ("Green", .green, "00FF00"),
            ("Orange", .orange, "FFA500"),
            ("Purple", .purple, "800080"),
            ("Pink", .pink, "FFC0CB"),
            ("Yellow", .yellow, "FFFF00"),
            ("Gray", .gray, "808080")
        ]
    }
    
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
        VStack(spacing: 20) {
            // Title
            Text("Edit Subcategory")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)
                .padding(.horizontal)
            
            // Name field
            HStack {
                Text("Name")
                    .frame(width: 60, alignment: .leading)
                TextField("", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            // Color section
            VStack(alignment: .leading, spacing: 10) {
                Text("Color")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Color grid - 4x2 layout
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                    ForEach(0..<colorOptions.count, id: \.self) { index in
                        Circle()
                            .fill(colorOptions[index].color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: selectedColorIndex == index ? 2 : 0)
                            )
                            .onTapGesture {
                                selectedColorIndex = index
                            }
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Buttons
            HStack {
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Text("Delete")
                        .frame(width: 80)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .frame(width: 80)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape, modifiers: [])
                
                Button(action: {
                    saveChanges()
                }) {
                    Text("Save")
                        .frame(width: 80)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.return, modifiers: [])
                .disabled(name.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 350)
        .background(Color(.darkGray).opacity(0.2))
        .cornerRadius(10)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .alert("Delete Subcategory", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSubcategory()
            }
        } message: {
            Text("Are you sure you want to delete this subcategory? This action cannot be undone.")
        }
    }
    
    private func saveChanges() {
        guard !name.isEmpty else { return }
        
        // Update the subcategory
        subcategory.name = name
        subcategory.colorHex = colorOptions[selectedColorIndex].hex
        subcategory.updatedAt = Date()
        
        // Save the changes
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "Failed to save subcategory: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func deleteSubcategory() {
        viewContext.delete(subcategory)
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "Failed to delete subcategory: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}
