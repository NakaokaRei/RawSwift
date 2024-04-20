import Foundation
import libraw
import OSLog
import CoreGraphics

public class ImageProcessing {

    public init() {}

    // TODO: get Thumbnail

    // Get an Image from RAW file
    public static func getImageFromData(_ rawdata: UnsafeMutablePointer<libraw_data_t>) -> CGImage? {

        guard unpackFile(rawdata) == LIBRAW_SUCCESS else {
            return nil
        }

        guard unpackThumb(rawdata) == LIBRAW_SUCCESS else {
            return nil
        }

        guard process(rawdata) == LIBRAW_SUCCESS else {
            return nil
        }

//        guard rawToImage(rawdata) == LIBRAW_SUCCESS else {
//            return nil
//        }

        return imageToCGImage(rawdata)
    }

    /// Unpacks the RAW files of the image, calculates the black level (not for all formats). The results are placed in imgdata.image.
    static func unpackFile(_ rawdata: UnsafeMutablePointer<libraw_data_t>) -> LibRaw_errors {
        let result = libraw_unpack(rawdata);

        if (result != LIBRAW_SUCCESS.rawValue) {
            if #available(OSX 11.0, *) {
                let defaultLog = Logger()
                let errorMessage = String(cString: libraw_strerror(result))
                defaultLog.log("LibRaw error: \(errorMessage)")
            }
            libraw_close(rawdata);
        }
        return LibRaw_errors.init(result)
    }

    static func unpackThumb(_ rawdata: UnsafeMutablePointer<libraw_data_t>) -> LibRaw_errors {
        let result = libraw_unpack_thumb(rawdata);

        if (result != LIBRAW_SUCCESS.rawValue) {
            if #available(OSX 11.0, *) {
                let defaultLog = Logger()
                let errorMessage = String(cString: libraw_strerror(result))
                defaultLog.log("LibRaw error: \(errorMessage)")
            }
            libraw_close(rawdata);
        }
        return LibRaw_errors.init(result)
    }

    /// Combines separate RGB layer to one
    static func rawToImage(_ rawdata: UnsafeMutablePointer<libraw_data_t>) -> LibRaw_errors {

        let result = libraw_raw2image(rawdata)

        if (result != LIBRAW_SUCCESS.rawValue) {
            if #available(OSX 11.0, *) {
                let defaultLog = Logger()
                let errorMessage = String(cString: libraw_strerror(result))
                defaultLog.log("LibRaw error: \(errorMessage)")
            }
            libraw_recycle(rawdata);
            libraw_close(rawdata);
        }
        return LibRaw_errors.init(result)
    }

    static func process(_ rawdata: UnsafeMutablePointer<libraw_data_t>) -> LibRaw_errors {
        let result = libraw_dcraw_process(rawdata);
        if (result != LIBRAW_SUCCESS.rawValue) {
            if #available(OSX 11.0, *) {
                let defaultLog = Logger()
                let errorMessage = String(cString: libraw_strerror(result))
                defaultLog.log("LibRaw error: \(errorMessage)")
            }
            libraw_free_image(rawdata);
            libraw_recycle(rawdata);
            libraw_close(rawdata);
        }
        return LibRaw_errors.init(result)
    }

    static func imageToCGImage(_ rawdata : UnsafeMutablePointer<libraw_data_t>) -> CGImage? {
        var result : Int32 = 0
        let processedImage = libraw_dcraw_make_mem_image(rawdata, &result)

        if (processedImage == nil) {
            if #available(OSX 11.0, *) {
                let defaultLog = Logger()
                let errorMessage = String(cString: libraw_strerror(result))
                defaultLog.log("LibRaw error: \(errorMessage)")
            }

            libraw_recycle(rawdata);
            libraw_close(rawdata);
            return nil
        }

        if let data = processedImage?.pointee {
            let heigth = Int(data.height)
            let width = Int(data.width)
            let numberOfComponents = Int(data.colors)
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

            let totalSize = Int(data.data_size)

            // TODO: Image bytes start at processedImage.data - pointer needs to be moved a bit
            let rgbData = (processedImage?.withMemoryRebound(to: UInt8.self, capacity: totalSize) {
                return CFDataCreate(nil, $0, Int(data.data_size))!
            })!

            let provider = CGDataProvider(data: rgbData)!
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)

            let rgbImageRef = CGImage(width: width,
                                      height: heigth,
                                      bitsPerComponent: Int(data.bits),
                                      bitsPerPixel: Int(data.bits) * numberOfComponents,
                                      bytesPerRow: width * numberOfComponents,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo,
                                      provider: provider,
                                      decode: nil,
                                      shouldInterpolate: true,
                                      intent: CGColorRenderingIntent.defaultIntent)

            return rgbImageRef

        }

        libraw_recycle(rawdata);
        libraw_close(rawdata);
        return nil
    }

}
