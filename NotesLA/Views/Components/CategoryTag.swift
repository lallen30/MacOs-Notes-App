import SwiftUI

public struct CategoryTag: View {
    let name: String
    let color: Color
    
    // Initialize with a name and color
    public init(name: String, color: Color) {
        self.name = name
        self.color = color
    }
    
    // Initialize with a name and hex color string
    public init(name: String, hexColor: String) {
        self.name = name
        self.color = Self.getColorFromHex(hexColor)
    }
    
    var body: some View {
        Text(name)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
    
    // Helper function to convert hex to Color
    static func getColorFromHex(_ hex: String) -> Color {
        print("DEBUG: CategoryTag - Converting hex to color: \(hex)")
        
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
            print("DEBUG: CategoryTag - Unknown hex value: \(hex), using blue as fallback")
            return .blue
        }
    }
}

struct CategoryTag_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            CategoryTag(name: "Work", color: .blue)
            CategoryTag(name: "Personal", color: .green)
            CategoryTag(name: "Urgent", color: .red)
        }
        .padding()
    }
}
