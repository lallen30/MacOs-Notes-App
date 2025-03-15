import SwiftUI

@main
struct TestEditSubcategoryApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var showingSheet = false
    @State private var testSubcategory = TestSubcategory(name: "Test Subcategory", colorHex: "007AFF")
    
    var body: some View {
        VStack {
            Text("Test EditSubcategorySheet")
                .font(.title)
            
            Button("Edit Subcategory") {
                showingSheet = true
            }
            .padding()
        }
        .padding()
        .frame(width: 300, height: 200)
        .sheet(isPresented: $showingSheet) {
            EditSubcategorySheet(subcategory: testSubcategory)
        }
    }
}

// Mock subcategory for testing
class TestSubcategory: Identifiable, ObservableObject {
    var id = UUID()
    @Published var name: String
    @Published var colorHex: String
    
    init(name: String, colorHex: String) {
        self.name = name
        self.colorHex = colorHex
    }
}

// Simplified EditSubcategorySheet for testing
struct EditSubcategorySheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var subcategory: TestSubcategory
    
    @State private var name: String = ""
    @State private var selectedColorIndex: Int = 0
    
    // Define standard colors directly
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
    
    init(subcategory: TestSubcategory) {
        self.subcategory = subcategory
        _name = State(initialValue: subcategory.name)
        
        // Find the index of the color that matches the subcategory's colorHex
        var index = 0
        let colorHex = subcategory.colorHex
        
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
        
        _selectedColorIndex = State(initialValue: index)
    }
    
    var body: some View {
        VStack {
            Text("Edit Subcategory")
                .font(.headline)
                .padding()
            
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Text("Color")
                .font(.subheadline)
                .padding(.top)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                ForEach(0..<colorOptions.count, id: \.self) { index in
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
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
                
                Spacer()
                
                Button("Save") {
                    updateSubcategory()
                }
                .padding()
                .disabled(name.isEmpty)
            }
            .padding()
        }
        .frame(width: 350, height: 350)
    }
    
    private func updateSubcategory() {
        guard !name.isEmpty else { return }
        
        // Get the selected color information
        let selectedColor = colorOptions[selectedColorIndex]
        let hexValue = selectedColor.hex
        
        // Create a clean hex value with proper formatting
        let cleanHexValue = hexValue.replacingOccurrences(of: "#", with: "").uppercased()
        
        // Update the subcategory
        subcategory.name = self.name
        subcategory.colorHex = cleanHexValue
        
        // Dismiss the sheet
        presentationMode.wrappedValue.dismiss()
    }
}
