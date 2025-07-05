import libraw
import RawSwift
import Foundation

// サポートされているカメラリストを表示
let cStringArray: UnsafeMutablePointer<UnsafePointer<CChar>?>! = libraw_cameraList()
var stringArray: [String] = []

var currentIndex = 0
while let cString = cStringArray[currentIndex] {
    stringArray.append(String(cString: cString))
    currentIndex += 1
}

print("Supported cameras: \(stringArray.count)")
print(stringArray.prefix(10)) // 最初の10台のカメラを表示

// JPEG出力テスト機能
print("\n--- JPEG Export Test ---")

// テスト用のRAWファイルパス（存在する場合）
let testRawPaths = [
    "img/test.ARW",
    "img/DSC01324.ARW",
    "test.raw",
    "sample.arw"
]

for testPath in testRawPaths {
    let inputURL = URL(fileURLWithPath: testPath)
    
    if FileManager.default.fileExists(atPath: testPath) {
        print("Testing JPEG export with: \(testPath)")
        
        let outputPath = testPath.replacingOccurrences(of: ".ARW", with: "_converted.jpg")
                                 .replacingOccurrences(of: ".raw", with: "_converted.jpg")
                                 .replacingOccurrences(of: ".arw", with: "_converted.jpg")
        let outputURL = URL(fileURLWithPath: outputPath)
        
        let params = ImageProcessing.ProcessingParams()
        let success = ImageProcessing.convertRawToJpeg(
            inputPath: inputURL,
            outputPath: outputURL,
            params: params,
            quality: 0.9
        )
        
        if success {
            print("✅ Successfully converted to: \(outputPath)")
        } else {
            print("❌ Failed to convert: \(testPath)")
        }
        break // 最初に見つかったファイルのみテスト
    }
}

print("Sample completed.")
