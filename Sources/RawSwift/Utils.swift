import libraw
import Foundation

public class Utils {

    public init() {}

    static public func librawVersion() -> String {
        String(cString: libraw_version())
    }
    
    // MARK: - Camera Information
    public static func getCameraInfo(_ rawdata: UnsafeMutablePointer<libraw_data_t>) -> CameraInfo? {
        let idata = rawdata.pointee.idata
        let other = rawdata.pointee.other
        
        return CameraInfo(
            make: withUnsafePointer(to: idata.make) {
                $0.withMemoryRebound(to: CChar.self, capacity: MemoryLayout.size(ofValue: idata.make)) {
                    String(cString: $0)
                }
            },
            model: withUnsafePointer(to: idata.model) {
                $0.withMemoryRebound(to: CChar.self, capacity: MemoryLayout.size(ofValue: idata.model)) {
                    String(cString: $0)
                }
            },
            software: withUnsafePointer(to: idata.software) {
                $0.withMemoryRebound(to: CChar.self, capacity: MemoryLayout.size(ofValue: idata.software)) {
                    String(cString: $0)
                }
            },
            isoSpeed: Int(other.iso_speed),
            shutterSpeed: other.shutter,
            aperture: other.aperture,
            focalLength: other.focal_len,
            timestamp: Date(timeIntervalSince1970: TimeInterval(other.timestamp))
        )
    }
    
    // MARK: - Image Information
    public static func getImageInfo(_ rawdata: UnsafeMutablePointer<libraw_data_t>) -> ImageInfo {
        let sizes = rawdata.pointee.sizes
        let idata = rawdata.pointee.idata
        
        return ImageInfo(
            width: Int(sizes.width),
            height: Int(sizes.height),
            rawWidth: Int(sizes.raw_width),
            rawHeight: Int(sizes.raw_height),
            topMargin: Int(sizes.top_margin),
            leftMargin: Int(sizes.left_margin),
            bitDepth: Int(idata.colors),
            colorCount: Int(idata.colors)
        )
    }
    
    // MARK: - Color Space Information
    public static func getColorMatrix(_ rawdata: UnsafeMutablePointer<libraw_data_t>) -> ColorMatrix {
        let color = rawdata.pointee.color
        
        // Simplified matrix handling - return basic white balance info
        return ColorMatrix(
            cameraXYZ: [],
            rgbCamera: [],
            whiteBalance: [
                color.cam_mul.0,
                color.cam_mul.1,
                color.cam_mul.2,
                color.cam_mul.3
            ]
        )
    }
}

// MARK: - Data Structures
public struct CameraInfo {
    public let make: String
    public let model: String
    public let software: String
    public let isoSpeed: Int
    public let shutterSpeed: Float
    public let aperture: Float
    public let focalLength: Float
    public let timestamp: Date
}

public struct ImageInfo {
    public let width: Int
    public let height: Int
    public let rawWidth: Int
    public let rawHeight: Int
    public let topMargin: Int
    public let leftMargin: Int
    public let bitDepth: Int
    public let colorCount: Int
}

public struct ColorMatrix {
    public let cameraXYZ: [[Float]]
    public let rgbCamera: [[Float]]
    public let whiteBalance: [Float]
}

