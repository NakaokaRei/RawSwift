import Foundation
import libraw
import OSLog
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public class ImageProcessing {

    public init() {}

    // MARK: - Processing Parameters
    public struct ProcessingParams {
        public var exposure: Float = 0.0        // 露出補正 (-3.0 ~ +3.0 stops)
        public var brightness: Float = 1.0      // 明るさ (0.25 ~ 8.0)
        public var temperature: Float = 6500.0  // 色温度 (K) - 設定可能だが、カメラWB使用時は無効
        public var tint: Float = 0.0           // 色合い補正 - カスタム実装
        public var contrast: Float = 1.0       // コントラスト - カスタム実装 (0.0 ~ 4.0)
        public var saturation: Float = 1.0     // 彩度 - カスタム実装 (0.0 ~ 4.0)
        public var gamma: Float = 2.2          // ガンマ (0.5 ~ 4.0)
        public var highlightRecovery: Int32 = 0 // ハイライト復元 (0-9)
        public var shadowRecovery: Float = 0.0  // シャドウ復元 - カスタム実装 (0.0 ~ 1.0)
        public var useCameraWB: Bool = false   // カメラのホワイトバランス使用
        public var useAutoWB: Bool = false     // 自動ホワイトバランス使用
        public var demosaicAlgorithm: DemosaicAlgorithm = .dcbInterpolation
        public var noAutoBright: Bool = false  // 自動明度調整を無効化
        public var fourColorRGB: Bool = false  // 4色RGB補間を使用
        
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
        
        // 露出補正 (LibRaw exp_shift: 0.25 (2-stop darken) to 8.0 (3-stop lighter), default 1.0)
        if params.exposure != 0.0 {
            rawdata.pointee.params.exp_correc = 1
            // exp_shift = 2^exposure (where exposure is in stops)
            rawdata.pointee.params.exp_shift = Float(pow(2.0, Double(params.exposure)))
            rawdata.pointee.params.exp_preser = 0.0  // preserve highlights
        } else {
            rawdata.pointee.params.exp_correc = 0
            rawdata.pointee.params.exp_shift = 1.0
        }
        
        // 明るさ (0.25 ~ 8.0)
        rawdata.pointee.params.bright = params.brightness
        
        // ガンマ補正 (BT.709標準: gamm[0] = 1/2.222, gamm[1] = 4.5)
        if params.gamma > 0 {
            rawdata.pointee.params.gamm.0 = Double(1.0 / params.gamma)  // 逆ガンマ値
            rawdata.pointee.params.gamm.1 = 4.5                         // toe slope (BT.709標準)
        }
        
        // デモザイクアルゴリズム
        rawdata.pointee.params.user_qual = params.demosaicAlgorithm.rawValue
        
        // ホワイトバランス設定の優先順位を明確化
        if params.useCameraWB {
            // カメラWB優先
            rawdata.pointee.params.use_camera_wb = 1
            rawdata.pointee.params.use_auto_wb = 0
            // user_mulをゼロクリアしてカメラWBを確実に使用
            rawdata.pointee.params.user_mul.0 = 0
            rawdata.pointee.params.user_mul.1 = 0
            rawdata.pointee.params.user_mul.2 = 0
            rawdata.pointee.params.user_mul.3 = 0
        } else if params.useAutoWB {
            // 自動WB
            rawdata.pointee.params.use_camera_wb = 0
            rawdata.pointee.params.use_auto_wb = 1
            rawdata.pointee.params.user_mul.0 = 0
            rawdata.pointee.params.user_mul.1 = 0
            rawdata.pointee.params.user_mul.2 = 0
            rawdata.pointee.params.user_mul.3 = 0
        } else {
            // マニュアルWB
            rawdata.pointee.params.use_camera_wb = 0
            rawdata.pointee.params.use_auto_wb = 0
        }
        
        // マニュアル色温度設定（カメラWBと自動WB両方が無効時のみ）
        if !params.useCameraWB && !params.useAutoWB {
            // より自然なバランスに調整
            rawdata.pointee.params.user_mul.0 = 1.0  // R (基準)
            rawdata.pointee.params.user_mul.1 = 0.9  // G (軽く抑制)
            rawdata.pointee.params.user_mul.2 = 1.1  // B (軽く強化)
            rawdata.pointee.params.user_mul.3 = 0.9  // G2 (軽く抑制)
        }
        
        // ハイライト復元モード (0: clip, 1: unclip, 2: blend, 3-9: rebuild)
        rawdata.pointee.params.highlight = params.highlightRecovery
        
        // その他の設定
        rawdata.pointee.params.no_auto_bright = params.noAutoBright ? 1 : 0
        rawdata.pointee.params.four_color_rgb = params.fourColorRGB ? 1 : 0
        
        // 出力設定
        rawdata.pointee.params.output_color = 0   // RAW色空間（カラーマトリックス変換なし）
        rawdata.pointee.params.output_bps = 8     // 8bit出力
        rawdata.pointee.params.output_tiff = 0    // TIFF出力無効
        rawdata.pointee.params.use_camera_matrix = 1  // カメラマトリックス使用
        rawdata.pointee.params.half_size = 0      // フルサイズ出力
        
        // カラープロファイル設定を標準化
        rawdata.pointee.params.camera_profile = nil  // 埋め込みプロファイル無効
        rawdata.pointee.params.output_profile = nil  // 出力プロファイル無効
        
        // 向きの問題を解決: カメラのEXIF回転情報を使用
        rawdata.pointee.params.user_flip = -1    // -1: EXIFに従って自動回転
        rawdata.pointee.params.user_black = 0
        rawdata.pointee.params.user_cblack.0 = 0
        rawdata.pointee.params.user_cblack.1 = 0
        rawdata.pointee.params.user_cblack.2 = 0
        rawdata.pointee.params.user_cblack.3 = 0
        
        return LibRaw_errors.init(LIBRAW_SUCCESS.rawValue)
    }
    
    // MARK: - Helper Functions
    
    /// 色温度(K)からRGB倍率を計算
    /// Planckian locusに基づく近似計算
    private static func kelvinToRGB(_ temperature: Double) -> (Double, Double, Double) {
        let temp = temperature / 100.0
        
        var red: Double
        var green: Double
        var blue: Double
        
        // Red component
        if temp <= 66 {
            red = 255
        } else {
            red = temp - 60
            red = 329.698727446 * pow(red, -0.1332047592)
            red = max(0, min(255, red))
        }
        
        // Green component
        if temp <= 66 {
            green = temp
            green = 99.4708025861 * log(green) - 161.1195681661
        } else {
            green = temp - 60
            green = 288.1221695283 * pow(green, -0.0755148492)
        }
        green = max(0, min(255, green))
        
        // Blue component
        if temp >= 66 {
            blue = 255
        } else {
            if temp <= 19 {
                blue = 0
            } else {
                blue = temp - 10
                blue = 138.5177312231 * log(blue) - 305.0447927307
                blue = max(0, min(255, blue))
            }
        }
        
        // 正規化してLibRaw用の倍率に変換
        let maxComponent = max(red, max(green, blue))
        return (red / maxComponent, green / maxComponent, blue / maxComponent)
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

        defer {
            // LibRawによって割り当てられたメモリを解放
            if let processedImage = processedImage {
                libraw_dcraw_clear_mem(processedImage)
            }
            libraw_recycle(rawdata);
            libraw_close(rawdata);
        }

        guard let data = processedImage?.pointee else {
            return nil
        }
        
        // ビットマップタイプのみサポート
        guard data.type == LIBRAW_IMAGE_BITMAP else {
            if #available(OSX 11.0, *) {
                let defaultLog = Logger()
                defaultLog.log("Unsupported image type")
            }
            return nil
        }

        let height = Int(data.height)
        let width = Int(data.width)
        let numberOfComponents = Int(data.colors)
        let bitsPerComponent = Int(data.bits)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        
        // LibRawのデータポインターから正しくデータを取得
        let imageDataSize = height * width * numberOfComponents * (bitsPerComponent / 8)
        let totalSize = Int(data.data_size)
        
        // processedImageから直接データを取得して色チャンネルを修正
        let rgbData = processedImage?.withMemoryRebound(to: UInt8.self, capacity: totalSize) { ptr in
            if numberOfComponents == 3 {
                let mutableData = Data(bytes: ptr, count: imageDataSize)
                var bytes = Array(mutableData)
                
                // LibRawの出力がBGR順序の場合、RGB順序に変換
                for i in stride(from: 0, to: bytes.count, by: 3) {
                    let temp = bytes[i]      // B
                    bytes[i] = bytes[i + 2]  // B <- R
                    bytes[i + 2] = temp      // R <- B
                    // G (bytes[i + 1]) はそのまま
                }
                
                return CFDataCreate(nil, bytes, imageDataSize)!
            } else {
                return CFDataCreate(nil, ptr, imageDataSize)!
            }
        }
        
        guard let provider = CGDataProvider(data: rgbData!) else {
            return nil
        }
        
        // RGB順序でCGImageを作成
        let bitmapInfo: CGBitmapInfo = [
            CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            CGBitmapInfo(rawValue: CGBitmapInfo.byteOrderDefault.rawValue)
        ]
        
        let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerComponent * numberOfComponents,
            bytesPerRow: width * numberOfComponents * (bitsPerComponent / 8),
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: CGColorRenderingIntent.defaultIntent
        )

        return cgImage
    }
    
    // MARK: - JPEG Export Functions
    
    /// RAW画像を処理してJPEGファイルとして保存
    public static func saveRawAsJpeg(
        _ rawdata: UnsafeMutablePointer<libraw_data_t>,
        to outputPath: URL,
        params: ProcessingParams = ProcessingParams(),
        quality: Float = 0.9
    ) -> Bool {
        guard let cgImage = getImageFromData(rawdata, params: params) else {
            return false
        }
        
        return saveCGImageAsJpeg(cgImage, to: outputPath, quality: quality)
    }
    
    /// RAWファイルからJPEGファイルを直接作成
    public static func convertRawToJpeg(
        inputPath: URL,
        outputPath: URL,
        params: ProcessingParams = ProcessingParams(),
        quality: Float = 0.9
    ) -> Bool {
        // RAWファイルを開く
        let rawdata = FileHandling.initLibRawData()
        
        defer {
            libraw_close(rawdata)
        }
        
        let fileHandler = FileHandling()
        guard fileHandler.openFile(url: inputPath, rawdata: rawdata) == LIBRAW_SUCCESS else {
            return false
        }
        
        return saveRawAsJpeg(rawdata, to: outputPath, params: params, quality: quality)
    }
    
    /// CGImageをJPEGファイルとして保存
    public static func saveCGImageAsJpeg(
        _ image: CGImage,
        to outputPath: URL,
        quality: Float = 0.9
    ) -> Bool {
        guard let destination = CGImageDestinationCreateWithURL(
            outputPath as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            if #available(OSX 11.0, *) {
                let defaultLog = Logger()
                defaultLog.log("Failed to create JPEG destination")
            }
            return false
        }
        
        // JPEG品質設定
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        // 画像を追加
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        
        // ファイルに書き込み
        let success = CGImageDestinationFinalize(destination)
        
        if !success {
            if #available(OSX 11.0, *) {
                let defaultLog = Logger()
                defaultLog.log("Failed to write JPEG file")
            }
        }
        
        return success
    }

}
