//
//  card-flip-container.swift
//  ZairyuMate
//
//  3D flip animation container for card views
//  Provides smooth rotation animation between front/back views
//

import SwiftUI

struct CardFlipContainer<Front: View, Back: View>: View {
    let front: Front
    let back: Back
    @Binding var isFlipped: Bool

    init(
        isFlipped: Binding<Bool>,
        @ViewBuilder front: () -> Front,
        @ViewBuilder back: () -> Back
    ) {
        self._isFlipped = isFlipped
        self.front = front()
        self.back = back()
    }

    var body: some View {
        ZStack {
            front
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )

            back
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isFlipped)
        .onTapGesture {
            isFlipped.toggle()
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(isFlipped ? "Showing card back, tap to flip" : "Showing card front, tap to flip")
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    struct PreviewWrapper: View {
        @State private var isFlipped = false

        var body: some View {
            VStack(spacing: Spacing.lg) {
                CardFlipContainer(isFlipped: $isFlipped) {
                    ZairyuCardView(
                        name: "山田太郎",
                        cardNumber: "1234567890123456",
                        visaType: "就労",
                        expiryDate: Date().addingTimeInterval(365 * 24 * 60 * 60)
                    )
                } back: {
                    ZStack {
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .fill(Color.zmTextSecondary)

                        VStack(spacing: Spacing.sm) {
                            Text("Card Back")
                                .font(.zmTitle2)
                            Text("Tap to flip")
                                .font(.zmCaption)
                        }
                        .foregroundColor(.white)
                    }
                    .frame(height: 200)
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                }

                Button("Toggle Flip") {
                    isFlipped.toggle()
                }
                .buttonStyle(.bordered)
            }
            .screenPadding()
            .background(Color.zmBackground)
        }
    }

    return PreviewWrapper()
}
#endif
