//
//  ViewModel.swift
//  RawSwift-example
//
//  Created by NakaokaRei on 2024/03/25.
//

import Foundation
import AppKit

@MainActor
class ViewModel: ObservableObject {
    var selectedRawImage: URL?

    func selectRawImage() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.allowedContentTypes = [.rawImage]
        openPanel.begin { response in
            if response == .OK {
                self.selectedRawImage = openPanel.url
                print(self.selectedRawImage)
            }
        }
    }
}
