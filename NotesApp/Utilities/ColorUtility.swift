import SwiftUI
import AppKit

// A central utility for handling color conversions consistently throughout the app
public struct ColorUtility {
    // Standard color mapping - used for both converting hex to color and color to hex
    public static let standardColors: [(color: Color, hex: String, name: String)] = [
        (.blue, "007AFF", "Blue"),
        (.red, "FF0000", "Red"),
        (.green, "00FF00", "Green"),
        (.orange, "FFA500", "Orange"),
        (.purple, "800080", "Purple"),
        (.pink, "FFC0CB", "Pink"),
        (.yellow, "FFFF00", "Yellow"),
        (.gray, "808080", "Gray")
    ]
    
    // Convert hex string to SwiftUI Color
    public static func color(from hex: String) -> Color {
        // Clean the hex string (remove # if present)
        let cleanHex = hex.replacingOccurrences(of: "#", with: "").uppercased()
        
        // First try to match with standard colors
        for colorInfo in standardColors {
            if colorInfo.hex == cleanHex {
                print("DEBUG: ColorUtility - Matched standard color: \(colorInfo.name)")
                return colorInfo.color
            }
        }
        
        // If no match, parse the hex
        print("DEBUG: ColorUtility - No standard color match, parsing hex: \(cleanHex)")
        return Color(hex: cleanHex)
    }
    
    // Get the hex string for a color
    public static func hex(from color: Color) -> String {
        // First try to match with standard colors
        let nsColor = NSColor(color)
        
        // Try to match with standard colors first
        for colorInfo in standardColors {
            if colorInfo.color.description == color.description {
                print("DEBUG: ColorUtility - Matched standard color for hex: \(colorInfo.name)")
                return colorInfo.hex
            }
        }
        
        // If no match, convert to hex
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else {
            print("DEBUG: ColorUtility - Color conversion failed, using default blue")
            return "007AFF" // Default to blue
        }
        
        let r = Int(rgbColor.redComponent * 255.0)
        let g = Int(rgbColor.greenComponent * 255.0)
        let b = Int(rgbColor.blueComponent * 255.0)
        
        let hexString = String(format: "%02X%02X%02X", r, g, b)
        print("DEBUG: ColorUtility - Converted to hex: \(hexString)")
        return hexString
    }
    
    // Get color name from hex
    public static func colorName(from hex: String) -> String {
        let cleanHex = hex.replacingOccurrences(of: "#", with: "").uppercased()
        
        for colorInfo in standardColors {
            if colorInfo.hex == cleanHex {
                return colorInfo.name
            }
        }
        
        return "Custom"
    }
}

// Extension for Color to use the utility
extension Color {
    // Create a color from a hex string (with or without # prefix)
    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        
        Scanner(string: hexString).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hexString.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            // Default to blue for invalid format
            (a, r, g, b) = (255, 0, 122, 255)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // Convert a Color to a hex string
    func toHexString() -> String {
        return ColorUtility.hex(from: self)
    }
}
