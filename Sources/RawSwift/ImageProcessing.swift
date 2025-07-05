import Foundation
import libraw
import OSLog
import CoreGraphics

public class ImageProcessing {

    public init() {}

    // MARK: - Processing Parameters
    public struct ProcessingParams {
        public var exposure: Float = 0.0        // 露出補正 (-4.0 ~ +4.0)
        public var brightness: Float = 1.0      // 明るさ (0.25 ~ 8.0)
        public var temperature: Float = 6500.0  // 色温度 (K)
        public var tint: Float = 0.0           // 色合い補正 (-100 ~ +100)
        public var contrast: Float = 1.0       // コントラスト (0.0 ~ 4.0)
        public var saturation: Float = 1.0     // 彩度 (0.0 ~ 4.0)
        public var gamma: Float = 2.2          // ガンマ (0.5 ~ 4.0)
        public var highlightRecovery: Float = 0.0 // ハイライト復元 (0.0 ~ 1.0)
        public var shadowRecovery: Float = 0.0    // シャドウ復元 (0.0 ~ 1.0)
        public var useCameraWB: Bool = true    // カメラのホワイトバランス使用
        public var demosaicAlgorithm: DemosaicAlgorithm = .dcbInterpolation
        
        public init() {}
    }
    
    public enum DemosaicAlgorithm: Int32 {
        case linear = 0
        case vng = 1
        case ppg = 2
        case ahd = 3
        case dcbInterpolation = 4
        case dcbInterpAndCorrection = 5
        case lmmse = 11
        case amaze = 12
    }

    // TODO: get Thumbnail

    // Get an Image from RAW file
    public static func getImageFromData(_ rawdata: UnsafeMutablePointer<libraw_data_t>) -> CGImage? {
        return getImageFromData(rawdata, params: ProcessingParams())
    }
    
    // Get an Image from RAW file with processing parameters
    public static func getImageFromData(_ rawdata: UnsafeMutablePointer<libraw_data_t>, params: ProcessingParams) -> CGImage? {
        
        // Apply processing parameters
        guard applyProcessingParams(rawdata, params: params) == LIBRAW_SUCCESS else {
            return nil
        }

        guard unpackFile(rawdata) == LIBRAW_SUCCESS else {
            return nil
        }

        guard unpackThumb(rawdata) == LIBRAW_SUCCESS else {
            return nil
        }

        guard process(rawdata) == LIBRAW_SUCCESS else {
            return nil
        }

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

    // MARK: - Processing Parameters Application
    static func applyProcessingParams(_ rawdata: UnsafeMutablePointer<libraw_data_t>, params: ProcessingParams) -> LibRaw_errors {
        
        // 露出補正
        rawdata.pointee.params.exp_correc = params.exposure != 0.0 ? 1 : 0
        rawdata.pointee.params.exp_shift = params.exposure
        
        // 明るさ
        rawdata.pointee.params.bright = params.brightness
        
        // ガンマ補正
        rawdata.pointee.params.gamm.0 = Double(1.0 / params.gamma)
        rawdata.pointee.params.gamm.1 = Double(1.0 / params.gamma)
        
        // デモザイクアルゴリズム
        rawdata.pointee.params.user_qual = params.demosaicAlgorithm.rawValue
        
        // カメラのホワイトバランス
        rawdata.pointee.params.use_camera_wb = params.useCameraWB ? 1 : 0
        
        // 色温度設定（カメラWB未使用時）
        if !params.useCameraWB {
            rawdata.pointee.params.user_mul.0 = 1.0  // R
            rawdata.pointee.params.user_mul.1 = 1.0  // G
            rawdata.pointee.params.user_mul.2 = 1.0  // B
            rawdata.pointee.params.user_mul.3 = 1.0  // G2
            
            // 色温度から係数を計算（簡易版）
            let tempRatio = params.temperature / 6500.0
            rawdata.pointee.params.user_mul.0 = Float(1.0 / tempRatio)      // R
            rawdata.pointee.params.user_mul.2 = Float(tempRatio)            // B
        }
        
        // ハイライト復元
        rawdata.pointee.params.highlight = params.highlightRecovery > 0 ? 1 : 0
        
        // 出力設定
        rawdata.pointee.params.output_color = 1  // sRGB
        rawdata.pointee.params.output_bps = 8    // 8bit
        
        return LibRaw_errors.init(LIBRAW_SUCCESS.rawValue)
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
