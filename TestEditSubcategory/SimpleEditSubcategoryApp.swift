import SwiftUI
import CoreData

@main
struct SimpleEditSubcategoryApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingSheet = false
    @State private var selectedSubcategory: SubCategory?
    
    var body: some View {
        VStack {
            Text("Test Edit Subcategory")
                .font(.title)
                .padding()
            
            Button("Create and Edit Subcategory") {
                createAndEditSubcategory()
            }
            .padding()
        }
        .frame(width: 400, height: 300)
        .sheet(isPresented: $showingSheet) {
            if let subcategory = selectedSubcategory {
                EditSubcategoryView(subcategory: subcategory)
            }
        }
    }
    
    private func createAndEditSubcategory() {
        // Create a test category
        let category = Category(context: viewContext)
        category.id = UUID()
        category.name = "Test Category"
        category.colorHex = "007AFF"
        category.createdAt = Date()
        category.updatedAt = Date()
        
        // Create a test subcategory
        let subcategory = SubCategory(context: viewContext)
        subcategory.id = UUID()
        subcategory.name = "Test Subcategory"
        subcategory.colorHex = "FF0000"
        subcategory.createdAt = Date()
        subcategory.updatedAt = Date()
        subcategory.parentCategory = category
        
        // Save to Core Data
        do {
            try viewContext.save()
            selectedSubcategory = subcategory
            showingSheet = true
        } catch {
            print("Error saving: \(error.localizedDescription)")
        }
    }
}

struct EditSubcategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    var subcategory: SubCategory
    
    @State private var name: String = ""
    @State private var selectedColorIndex: Int = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
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
    
    init(subcategory: SubCategory) {
        self.subcategory = subcategory
        _name = State(initialValue: subcategory.name ?? "")
        
        // Find the index of the color that matches the subcategory's colorHex
        var index = 0
        if let colorHex = subcategory.colorHex {
            let cleanHex = colorHex.replacingOccurrences(of: "#", with: "").uppercased()
            
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
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func updateSubcategory() {
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
            presentationMode.wrappedValue.dismiss()
        } catch {
            showingAlert = true
            alertMessage = "Failed to save subcategory: \(error.localizedDescription)"
        }
    }
}

// MARK: - Core Data Model
class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "NotesApp")
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}

// MARK: - Core Data Model Extensions
extension NSManagedObject {
    convenience init(context: NSManagedObjectContext) {
        let name = String(describing: type(of: self))
        let entity = NSEntityDescription.entity(forEntityName: name, in: context)!
        self.init(entity: entity, insertInto: context)
    }
}

class Category: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var colorHex: String?
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var subcategories: NSSet?
}

class SubCategory: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var colorHex: String?
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var parentCategory: Category?
}
