#!/bin/bash

# Directory where icons will be saved
ICON_DIR="NotesApp/Assets.xcassets/AppIcon.appiconset"

# Create a simple placeholder icon with text showing the size
generate_icon() {
    size=$1
    output="$ICON_DIR/icon_${size}x${size}.png"
    
    # Use ImageMagick to create a simple icon
    convert -size ${size}x${size} xc:skyblue -fill white -gravity center \
        -pointsize $(($size/4)) -annotate 0 "Notes\n${size}x${size}" \
        -draw "roundrectangle 0,0,$size,$size,$(($size/10)),$(($size/10))" "$output"
    
    echo "Created $output"
}

# Generate all required icon sizes
generate_icon 16
generate_icon 32
generate_icon 64  # 16@2x and 32@2x
generate_icon 128
generate_icon 256
generate_icon 512
generate_icon 1024 # 512@2x

# Create symbolic links for @2x versions
ln -sf icon_64x64.png "$ICON_DIR/icon_16x16@2x.png"
ln -sf icon_64x64.png "$ICON_DIR/icon_32x32@2x.png"
ln -sf icon_256x256.png "$ICON_DIR/icon_128x128@2x.png"
ln -sf icon_512x512.png "$ICON_DIR/icon_256x256@2x.png"
ln -sf icon_1024x1024.png "$ICON_DIR/icon_512x512@2x.png"

echo "All icons generated successfully!"
