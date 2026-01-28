//
//  home-upcoming-events-section-view.swift
//  ZairyuMate
//
//  Displays upcoming timeline events with dates and countdown
//  Shows next 5 events sorted by date
//

import SwiftUI

struct UpcomingEventsSectionView: View {

    // MARK: - Properties

    let events: [TimelineEvent]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Section Header
            HStack {
                Text("Upcoming Events")
                    .font(.zmTitle3)
                    .foregroundColor(.zmTextPrimary)

                Spacer()

                NavigationLink(destination: TimelinePlaceholderView()) {
                    Text("View All")
                        .font(.zmCallout)
                        .foregroundColor(.zmPrimary)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)

            // Events List
            VStack(spacing: Spacing.xs) {
                ForEach(events) { event in
                    EventRowView(event: event)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }
}

// MARK: - Event Row View

struct EventRowView: View {

    // MARK: - Properties

    let event: TimelineEvent

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Event Type Icon
            eventIcon
                .frame(width: 40)

            // Event Details
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(event.title ?? "Untitled Event")
                    .font(.zmBody)
                    .foregroundColor(.zmTextPrimary)
                    .lineLimit(2)

                Text(eventDateDescription)
                    .font(.zmCaption)
                    .foregroundColor(.zmTextSecondary)
            }

            Spacer()

            // Days Until
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(daysUntil)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(urgencyColor)

                Text("days")
                    .font(.zmCaption2)
                    .foregroundColor(.zmTextSecondary)
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(Color.white.opacity(0.05))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.title ?? "Event"), \(eventDateDescription)")
    }

    // MARK: - Computed Properties

    @ViewBuilder
    private var eventIcon: some View {
        let iconName: String
        let iconColor: Color

        switch event.eventType {
        case "reminder":
            iconName = "bell.fill"
            iconColor = .blue
        case "deadline":
            iconName = "exclamationmark.triangle.fill"
            iconColor = .orange
        case "milestone":
            iconName = "flag.fill"
            iconColor = .green
        default:
            iconName = "circle.fill"
            iconColor = .gray
        }

        return Image(systemName: iconName)
            .font(.system(size: 22))
            .foregroundColor(iconColor)
    }

    private var daysUntil: Int {
        guard let eventDate = event.eventDate else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: eventDate)
        return max(0, components.day ?? 0)
    }

    private var urgencyColor: Color {
        if daysUntil <= 7 {
            return .red
        } else if daysUntil <= 30 {
            return .orange
        } else {
            return .zmTextPrimary
        }
    }

    private var eventDateDescription: String {
        guard let eventDate = event.eventDate else { return "No date" }
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(eventDate)
        let isTomorrow = calendar.isDateInTomorrow(eventDate)

        if isToday {
            return "Today"
        } else if isTomorrow {
            return "Tomorrow"
        } else {
            return eventDate.displayFormatted
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Upcoming Events") {
    let context = PersistenceController.preview.viewContext
    let profile = Profile(context: context)
    profile.name = "山田太郎"

    // Create sample events
    let event1 = TimelineEvent(context: context)
    event1.title = "Submit visa renewal application"
    event1.eventDate = Calendar.current.date(byAdding: .day, value: 15, to: Date())!
    event1.eventType = "deadline"
    event1.profile = profile

    let event2 = TimelineEvent(context: context)
    event2.title = "Tax document preparation"
    event2.eventDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
    event2.eventType = "reminder"
    event2.profile = profile

    let event3 = TimelineEvent(context: context)
    event3.title = "Passport renewal due"
    event3.eventDate = Calendar.current.date(byAdding: .day, value: 60, to: Date())!
    event3.eventType = "milestone"
    event3.profile = profile

    return NavigationStack {
        ScrollView {
            UpcomingEventsSectionView(events: [event1, event2, event3])
        }
        .background(Color.zmBackground)
    }
}

#Preview("Single Event") {
    let context = PersistenceController.preview.viewContext
    let profile = Profile(context: context)
    profile.name = "田中花子"

    let event = TimelineEvent(context: context)
    event.title = "Visa expiry date"
    event.eventDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
    event.eventType = "deadline"
    event.profile = profile

    return NavigationStack {
        ScrollView {
            UpcomingEventsSectionView(events: [event])
        }
        .background(Color.zmBackground)
    }
}

#Preview("Dark Mode") {
    let context = PersistenceController.preview.viewContext
    let profile = Profile(context: context)
    profile.name = "佐藤次郎"

    let event1 = TimelineEvent(context: context)
    event1.title = "Start preparing documents"
    event1.eventDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    event1.eventType = "reminder"
    event1.profile = profile

    let event2 = TimelineEvent(context: context)
    event2.title = "Submit application"
    event2.eventDate = Calendar.current.date(byAdding: .day, value: 45, to: Date())!
    event2.eventType = "deadline"
    event2.profile = profile

    return NavigationStack {
        ScrollView {
            UpcomingEventsSectionView(events: [event1, event2])
        }
        .background(Color.zmBackground)
        .preferredColorScheme(.dark)
    }
}
#endif
