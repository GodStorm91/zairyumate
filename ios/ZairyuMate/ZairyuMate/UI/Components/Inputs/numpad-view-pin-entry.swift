//
//  numpad-view-pin-entry.swift
//  ZairyuMate
//
//  Number pad component for PIN entry
//  3x4 grid with numbers 1-9, 0, and delete button
//

import SwiftUI

struct NumPadView: View {
    @Binding var pin: String
    var onComplete: () -> Void
    var maxLength: Int = 6

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.md), count: 3)
    private let buttonSize: CGFloat = 75
    private let numbers = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "delete"]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.md) {
            ForEach(numbers, id: \.self) { item in
                if item.isEmpty {
                    // Empty space
                    Color.clear
                        .frame(width: buttonSize, height: buttonSize)
                } else if item == "delete" {
                    // Delete button
                    Button(action: deleteDigit) {
                        Image(systemName: "delete.left.fill")
                            .font(.title2)
                            .foregroundColor(.zmTextPrimary)
                            .frame(width: buttonSize, height: buttonSize)
                            .background(Color.zmBackground)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Delete")
                } else {
                    // Number button
                    Button(action: { appendDigit(item) }) {
                        Text(item)
                            .font(.system(size: 28, weight: .regular))
                            .foregroundColor(.zmTextPrimary)
                            .frame(width: buttonSize, height: buttonSize)
                            .background(Color.zmBackground)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Digit \(item)")
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Actions

    private func appendDigit(_ digit: String) {
        guard pin.count < maxLength else { return }

        pin.append(digit)

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Check if complete
        if pin.count == maxLength {
            // Small delay before calling completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onComplete()
            }
        }
    }

    private func deleteDigit() {
        guard !pin.isEmpty else { return }

        pin.removeLast()

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Empty PIN") {
    @Previewable @State var pin = ""

    VStack(spacing: Spacing.xl) {
        // PIN dots display
        HStack(spacing: Spacing.md) {
            ForEach(0..<6) { index in
                Circle()
                    .fill(index < pin.count ? Color.zmPrimary : Color.gray.opacity(0.3))
                    .frame(width: 16, height: 16)
            }
        }

        NumPadView(pin: $pin, onComplete: {
            print("PIN complete: \(pin)")
        })
    }
    .padding()
    .background(Color.white)
}

#Preview("Partial PIN") {
    @Previewable @State var pin = "123"

    VStack(spacing: Spacing.xl) {
        // PIN dots display
        HStack(spacing: Spacing.md) {
            ForEach(0..<6) { index in
                Circle()
                    .fill(index < pin.count ? Color.zmPrimary : Color.gray.opacity(0.3))
                    .frame(width: 16, height: 16)
            }
        }

        NumPadView(pin: $pin, onComplete: {
            print("PIN complete: \(pin)")
        })
    }
    .padding()
    .background(Color.white)
}

#Preview("Dark Mode") {
    @Previewable @State var pin = "12"

    VStack(spacing: Spacing.xl) {
        HStack(spacing: Spacing.md) {
            ForEach(0..<6) { index in
                Circle()
                    .fill(index < pin.count ? Color.zmPrimary : Color.gray.opacity(0.3))
                    .frame(width: 16, height: 16)
            }
        }

        NumPadView(pin: $pin, onComplete: {
            print("PIN complete: \(pin)")
        })
    }
    .padding()
    .background(Color.zmBackground)
    .preferredColorScheme(.dark)
}
#endif
