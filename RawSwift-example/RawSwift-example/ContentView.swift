//
//  ContentView.swift
//  RawSwift-example
//
//  Created by NakaokaRei on 2024/03/25.
//

import SwiftUI

struct ContentView: View {

    @StateObject private var viewModel = ViewModel()

    var body: some View {
        VStack {
            Button("Select Raw Image") {
                viewModel.selectRawImage()
            }
            if let cgImage = viewModel.cgImage {
                Image(nsImage: convert(cgImage: cgImage))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 500, height: 500)
            }
        }
        .padding()
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

#Preview {
    ContentView()
}
