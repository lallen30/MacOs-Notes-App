import SwiftUI
import CoreData

// A minimal app to test the EditSubcategorySheet functionality
@main
struct MinimalEditSubcategoryApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Simple content view with a button to show the edit sheet
struct ContentView: View {
    @State private var showingSheet = false
    @State private var subcategoryName = "Test Subcategory"
    @State private var subcategoryColor = "FF0000" // Red
    
    var body: some View {
        VStack {
            Text("Edit Subcategory Test")
                .font(.title)
                .padding()
            
            Text("Current Subcategory: \(subcategoryName)")
                .padding()
            
            Circle()
                .fill(Color.red)
                .frame(width: 30, height: 30)
                .padding()
            
            Button("Edit Subcategory") {
                showingSheet = true
            }
            .padding()
        }
        .frame(width: 400, height: 300)
        .sheet(isPresented: $showingSheet) {
            EditSubcategoryView(
                name: $subcategoryName,
                colorHex: $subcategoryColor,
                onDismiss: { showingSheet = false }
            )
        }
    }
}

// Simplified EditSubcategoryView that doesn't depend on Core Data
struct EditSubcategoryView: View {
    @Binding var name: String
    @Binding var colorHex: String
    var onDismiss: () -> Void
    
    @State private var editedName: String
    @State private var selectedColorIndex: Int = 0
    
    // Define standard colors
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
    
    init(name: Binding<String>, colorHex: Binding<String>, onDismiss: @escaping () -> Void) {
        self._name = name
        self._colorHex = colorHex
        self.onDismiss = onDismiss
        self._editedName = State(initialValue: name.wrappedValue)
        
        // Find the index of the color that matches the subcategory's colorHex
        var index = 0
        let cleanHex = colorHex.wrappedValue.replacingOccurrences(of: "#", with: "").uppercased()
        
        for (i, option) in colorOptions.enumerated() {
            let optionHex = option.hex.uppercased()
            if optionHex == cleanHex {
                index = i
                break
            }
        }
        
        self._selectedColorIndex = State(initialValue: index)
    }
    
    var body: some View {
        VStack {
            Text("Edit Subcategory")
                .font(.headline)
                .padding()
            
            TextField("Name", text: $editedName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
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
                Button("Cancel") {
                    onDismiss()
                }
                .padding()
                
                Spacer()
                
                Button("Save") {
                    saveChanges()
                }
                .padding()
                .disabled(editedName.isEmpty)
            }
            .padding()
        }
        .frame(width: 350, height: 350)
    }
    
    private func saveChanges() {
        // Update the bindings with the new values
        name = editedName
        colorHex = colorOptions[selectedColorIndex].hex
        
        // Dismiss the sheet
        onDismiss()
    }
}
