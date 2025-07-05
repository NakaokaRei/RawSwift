# RawSwift

A comprehensive Swift wrapper for the [LibRaw](https://github.com/LibRaw/LibRaw) API, providing professional-grade RAW image processing capabilities for macOS applications.

## Features

### Core Library (RawSwift)
- **Complete LibRaw Integration**: Full Swift wrapper around the LibRaw C API
- **Comprehensive Processing Parameters**: Exposure, color temperature, contrast, saturation, gamma, and more
- **Multiple Demosaic Algorithms**: Linear, VNG, PPG, AHD, DCB, LMMSE, AMaZE support
- **Metadata Extraction**: Camera information, EXIF data, and image specifications
- **Memory Management**: Safe handling of LibRaw data structures
- **Thread-Safe Operations**: Background processing support for non-blocking UI

### Demo Application (RawSwift-example)
- **Professional SwiftUI Interface**: Modern, intuitive RAW image editor
- **Real-time Parameter Adjustment**: Live preview of processing changes
- **Background Processing**: Heavy image operations run off the main thread
- **Comprehensive Loading Indicators**: Progress tracking and status updates
- **Rich Metadata Display**: Camera settings, image dimensions, and technical details
- **Multiple Export Options**: Support for various output formats

## Supported RAW Formats

RawSwift supports all RAW formats supported by LibRaw, including:
- Canon (CR2, CR3)
- Nikon (NEF, NRW)
- Sony (ARW, SRF, SR2)
- Adobe (DNG)
- Panasonic (RW2)
- Fujifilm (RAF)
- Olympus (ORF)
- And many more...

## Requirements

- macOS 14.3+
- Xcode 15.0+
- Swift 5.0+
- LibRaw 0.21.2+ (installed via Homebrew)

## Installation

### Prerequisites

Install LibRaw using Homebrew:

```bash
brew install libraw little-cms2
```

### Swift Package Manager

Add RawSwift to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/NakaokaRei/RawSwift.git", from: "1.0.0")
]
```

## Usage

### Basic RAW Processing

```swift
import RawSwift

// Initialize file handling
let fileHandling = FileHandling()
let rawData = FileHandling.initLibRawData()

// Open RAW file
let result = fileHandling.openFile(url: rawFileURL, rawdata: rawData)

// Configure processing parameters
var params = ImageProcessing.ProcessingParams()
params.exposure = 1.0
params.temperature = 6500.0
params.demosaicAlgorithm = .dcbInterpolation

// Process image
let cgImage = ImageProcessing.getImageFromData(rawData, params: params)
```

### Advanced Processing with Metadata

```swift
// Extract camera information
let cameraInfo = Utils.getCameraInfo(rawData)
print("Camera: \(cameraInfo.make) \(cameraInfo.model)")

// Get image specifications
let imageInfo = Utils.getImageInfo(rawData)
print("Resolution: \(imageInfo.width)×\(imageInfo.height)")

// Apply comprehensive adjustments
params.brightness = 1.2
params.contrast = 1.1
params.saturation = 1.05
params.gamma = 2.2
params.highlightRecovery = 0.2
params.shadowRecovery = 0.1
```

### Background Processing (Recommended)

```swift
Task.detached {
    let processedImage = ImageProcessing.getImageFromData(rawData, params: params)
    
    await MainActor.run {
        // Update UI with processed image
        self.displayImage = processedImage
    }
}
```

## Demo Application

The included demo application showcases all RawSwift capabilities:

1. **File Selection**: Choose RAW images with native file picker
2. **Real-time Editing**: Adjust processing parameters with immediate feedback
3. **Metadata Viewing**: Inspect camera settings and image properties
4. **Export Options**: Save processed images in various formats

To run the demo:

```bash
cd RawSwift-example
open RawSwift-example.xcodeproj
```

## Architecture

### RawSwift Library Structure

```
Sources/RawSwift/
├── FileHandling.swift      # RAW file I/O operations
├── ImageProcessing.swift   # Core processing and parameters
├── Utils.swift            # Metadata extraction utilities
└── libraw/                # LibRaw C library integration
    ├── module.modulemap
    └── libraw_wrapper.h
```

### Demo Application Structure

```
RawSwift-example/
├── RawImageEditView.swift     # Main editing interface
├── RawImageViewModel.swift    # Business logic and state management
└── RawSwift_exampleApp.swift  # Application entry point
```

## Processing Parameters

| Parameter | Range | Description |
|-----------|-------|-------------|
| Exposure | -4.0 to 4.0 EV | Exposure compensation |
| Brightness | 0.25 to 4.0 | Overall brightness adjustment |
| Temperature | 2000K to 10000K | White balance temperature |
| Tint | -100 to 100 | White balance tint |
| Contrast | 0.0 to 4.0 | Contrast adjustment |
| Saturation | 0.0 to 4.0 | Color saturation |
| Gamma | 0.5 to 4.0 | Gamma correction |
| Highlight Recovery | 0.0 to 1.0 | Recover blown highlights |
| Shadow Recovery | 0.0 to 1.0 | Lift shadow details |

## Demosaic Algorithms

- **Linear**: Simple linear interpolation
- **VNG**: Variable Number of Gradients
- **PPG**: Patterned Pixel Grouping
- **AHD**: Adaptive Homogeneity-Directed
- **DCB**: DCB Interpolation
- **DCB + Correction**: DCB with color correction
- **LMMSE**: Linear Minimum Mean Square Error
- **AMaZE**: Aliasing Minimization and Zipper Elimination

## Performance

- **Background Processing**: Heavy operations run on background threads
- **Memory Efficient**: Proper LibRaw data lifecycle management
- **Optimized for Real-time**: Responsive UI with immediate parameter feedback
- **Cancellation Support**: Long-running operations can be interrupted

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [LibRaw](https://github.com/LibRaw/LibRaw) - The underlying RAW processing library
- [Little-CMS](http://www.littlecms.com/) - Color management engine
- SwiftUI - Modern declarative UI framework

## Roadmap

- [ ] Batch processing support
- [ ] Additional export formats
- [ ] Lens correction profiles
- [ ] HDR processing capabilities
- [ ] Plugin architecture for custom filters

---

Built with ❤️ using Swift and LibRaw