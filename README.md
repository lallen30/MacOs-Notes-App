# NotesApp for macOS

A native macOS application for managing notes with categories, search, filtering, and offline capabilities.

## Features

- Create, edit, and delete notes
- Organize notes with categories and subcategories
- Color-code categories for visual organization
- Search notes by title or content
- Filter notes by title, creation date, or last updated date
- Fully offline functionality with Core Data storage
- Modern SwiftUI interface
- Native macOS experience

## Requirements

- macOS 13.0+
- Xcode 14.0+
- Swift 5.0+

## Getting Started

1. Open the `NotesApp.xcodeproj` file in Xcode
2. Select your development team in the signing & capabilities section if you want to run on your device
3. Build and run the application (⌘+R)

## App Structure

- **Models**: Core Data models for notes, categories, and subcategories with extension methods
- **Views**: SwiftUI views for the home screen, category management, note list, and detail screens
- **Core Data**: Persistence layer for storing all data locally

## Usage

- **Creating a Note**: Click the "+" button in the toolbar or use ⌘+N
- **Editing a Note**: Select a note and click "Edit" or use ⌘+E
- **Searching**: Type in the search field or use ⌘+F to focus the search field
- **Filtering**: Use the sort menu to filter by title, creation date, or last updated date
- **Deleting**: Right-click on a note in the list and select "Delete"

### Category Management

- **Creating a Category**: Click the "Add Category" button in the sidebar
- **Creating a Subcategory**: Expand a category and click "Add Subcategory"
- **Assigning Categories**: When creating or editing a note, select a category and optional subcategory
- **Viewing by Category**: Click on a category or subcategory in the sidebar to view all associated notes
- **Color Coding**: Each category can have a custom color for visual organization

## License

This project is available for personal use.
