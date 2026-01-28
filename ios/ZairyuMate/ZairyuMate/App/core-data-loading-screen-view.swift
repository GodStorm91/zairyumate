//
//  core-data-loading-screen-view.swift
//  ZairyuMate
//
//  Loading screen displayed while Core Data store initializes
//

import SwiftUI
import UIKit

struct CoreDataLoadingScreenView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color(uiColor: UIColor.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // App logo or icon
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 2)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )

                VStack(spacing: 8) {
                    Text("Zairyu Mate")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                ProgressView()
                    .scaleEffect(1.2)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    CoreDataLoadingScreenView()
}
