//
//  nfc-scanning-animation-view.swift
//  ZairyuMate
//
//  Animated view for NFC scanning state
//  Shows pulse animation and guidance
//

import SwiftUI

struct NFCScanningAnimationView: View {
    let onCancel: () -> Void

    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Animated NFC icon
            ZStack {
                // Pulse rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(Color.zmPrimary.opacity(0.3), lineWidth: 2)
                        .frame(width: 120 + CGFloat(index * 40), height: 120 + CGFloat(index * 40))
                        .scaleEffect(isAnimating ? 1.5 : 1.0)
                        .opacity(isAnimating ? 0 : 0.5)
                        .animation(
                            .easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.3),
                            value: isAnimating
                        )
                }

                // Center icon
                ZStack {
                    Circle()
                        .fill(Color.zmPrimary.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: "wave.3.right")
                        .font(.system(size: 50))
                        .foregroundColor(.zmPrimary)
                }
            }

            // Status text
            VStack(spacing: Spacing.sm) {
                Text("Scanning...")
                    .font(.zmTitle2)
                    .foregroundColor(.zmTextPrimary)

                Text("Hold your iPhone near the card")
                    .font(.zmBody)
                    .foregroundColor(.zmTextSecondary)
            }

            // Visual card position guide
            VStack(spacing: Spacing.xs) {
                Image(systemName: "iphone")
                    .font(.system(size: 60))
                    .foregroundColor(.zmTextTertiary)

                Image(systemName: "arrow.down")
                    .font(.system(size: 24))
                    .foregroundColor(.zmTextTertiary)
                    .opacity(isAnimating ? 1 : 0.3)
                    .animation(.easeInOut(duration: 0.8).repeatForever(), value: isAnimating)

                Image(systemName: "creditcard.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.zmTextTertiary)
            }

            Spacer()

            // Cancel button
            Button {
                onCancel()
            } label: {
                Text("Cancel")
                    .font(.zmBody)
                    .foregroundColor(.zmPrimary)
            }
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.zmBackground)
        .onAppear {
            isAnimating = true
        }
    }
}
