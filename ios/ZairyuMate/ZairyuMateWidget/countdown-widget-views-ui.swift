//
//  countdown-widget-views-ui.swift
//  ZairyuMateWidget
//
//  Widget views for all supported sizes (small, medium, lock screen)
//  Displays visa expiry countdown with urgency-based color coding
//

import SwiftUI
import WidgetKit

/// Main widget configuration
struct CountdownWidget: Widget {
    let kind = "CountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountdownProvider()) { entry in
            CountdownWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Visa Countdown")
        .description("Days until your visa expires")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

/// Main widget view router based on widget family
struct CountdownWidgetView: View {
    let entry: CountdownEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryRectangular:
            LockScreenWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

/// Small widget (2x2) - Big number countdown
struct SmallWidgetView: View {
    let entry: CountdownEntry

    var urgencyColor: Color {
        switch entry.urgencyColor {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        default: return .green
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            // Days remaining - large number
            Text("\(entry.daysRemaining)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(urgencyColor)
                .minimumScaleFactor(0.5)

            // "days" label
            Text("days")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            // Divider
            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 12)

            // Label
            Text("Visa Expiry")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)
        }
        .padding(12)
    }
}

/// Medium widget (4x2) - Ring + Details
struct MediumWidgetView: View {
    let entry: CountdownEntry

    var urgencyColor: Color {
        switch entry.urgencyColor {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        default: return .green
        }
    }

    var progress: Double {
        // Assume 1 year max (365 days) for progress calculation
        let total = 365.0
        let remaining = Double(entry.daysRemaining)
        return min(1.0, remaining / total)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Left side: Circular progress ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(.secondary.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(urgencyColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                // Center number
                VStack(spacing: 2) {
                    Text("\(entry.daysRemaining)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(urgencyColor)
                    Text("days")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 8)

            // Right side: Profile details
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.profileName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(entry.visaType)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("Expires: \(entry.formattedExpiryDate)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
            .padding(.trailing, 12)

            Spacer()
        }
        .padding(.vertical, 12)
    }
}

/// Lock screen widget (accessory rectangular) - Compact format
struct LockScreenWidgetView: View {
    let entry: CountdownEntry

    var body: some View {
        HStack(spacing: 8) {
            // Days with "d" suffix
            Text("\(entry.daysRemaining)d")
                .font(.system(size: 16, weight: .bold, design: .rounded))

            // Separator
            Text("|")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            // Visa label
            Text("Visa")
                .font(.system(size: 14, weight: .medium))

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    CountdownWidget()
} timeline: {
    CountdownEntry.placeholder
    CountdownEntry(
        date: Date(),
        profileName: "Jane Smith",
        visaType: "Permanent Resident",
        expiryDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!,
        daysRemaining: 14
    )
}

#Preview(as: .systemMedium) {
    CountdownWidget()
} timeline: {
    CountdownEntry.placeholder
}

#Preview(as: .accessoryRectangular) {
    CountdownWidget()
} timeline: {
    CountdownEntry.placeholder
}
