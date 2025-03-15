import SwiftUI
import CoreData

struct BasicCategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedCategory: Category?
    @State private var selectedSubcategory: SubCategory?
    @State private var showingCreateCategorySheet = false
    @State private var showingCreateSubcategorySheet = false
    @State private var refreshCategoryList = false
    
    // MARK: - Color Utility
    private func getColorFromHex(_ hex: String) -> Color {
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
    
    var body: some View {
        NavigationView {
            // Left sidebar with categories and subcategories
            List {
                // Header with create button
                HStack {
                    Text("Categories")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        showingCreateCategorySheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 8)
                
                // Categories with subcategories
                ForEach(fetchCategories(), id: \\.self) { category in
                    DisclosureGroup {
                        // Subcategories
                        if let subcategories = category.subcategories as? Set<SubCategory>, !subcategories.isEmpty {
                            ForEach(Array(subcategories).sorted(by: { ($0.name ?? "") < ($1.name ?? "") }), id: \\.self) { subcategory in
                                HStack {
                                    Circle()
                                        .fill(getColorFromHex(subcategory.colorHex ?? "007AFF"))
                                        .frame(width: 10, height: 10)
                                    
                                    Text(subcategory.name ?? "Unnamed")
                                        .lineLimit(1)
                                        .font(.system(size: 13))
                                    
                                    Spacer()
                                    
                                    // Count notes in this subcategory
                                    Text("\\(subcategory.notes?.count ?? 0)")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(.leading, 10)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCategory = category
                                    selectedSubcategory = subcategory
                                }
                                .background(selectedSubcategory == subcategory ? Color.accentColor.opacity(0.1) : Color.clear)
                            }
                        }
                        
                        // Add subcategory button
                        Button(action: {
                            selectedCategory = category
                            showingCreateSubcategorySheet = true
                        }) {
                            Label("Add Subcategory", systemImage: "plus")
                                .font(.caption)
                        }
                        .padding(.leading, 10)
                        .buttonStyle(.plain)
                    } label: {
                        HStack {
                            Circle()
                                .fill(getColorFromHex(category.colorHex ?? "007AFF"))
                                .frame(width: 12, height: 12)
                            
                            Text(category.name ?? "Unnamed")
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\\(category.notes?.count ?? 0)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCategory = category
                            selectedSubcategory = nil
                        }
                        .background(selectedCategory == category && selectedSubcategory == nil ? Color.accentColor.opacity(0.1) : Color.clear)
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 220)
            
            // Right side - placeholder for note content
            VStack {
                if let subcategory = selectedSubcategory {
                    Text("Selected Subcategory: \\(subcategory.name ?? "")")
                        .font(.headline)
                } else if let category = selectedCategory {
                    Text("Selected Category: \\(category.name ?? "")")
                        .font(.headline)
                } else {
                    Text("Select a category or subcategory")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        .sheet(isPresented: $showingCreateCategorySheet) {
            // Use a simple sheet for creating categories
            VStack {
                Text("Create Category")
                    .font(.headline)
                    .padding()
                
                TextField("Category Name", text: .constant("New Category"))
                    .padding()
                
                Button("Add Category") {
                    let _ = Category.create(name: "New Category", context: viewContext)
                    showingCreateCategorySheet = false
                    refreshCategoryList.toggle()
                }
                .padding()
            }
            .frame(width: 300, height: 200)
        }
        .sheet(isPresented: $showingCreateSubcategorySheet) {
            // Use a simple sheet for creating subcategories
            VStack {
                Text("Create Subcategory")
                    .font(.headline)
                    .padding()
                
                if let category = selectedCategory {
                    TextField("Subcategory Name", text: .constant("New Subcategory"))
                        .padding()
                    
                    Button("Add Subcategory") {
                        let _ = SubCategory.create(name: "New Subcategory", parentCategory: category, colorHex: category.colorHex, context: viewContext)
                        showingCreateSubcategorySheet = false
                        refreshCategoryList.toggle()
                    }
                    .padding()
                }
            }
            .frame(width: 300, height: 200)
        }
    }
    
    // MARK: - Category Management Functions
    private func fetchCategories() -> [Category] {
        let request = NSFetchRequest<Category>(entityName: "Category")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \\Category.name, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching categories: \\(error)")
            return []
        }
    }
}

struct BasicCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        BasicCategoryView()
            .environment(\\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
