# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

This is an iOS keyboard panel framework with a main app (`keybaord`) and a Swift Package (`KeyboardPanelKit`).

### KeyboardPanelKit Architecture

The kit provides keyboard-aware panel components with two main patterns:

1. **Embedded Panel Pattern** - `KeyboardPanelController` + `KeyboardPanelView`
   - UIKit-based controller with SwiftUI content wrapper
   - Shows toolbar above system keyboard with swappable function panels
   - Panel slides up from keyboard position when keyboard is dismissed
   - Key components:
     - `KeyboardPanelController` - Main UIViewController managing keyboard layout
     - `KeyboardPanelView` - SwiftUI wrapper using UIViewControllerRepresentable
     - `KeyboardAccessoryView` - Toolbar with text input and function buttons
     - `KeyboardFocusController` - Singleton for managing keyboard first responder
     - `KeyboardPanelItem` - Model for function panel items

2. **Dock Container Pattern** - `KeyboardDockContainerController` + `KeyboardDockContainerModifier`
   - Independent window overlay that docks to keyboard top edge
   - Supports single content or split base/overlay views
   - Tap-to-dismiss dimming background
   - Self-contained - no external dependencies (previously required Container/Routing/SkinManager)
   - Uses `WindowContainerHandle` protocols for abstraction

## Build Commands

```bash
# Build the Xcode project
xcodebuild -project keybaord.xcodeproj -scheme keybaord -configuration Debug build

# Build the Swift Package (from KeyboardPanelKit directory)
cd KeyboardPanelKit && swift build

# Build for testing
cd KeyboardPanelKit && swift build -c debug
```

## Design Notes

- `KeyboardDockContainerController` was refactored to remove external dependencies (`Container.shared.skinManager()`, `Container.shared.routing()`) - it now works standalone
- Window level uses `UIWindow.Level.normal.rawValue + 1000` instead of the non-existent `.keyboardDock`
- All keyboard animation uses the system's keyboard animation curve for smooth transitions
- Animation curve is extracted from keyboard notification userInfo: `UIView.AnimationOptions(rawValue: curve << 16)`
- Keyboard detection uses best-effort window scanning for compatibility (finds system keyboard window by iterating windows)

## Platform Support

- **iOS**: 15.0+
- **macOS**: 12.0+ (limited support - keyboard panels are primarily iOS-focused)

## Dependencies

- Zero external dependencies - uses only Apple frameworks (UIKit, SwiftUI, Foundation)
