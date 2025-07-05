//
//  RawImageViewModel.swift
//  RawSwift-example
//
//  Created by NakaokaRei on 2024/03/25.
//  Enhanced with RAW image processing parameters
//

import Foundation
import AppKit
import RawSwift

@MainActor
class RawImageViewModel: ObservableObject {

    @Published var cgImage: CGImage?
    @Published var processingParams = ImageProcessing.ProcessingParams()
    @Published var cameraInfo: CameraInfo?
    @Published var imageInfo: ImageInfo?
    @Published var isProcessing = false
    @Published var processingProgress: String = ""
    
    private let fileHandling = FileHandling()
    private var rawData: UnsafeMutablePointer<libraw_data_t>?
    private var currentFileURL: URL?
    private var processingTask: Task<Void, Never>?
    
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
        // 既存の処理をキャンセル
        processingTask?.cancel()
        
        // 既存のRAWデータをクリーンアップ
        cleanupRawData()
        
        isProcessing = true
        processingProgress = "Loading RAW file..."
        
        // ファイル読み込みも別スレッドで実行
        processingTask = Task.detached { [weak self] in
            let fileHandling = FileHandling()
            let newRawData = FileHandling.initLibRawData()
            let result = fileHandling.openFile(url: url, rawdata: newRawData)
            
            guard let self = self else { return }
            
            if result == LibRaw_errors.init(0) { // LIBRAW_SUCCESS
                await MainActor.run {
                    self.rawData = newRawData
                    self.currentFileURL = url
                    self.processingProgress = "Extracting metadata..."
                }
                
                // メタデータ取得
                let cameraInfo = Utils.getCameraInfo(newRawData)
                let imageInfo = Utils.getImageInfo(newRawData)
                
                await MainActor.run {
                    self.cameraInfo = cameraInfo
                    self.imageInfo = imageInfo
                    self.processingProgress = "Setting default parameters..."
                    
                    // 初期パラメータを設定
                    self.resetToDefaults()
                }
                
                // 初回画像処理
                await self.processImageInBackground()
            } else {
                await MainActor.run {
                    self.isProcessing = false
                    self.processingProgress = ""
                    print("Failed to open RAW file: \(result)")
                }
            }
        }
    }
    
    private func processImage() {
        // 既存の処理をキャンセル
        processingTask?.cancel()
        
        guard rawData != nil else { return }
        
        processingTask = Task { [weak self] in
            await self?.processImageInBackground()
        }
    }
    
    private func processImageInBackground() async {
        await MainActor.run {
            isProcessing = true
            processingProgress = "Processing RAW image..."
        }
        
        guard let url = currentFileURL else {
            await MainActor.run {
                isProcessing = false
                processingProgress = ""
            }
            return
        }
        
        // 重い画像処理を別スレッドで実行
        let result = await Task.detached { [processingParams] in
            let fileHandling = FileHandling()
            let processRawData = FileHandling.initLibRawData()
            let result = fileHandling.openFile(url: url, rawdata: processRawData)
            
            if result == LibRaw_errors.init(0) {
                return ImageProcessing.getImageFromData(processRawData, params: processingParams)
            }
            return nil
        }.value
        
        await MainActor.run {
            self.cgImage = result
            self.isProcessing = false
            self.processingProgress = ""
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
    
    deinit {
        processingTask?.cancel()
    }
}