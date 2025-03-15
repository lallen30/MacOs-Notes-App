import SwiftUI
import CoreData

struct SimpleSubcategoryEditor: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    var subcategory: SubCategory
    
    @State private var name: String
    @State private var selectedColor: Color
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(subcategory: SubCategory) {
        self.subcategory = subcategory
        _name = State(initialValue: subcategory.name ?? "")
        
        // Convert hex color to Color directly to avoid initialization issues
        let colorHex = subcategory.colorHex ?? "007AFF"
        let cleanHex = colorHex.replacingOccurrences(of: "#", with: "").uppercased()
        
        var color: Color = .blue
        switch cleanHex {
        case "FF0000": color = .red
        case "00FF00": color = .green
        case "FFA500": color = .orange
        case "800080": color = .purple
        case "FFC0CB": color = .pink
        case "FFFF00": color = .yellow
        case "808080": color = .gray
        default: color = .blue
        }
        
        _selectedColor = State(initialValue: color)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Subcategory")
                .font(.headline)
            
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)
            
            HStack(spacing: 10) {
                ColorPicker("Color", selection: $selectedColor)
                    .frame(width: 200)
            }
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                
                Button("Save") {
                    saveChanges()
                }
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 250, height: 200)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func saveChanges() {
        guard !name.isEmpty else { return }
        
        // Update the subcategory
        subcategory.name = name
        subcategory.colorHex = colorToHex(selectedColor)
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
    
    // Helper function to convert hex to Color
    private func getColorFromHex(_ hex: String) -> Color {
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
    
    // Helper function to convert Color to hex
    private func colorToHex(_ color: Color) -> String {
        // This is a simplified version - in a real app you'd need a more robust conversion
        if color == .blue { return "007AFF" }
        if color == .red { return "FF0000" }
        if color == .green { return "00FF00" }
        if color == .orange { return "FFA500" }
        if color == .purple { return "800080" }
        if color == .pink { return "FFC0CB" }
        if color == .yellow { return "FFFF00" }
        if color == .gray { return "808080" }
        
        // Default to blue
        return "007AFF"
    }
}
