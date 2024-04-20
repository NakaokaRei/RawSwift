//
//  ViewModel.swift
//  RawSwift-example
//
//  Created by NakaokaRei on 2024/03/25.
//

import Foundation
import AppKit
import RawSwift

@MainActor
class ViewModel: ObservableObject {

    @Published var cgImage: CGImage?
    let fileHandling = FileHandling()

    func selectRawImage() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.allowedContentTypes = [.rawImage]
        openPanel.begin { response in
            if response == .OK {
                let rawData = FileHandling.initLibRawData()
                let _ = self.fileHandling.openFile(url: openPanel.url!, rawdata: rawData)
                self.cgImage = ImageProcessing.getImageFromData(rawData)
            }
        }
    }
}
