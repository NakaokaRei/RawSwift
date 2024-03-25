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
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
