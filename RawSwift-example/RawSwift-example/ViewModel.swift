//
//  ViewModel.swift
//  RawSwift-example
//
//  Created by NakaokaRei on 2024/03/25.
//  Enhanced with RAW image processing parameters
//

import Foundation
import AppKit
import RawSwift

@MainActor
class ViewModel: ObservableObject {

    @Published var cgImage: CGImage?
    @Published var processingParams = ImageProcessing.ProcessingParams()
    @Published var cameraInfo: CameraInfo?
    @Published var imageInfo: ImageInfo?
    @Published var isProcessing = false
    
    private let fileHandling = FileHandling()
    private var rawData: UnsafeMutablePointer<libraw_data_t>?
    private var currentFileURL: URL?
    
    // MARK: - Processing Parameters
    @Published var exposure: Float = 0.0 {
        didSet { updateProcessingParams() }
    }
    @Published var brightness: Float = 1.0 {
        didSet { updateProcessingParams() }
    }
    @Published var temperature: Float = 6500.0 {
        didSet { updateProcessingParams() }
    }
    @Published var tint: Float = 0.0 {
        didSet { updateProcessingParams() }
    }
    @Published var contrast: Float = 1.0 {
        didSet { updateProcessingParams() }
    }
    @Published var saturation: Float = 1.0 {
        didSet { updateProcessingParams() }
    }
    @Published var gamma: Float = 2.2 {
        didSet { updateProcessingParams() }
    }
    @Published var highlightRecovery: Float = 0.0 {
        didSet { updateProcessingParams() }
    }
    @Published var shadowRecovery: Float = 0.0 {
        didSet { updateProcessingParams() }
    }
    @Published var useCameraWB: Bool = true {
        didSet { updateProcessingParams() }
    }
    @Published var demosaicAlgorithm: ImageProcessing.DemosaicAlgorithm = .dcbInterpolation {
        didSet { updateProcessingParams() }
    }
    
    private func updateProcessingParams() {
        processingParams.exposure = exposure
        processingParams.brightness = brightness
        processingParams.temperature = temperature
        processingParams.tint = tint
        processingParams.contrast = contrast
        processingParams.saturation = saturation
        processingParams.gamma = gamma
        processingParams.highlightRecovery = highlightRecovery
        processingParams.shadowRecovery = shadowRecovery
        processingParams.useCameraWB = useCameraWB
        processingParams.demosaicAlgorithm = demosaicAlgorithm
        
        // リアルタイム更新
        if rawData != nil {
            processImage()
        }
    }
    
    func selectRawImage() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.allowedContentTypes = [.rawImage]
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                self.loadRawImage(from: url)
            }
        }
    }
    
    private func loadRawImage(from url: URL) {
        // 既存のRAWデータをクリーンアップ
        cleanupRawData()
        
        let newRawData = FileHandling.initLibRawData()
        let result = fileHandling.openFile(url: url, rawdata: newRawData)
        
        if result == LibRaw_errors.init(0) { // LIBRAW_SUCCESS
            self.rawData = newRawData
            self.currentFileURL = url
            
            // メタデータを取得
            self.cameraInfo = Utils.getCameraInfo(newRawData)
            self.imageInfo = Utils.getImageInfo(newRawData)
            
            // 初期パラメータを設定
            resetToDefaults()
            
            // 初回画像処理
            processImage()
        } else {
            print("Failed to open RAW file: \(result)")
        }
    }
    
    private func processImage() {
        guard rawData != nil else { return }
        
        Task {
            await MainActor.run {
                isProcessing = true
            }
            
            // 新しいRAWデータインスタンスを作成（並列処理用）
            let processRawData = FileHandling.initLibRawData()
            guard let url = currentFileURL else { return }
            
            let result = fileHandling.openFile(url: url, rawdata: processRawData)
            if result == LibRaw_errors.init(0) {
                let processedImage = ImageProcessing.getImageFromData(processRawData, params: processingParams)
                
                await MainActor.run {
                    self.cgImage = processedImage
                    self.isProcessing = false
                }
            } else {
                await MainActor.run {
                    self.isProcessing = false
                }
            }
        }
    }
    
    func resetToDefaults() {
        exposure = 0.0
        brightness = 1.0
        temperature = 6500.0
        tint = 0.0
        contrast = 1.0
        saturation = 1.0
        gamma = 2.2
        highlightRecovery = 0.0
        shadowRecovery = 0.0
        useCameraWB = true
        demosaicAlgorithm = .dcbInterpolation
    }
    
    private func cleanupRawData() {
        if rawData != nil {
            // LibRawデータのクリーンアップ
            // Note: libraw_close は ImageProcessing 内で呼ばれるため、ここでは呼ばない
            self.rawData = nil
        }
    }
}