//
//  RawImageEditView.swift
//  RawSwift-example
//
//  Created by NakaokaRei on 2024/03/25.
//

import SwiftUI
import RawSwift

struct RawImageEditView: View {

    @StateObject private var viewModel = RawImageViewModel()

    var body: some View {
        HSplitView {
            // Left Panel - Controls
            VStack(alignment: .leading, spacing: 20) {
                // File Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("File Operations")
                        .font(.headline)
                    
                    HStack {
                        Button("Select RAW Image") {
                            viewModel.selectRawImage()
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isProcessing)
                        
                        Button("Reset to Defaults") {
                            viewModel.resetToDefaults()
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.cgImage == nil || viewModel.isProcessing)
                    }
                }
                
                Divider()
                
                // Processing Status
                if viewModel.isProcessing {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Processing")
                                .font(.headline)
                            Spacer()
                        }
                        
                        if !viewModel.processingProgress.isEmpty {
                            Text(viewModel.processingProgress)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    Divider()
                }
                
                // Processing Controls
                if viewModel.cgImage != nil && !viewModel.isProcessing {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Image Processing")
                                .font(.headline)
                            
                            // Exposure Controls
                            Group {
                                Text("Exposure & Brightness")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                SliderControl(
                                    label: "Exposure",
                                    value: $viewModel.exposure,
                                    range: -3.0...3.0,
                                    step: 0.1,
                                    unit: "EV"
                                )
                                
                                SliderControl(
                                    label: "Brightness",
                                    value: $viewModel.brightness,
                                    range: 0.25...4.0,
                                    step: 0.05,
                                    unit: ""
                                )
                                
                                IntSliderControl(
                                    label: "Highlight Recovery",
                                    value: $viewModel.highlightRecovery,
                                    range: 0...9,
                                    unit: ""
                                )
                                
                                SliderControl(
                                    label: "Shadow Recovery",
                                    value: $viewModel.shadowRecovery,
                                    range: 0.0...1.0,
                                    step: 0.01,
                                    unit: ""
                                )
                            }
                            
                            Divider()
                            
                            // Color Controls
                            Group {
                                Text("Color & White Balance")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Toggle("Use Camera WB", isOn: $viewModel.useCameraWB)
                                    Spacer()
                                }
                                
                                SliderControl(
                                    label: "Temperature",
                                    value: $viewModel.temperature,
                                    range: 2000.0...10000.0,
                                    step: 50.0,
                                    unit: "K",
                                    isDisabled: viewModel.useCameraWB
                                )
                                
                                SliderControl(
                                    label: "Tint",
                                    value: $viewModel.tint,
                                    range: -100.0...100.0,
                                    step: 1.0,
                                    unit: "",
                                    isDisabled: viewModel.useCameraWB
                                )
                                
                                SliderControl(
                                    label: "Saturation",
                                    value: $viewModel.saturation,
                                    range: 0.0...4.0,
                                    step: 0.05,
                                    unit: ""
                                )
                            }
                            
                            Divider()
                            
                            // Tone Controls
                            Group {
                                Text("Tone & Contrast")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                SliderControl(
                                    label: "Contrast",
                                    value: $viewModel.contrast,
                                    range: 0.0...4.0,
                                    step: 0.05,
                                    unit: ""
                                )
                                
                                SliderControl(
                                    label: "Gamma",
                                    value: $viewModel.gamma,
                                    range: 0.5...4.0,
                                    step: 0.05,
                                    unit: ""
                                )
                            }
                            
                            Divider()
                            
                            // Demosaic Settings
                            Group {
                                Text("Demosaic Algorithm")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Picker("Algorithm", selection: $viewModel.demosaicAlgorithm) {
                                    Text("Linear").tag(ImageProcessing.DemosaicAlgorithm.linear)
                                    Text("VNG").tag(ImageProcessing.DemosaicAlgorithm.vng)
                                    Text("PPG").tag(ImageProcessing.DemosaicAlgorithm.ppg)
                                    Text("AHD").tag(ImageProcessing.DemosaicAlgorithm.ahd)
                                    Text("DCB").tag(ImageProcessing.DemosaicAlgorithm.dcbInterpolation)
                                    Text("DCB + Correction").tag(ImageProcessing.DemosaicAlgorithm.dcbInterpAndCorrection)
                                    Text("LMMSE").tag(ImageProcessing.DemosaicAlgorithm.lmmse)
                                    Text("AMaZE").tag(ImageProcessing.DemosaicAlgorithm.amaze)
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .frame(minWidth: 300, maxWidth: 400)
            .padding()
            
            // Right Panel - Image Display
            VStack {
                ZStack {
                    // Background
                    Color.black
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    if viewModel.isProcessing {
                        // Processing Overlay
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("Processing RAW Image")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            if !viewModel.processingProgress.isEmpty {
                                Text(viewModel.processingProgress)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    } else if let cgImage = viewModel.cgImage {
                        // Processed Image
                        Image(nsImage: convert(cgImage: cgImage))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Initial State
                        VStack(spacing: 16) {
                            Image(systemName: "photo")
                                .font(.system(size: 64))
                                .foregroundColor(.white.opacity(0.6))
                            Text("Select a RAW image to begin")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.8))
                            Text("Supported formats: ARW, CR2, NEF, DNG, and more")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                // Metadata Panel
                if viewModel.cgImage != nil && !viewModel.isProcessing {
                    RawImageMetadataPanel(
                        cameraInfo: viewModel.cameraInfo,
                        imageInfo: viewModel.imageInfo
                    )
                }
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .navigationTitle("RAW Image Editor")
    }

    func convert(cgImage: CGImage) -> NSImage {
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        let nsImage = NSImage(size: size)
        nsImage.lockFocus()
        if let context = NSGraphicsContext.current?.cgContext {
            context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        }
        nsImage.unlockFocus()
        return nsImage
    }
}

// MARK: - Slider Control Component
struct SliderControl: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float
    let unit: String
    var isDisabled: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(isDisabled ? .secondary : .primary)
                Spacer()
                Text(String(format: "%.2f\(unit)", value))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            
            Slider(value: $value, in: range, step: step)
                .disabled(isDisabled)
        }
    }
}

// MARK: - Integer Slider Control Component
struct IntSliderControl: View {
    let label: String
    @Binding var value: Int32
    let range: ClosedRange<Int32>
    let unit: String
    var isDisabled: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(isDisabled ? .secondary : .primary)
                Spacer()
                Text("\(value)\(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int32($0.rounded()) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1.0
            )
            .disabled(isDisabled)
        }
    }
}

// MARK: - Metadata Panel Component
struct RawImageMetadataPanel: View {
    let cameraInfo: CameraInfo?
    let imageInfo: ImageInfo?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Image Information")
                .font(.headline)
            
            if let cameraInfo = cameraInfo {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Camera: \(cameraInfo.make) \(cameraInfo.model)")
                        .font(.caption)
                    if cameraInfo.isoSpeed > 0 {
                        Text("ISO: \(cameraInfo.isoSpeed)")
                            .font(.caption)
                    }
                    if cameraInfo.shutterSpeed > 0 {
                        Text("Shutter: 1/\(Int(1/cameraInfo.shutterSpeed))s")
                            .font(.caption)
                    }
                    if cameraInfo.aperture > 0 {
                        Text("Aperture: f/\(String(format: "%.1f", cameraInfo.aperture))")
                            .font(.caption)
                    }
                    if cameraInfo.focalLength > 0 {
                        Text("Focal Length: \(String(format: "%.1f", cameraInfo.focalLength))mm")
                            .font(.caption)
                    }
                }
            }
            
            if let imageInfo = imageInfo {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Image: \(imageInfo.width)×\(imageInfo.height)")
                        .font(.caption)
                    Text("RAW: \(imageInfo.rawWidth)×\(imageInfo.rawHeight)")
                        .font(.caption)
                    Text("Bit Depth: \(imageInfo.bitDepth)")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    RawImageEditView()
}