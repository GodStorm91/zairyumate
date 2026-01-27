//
//  countdown-ring-view.swift
//  ZairyuMate
//
//  Activity ring style countdown display showing days remaining
//  Color changes based on urgency: green > 90 days, yellow > 30, red < 30
//

import SwiftUI

struct CountdownRingView: View {
    let daysRemaining: Int
    let totalDays: Int
    @State private var animatedProgress: Double = 0

    private var progress: Double {
        min(Double(daysRemaining) / Double(totalDays), 1.0)
    }

    private var ringColor: Color {
        if daysRemaining > 90 { return .green }
        if daysRemaining > 30 { return .yellow }
        return .red
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(lineWidth: 12)
                .opacity(0.2)
                .foregroundColor(ringColor)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    style: StrokeStyle(
                        lineWidth: 12,
                        lineCap: .round
                    )
                )
                .foregroundColor(ringColor)
                .rotationEffect(.degrees(-90))

            // Center text
            VStack(spacing: 0) {
                Text("\(daysRemaining)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.zmTextPrimary)

                Text("days")
                    .font(.zmCaption2)
                    .foregroundColor(.zmTextSecondary)
            }
        }
        .frame(width: 100, height: 100)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(daysRemaining) days remaining out of \(totalDays)")
        .accessibilityValue(urgencyDescription)
    }

    private var urgencyDescription: String {
        if daysRemaining > 90 { return "Good status" }
        if daysRemaining > 30 { return "Warning, renewal needed soon" }
        return "Urgent, renewal needed immediately"
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Healthy Status") {
    VStack(spacing: Spacing.xl) {
        Text("More than 90 days")
            .zmHeadlineStyle()

        CountdownRingView(daysRemaining: 180, totalDays: 365)
    }
    .screenPadding()
    .background(Color.zmBackground)
}

#Preview("Warning Status") {
    VStack(spacing: Spacing.xl) {
        Text("30-90 days")
            .zmHeadlineStyle()

        CountdownRingView(daysRemaining: 60, totalDays: 365)
    }
    .screenPadding()
    .background(Color.zmBackground)
}

#Preview("Urgent Status") {
    VStack(spacing: Spacing.xl) {
        Text("Less than 30 days")
            .zmHeadlineStyle()

        CountdownRingView(daysRemaining: 15, totalDays: 365)
    }
    .screenPadding()
    .background(Color.zmBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: Spacing.xl) {
        CountdownRingView(daysRemaining: 180, totalDays: 365)
        CountdownRingView(daysRemaining: 60, totalDays: 365)
        CountdownRingView(daysRemaining: 15, totalDays: 365)
    }
    .screenPadding()
    .background(Color.zmBackground)
    .preferredColorScheme(.dark)
}
#endif
