import SwiftUI
import CoreData

struct CreateCategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var name: String = ""
    @State private var selectedColor: Color = .blue
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Predefined colors
    private let colors: [Color] = [
        .blue, .red, .green, .orange, .purple, .pink, .yellow, .gray
    ]
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Category Details")) {
                    TextField("Name", text: $name)
                        .padding(.vertical, 4)
                    
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
            .padding()
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("Save") {
                    saveCategory()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(name.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 300)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func saveCategory() {
        if name.isEmpty {
            alertMessage = "Please enter a name for your category."
            showingAlert = true
            return
        }
        
        // Convert Color to hex string
        let uiColor = NSColor(selectedColor)
        let colorHex = String(format: "#%02X%02X%02X", 
                             Int(uiColor.redComponent * 255), 
                             Int(uiColor.greenComponent * 255), 
                             Int(uiColor.blueComponent * 255))
        
        // Create the category
        let _ = Category.create(name: name, colorHex: colorHex, context: viewContext)
        
        // Dismiss the sheet
        presentationMode.wrappedValue.dismiss()
    }
}

struct CreateCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        CreateCategoryView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
