import SwiftUI
import CoreData

// Helper function to convert hex to Color
func getColorFromHex(_ hex: String) -> Color {
    // Remove # if present and convert to uppercase for consistent comparison
    let cleanHex = hex.replacingOccurrences(of: "#", with: "").uppercased()
    
    // Direct mapping to SwiftUI system colors
    switch cleanHex {
    case "007AFF": return .blue
    case "FF0000", "FF3B30": return .red
    case "00FF00", "34C759": return .green
    case "FFA500", "FF9500": return .orange
    case "800080", "AF52DE": return .purple
    case "FFC0CB", "FF2D55": return .pink
    case "FFFF00", "FFCC00": return .yellow
    case "808080", "8E8E93": return .gray
    default:
        // For any other hex values, use blue as fallback
        return .blue
    }
}

struct CreateSubcategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    let parentCategory: Category
    
    @State private var name: String = ""
    @State private var selectedColor: Color = .blue
    @State private var inheritParentColor: Bool = true
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Predefined colors
    private let colors: [Color] = [
        .blue, .red, .green, .orange, .purple, .pink, .yellow, .gray
    ]
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Subcategory Details")) {
                    TextField("Name", text: $name)
                        .padding(.vertical, 4)
                    
                    Toggle("Use parent category color", isOn: $inheritParentColor)
                        .padding(.vertical, 4)
                    
                    if !inheritParentColor {
                        Text("Color")
                            .padding(.vertical, 4)
                        
                        // Color presets
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor.description == color.description ? 2 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section(header: Text("Parent Category")) {
                    HStack {
                        Circle()
                            .fill(getColorFromHex(parentCategory.colorHex ?? "007AFF"))
                            .frame(width: 12, height: 12)
                        Text(parentCategory.name ?? "Unnamed")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("Save") {
                    saveSubcategory()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(name.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 350)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            // Initialize with parent category color
            if let colorHex = parentCategory.colorHex {
                // Convert hex to Color using our utility function
                selectedColor = getColorFromHex(colorHex)
            }
        }
    }
    
    private func saveSubcategory() {
        if name.isEmpty {
            alertMessage = "Please enter a name for your subcategory."
            showingAlert = true
            return
        }
        
        var colorHex: String? = nil
        
        if !inheritParentColor {
            // Convert Color to hex string
            // For simplicity, we'll use predefined colors with their hex values
            switch selectedColor {
            case .blue: colorHex = "#007AFF"
            case .red: colorHex = "#FF3B30"
            case .green: colorHex = "#34C759"
            case .orange: colorHex = "#FF9500"
            case .purple: colorHex = "#AF52DE"
            case .pink: colorHex = "#FF2D55"
            case .yellow: colorHex = "#FFCC00"
            case .gray: colorHex = "#8E8E93"
            default: colorHex = "#007AFF" // Default blue
            }
        }
        
        // Create the subcategory
        let _ = SubCategory.create(name: name, parentCategory: parentCategory, colorHex: colorHex, context: viewContext)
        
        // Dismiss the sheet
        presentationMode.wrappedValue.dismiss()
    }
}

struct CreateSubcategoryView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        let category = Category.create(name: "Sample Category", context: context)
        
        return CreateSubcategoryView(parentCategory: category)
            .environment(\.managedObjectContext, context)
    }
}
