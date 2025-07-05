# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Development Commands

### Prerequisites
- macOS 13.0+
- Swift 5.9+
- LibRaw library: `brew install libraw`

### Essential Commands
```bash
# Build the library
swift build

# Run sample executable (shows supported cameras)
swift run Sample

# Build example macOS app
cd RawSwift-example
xcodebuild -scheme RawSwift-example -destination 'platform=macOS' build

# Clean build artifacts
swift package clean
```

### Testing
```bash
# Run tests (via Xcode - recommended)
cd RawSwift-example
xcodebuild test -scheme RawSwift-example -destination 'platform=macOS'
```

## Architecture Overview

### Core Library Structure
RawSwift wraps LibRaw C++ library with three main components:

1. **FileHandling** (`Sources/RawSwift/FileHandling.swift`)
   - LibRaw data initialization and file operations
   - Key methods: `initLibRawData()`, `openFile(url:rawdata:)`

2. **ImageProcessing** (`Sources/RawSwift/ImageProcessing.swift`)
   - RAW processing pipeline: unpack → process → convert to CGImage
   - Main entry point: `getImageFromData(_:)`
   - Pipeline methods: `unpackFile()`, `unpackThumb()`, `process()`, `imageToCGImage()`

3. **Utils** (`Sources/RawSwift/Utils.swift`)
   - LibRaw utility functions

### System Dependencies
- **libraw** system library integrated via module map (`Sources/libraw/`)
- Configured in Package.swift with pkgConfig and Homebrew provider

### Example Application
- SwiftUI-based macOS app demonstrating RAW file processing
- **ViewModel** handles file selection and processing logic
- **ContentView** provides UI for file picker and image display

### Key Architecture Patterns
- **Wrapper Pattern**: Swift classes wrap LibRaw C functions
- **Error Handling**: LibRaw error codes converted to Swift enum
- **Memory Management**: Proper cleanup of LibRaw pointers with error handling
- **SwiftUI Integration**: ViewModel pattern for UI state management

## Development Notes

### Error Handling Flow
All LibRaw operations follow this pattern:
1. Call LibRaw function
2. Check return code against `LIBRAW_SUCCESS`
3. Log error message via `libraw_strerror()` if available
4. Clean up resources (`libraw_close()`, `libraw_recycle()`)

### Memory Management
- LibRaw data structures are managed via `UnsafeMutablePointer<libraw_data_t>`
- Always pair `libraw_init()` with `libraw_close()`
- Free resources in error paths to prevent memory leaks

### Testing Setup
- Tests are located in `RawSwift-example/RawSwift-exampleTests/`
- Currently mostly placeholder tests - implementation needed
- Test RAW files can be placed in `img/` directory