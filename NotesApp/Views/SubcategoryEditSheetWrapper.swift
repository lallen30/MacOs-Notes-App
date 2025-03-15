import SwiftUI

struct SubcategoryEditSheetWrapper: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool
    @Binding var selectedSubcategory: SubCategory?
    var onDismiss: () -> Void
    
    var body: some View {
        if let subcategory = selectedSubcategory {
            SubcategoryEditView(subcategory: subcategory, onDismiss: {
                isPresented = false
                selectedSubcategory = nil
                onDismiss()
            })
        } else {
            Text("No subcategory selected")
                .onAppear {
                    // If no subcategory is selected, dismiss the sheet
                    isPresented = false
                }
        }
    }
}
