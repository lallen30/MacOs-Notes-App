import SwiftUI
import AppKit

extension Color {
    // Create a color from a hex string (with or without # prefix)
    init(hex: String) {
        print("DEBUG: Color initializer with hex: \(hex)")
        
        // Clean up the hex string by removing any non-alphanumeric characters
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        print("DEBUG: Cleaned hex string: \(hexString)")
        
        // Map known color names to their hex values for consistency
        let knownColors: [String: (Color, String)] = [
            "007AFF": (.blue, "Blue"),
            "FF0000": (.red, "Red"),
            "00FF00": (.green, "Green"),
            "FFA500": (.orange, "Orange"),
            "800080": (.purple, "Purple"),
            "FFC0CB": (.pink, "Pink"),
            "FFFF00": (.yellow, "Yellow"),
            "808080": (.gray, "Gray")
        ]
        
        // Check if this is a known color
        if let (knownColor, colorName) = knownColors[hexString.uppercased()] {
            print("DEBUG: Using known color: \(colorName)")
            self = knownColor
            return
        }
        
        // Parse the hex string
        var int: UInt64 = 0
        let success = Scanner(string: hexString).scanHexInt64(&int)
        print("DEBUG: Hex parsing success: \(success)")
        
        let a, r, g, b: UInt64
        
        switch hexString.count {
        case 3: // RGB (12-bit)
            print("DEBUG: Parsing 3-digit hex")
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
            
        case 6: // RGB (24-bit)
            print("DEBUG: Parsing 6-digit hex")
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
            
        case 8: // ARGB (32-bit)
            print("DEBUG: Parsing 8-digit hex")
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
            
        default:
            print("DEBUG: Invalid hex format, using fallback parsing")
            
            // Try to parse it anyway by padding or truncating
            if hexString.count > 6 {
                // Take just the first 6 characters
                let truncated = String(hexString.prefix(6))
                print("DEBUG: Truncating to 6 chars: \(truncated)")
                var truncInt: UInt64 = 0
                if Scanner(string: truncated).scanHexInt64(&truncInt) {
                    (a, r, g, b) = (255, truncInt >> 16, truncInt >> 8 & 0xFF, truncInt & 0xFF)
                } else {
                    (a, r, g, b) = (255, 0, 0, 0) // Black as fallback
                }
            } else if hexString.count > 0 {
                // Pad to 6 characters
                let padded = hexString.padding(toLength: 6, withPad: "0", startingAt: 0)
                print("DEBUG: Padding to 6 chars: \(padded)")
                var paddedInt: UInt64 = 0
                if Scanner(string: padded).scanHexInt64(&paddedInt) {
                    (a, r, g, b) = (255, paddedInt >> 16, paddedInt >> 8 & 0xFF, paddedInt & 0xFF)
                } else {
                    (a, r, g, b) = (255, 0, 0, 0) // Black as fallback
                }
            } else {
                // Empty string, use a default color (red to make it obvious)
                print("DEBUG: Empty hex string, using red as fallback")
                (a, r, g, b) = (255, 255, 0, 0) // Red as fallback for empty string
            }
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
        let nsColor = NSColor(self)
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else {
            return "#007AFF" // Default to blue if conversion fails
        }
        
        let r = Int(rgbColor.redComponent * 255.0)
        let g = Int(rgbColor.greenComponent * 255.0)
        let b = Int(rgbColor.blueComponent * 255.0)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
