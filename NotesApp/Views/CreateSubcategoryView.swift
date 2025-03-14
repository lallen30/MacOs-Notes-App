import SwiftUI
import CoreData

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
                        ColorPicker("Color", selection: $selectedColor)
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
                            .fill(parentCategory.color)
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
            if let colorHex = parentCategory.colorHex, let color = try? Color(hex: colorHex) {
                selectedColor = color
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
            let uiColor = NSColor(selectedColor)
            colorHex = String(format: "#%02X%02X%02X", 
                             Int(uiColor.redComponent * 255), 
                             Int(uiColor.greenComponent * 255), 
                             Int(uiColor.blueComponent * 255))
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
