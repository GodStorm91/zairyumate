//
//  profile-row-view.swift
//  ZairyuMate
//
//  List row component for displaying profile summary
//  Shows name, visa type, expiry status, and active indicator
//

import SwiftUI

struct ProfileRowView: View {
    let profile: Profile
    let isActive: Bool

    private var daysUntilExpiry: Int? {
        profile.daysUntilExpiry
    }

    private var isExpiringSoon: Bool {
        profile.isExpiringSoon
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Active indicator
            if isActive {
                Circle()
                    .fill(Color.zmPrimary)
                    .frame(width: 8, height: 8)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 8, height: 8)
            }

            // Profile info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Name
                Text(profile.displayName)
                    .font(.zmHeadline)
                    .foregroundColor(.zmTextPrimary)

                // Relationship and visa type
                HStack(spacing: Spacing.xs) {
                    if let relationship = profile.relationship {
                        Text(relationship.capitalized)
                            .font(.zmCaption)
                            .foregroundColor(.zmTextSecondary)

                        Text("•")
                            .font(.zmCaption)
                            .foregroundColor(.zmTextSecondary)
                    }

                    if let visaTypeStr = profile.visaType,
                       let visaType = VisaType.allCases.first(where: { $0.rawValue == visaTypeStr }) {
                        Text(visaType.shortName)
                            .font(.zmCaption)
                            .foregroundColor(.zmTextSecondary)
                    }
                }

                // Expiry warning
                if let days = daysUntilExpiry {
                    HStack(spacing: 4) {
                        Image(systemName: isExpiringSoon ? "exclamationmark.triangle.fill" : "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(isExpiringSoon ? .red : .zmTextSecondary)

                        if days < 0 {
                            Text("Expired \(abs(days)) days ago")
                                .font(.zmCaption)
                                .foregroundColor(.red)
                        } else if days == 0 {
                            Text("Expires today")
                                .font(.zmCaption)
                                .foregroundColor(.red)
                        } else {
                            Text("Expires in \(days) days")
                                .font(.zmCaption)
                                .foregroundColor(isExpiringSoon ? .orange : .zmTextSecondary)
                        }
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.zmCaption)
                .foregroundColor(.zmTextSecondary)
        }
        .padding(.vertical, Spacing.sm)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Active Profile") {
    List {
        ProfileRowView(
            profile: {
                let profile = Profile(context: PersistenceController.preview.viewContext)
                profile.id = UUID()
                profile.name = "山田太郎"
                profile.relationship = "self"
                profile.visaType = VisaType.engineer.rawValue
                profile.cardExpiry = Calendar.current.date(byAdding: .day, value: 60, to: Date())
                profile.isActive = true
                return profile
            }(),
            isActive: true
        )
    }
    .listStyle(.plain)
}

#Preview("Expiring Soon") {
    List {
        ProfileRowView(
            profile: {
                let profile = Profile(context: PersistenceController.preview.viewContext)
                profile.id = UUID()
                profile.name = "Nguyen Van A"
                profile.relationship = "self"
                profile.visaType = VisaType.engineer.rawValue
                profile.cardExpiry = Calendar.current.date(byAdding: .day, value: 45, to: Date())
                profile.isActive = false
                return profile
            }(),
            isActive: false
        )
    }
    .listStyle(.plain)
}

#Preview("Multiple Profiles") {
    List {
        ProfileRowView(
            profile: {
                let profile = Profile(context: PersistenceController.preview.viewContext)
                profile.id = UUID()
                profile.name = "John Smith"
                profile.relationship = "self"
                profile.visaType = VisaType.permanentResident.rawValue
                profile.cardExpiry = Calendar.current.date(byAdding: .year, value: 5, to: Date())
                profile.isActive = true
                return profile
            }(),
            isActive: true
        )

        ProfileRowView(
            profile: {
                let profile = Profile(context: PersistenceController.preview.viewContext)
                profile.id = UUID()
                profile.name = "Jane Smith"
                profile.relationship = "spouse"
                profile.visaType = VisaType.dependant.rawValue
                profile.cardExpiry = Calendar.current.date(byAdding: .day, value: 30, to: Date())
                profile.isActive = false
                return profile
            }(),
            isActive: false
        )

        ProfileRowView(
            profile: {
                let profile = Profile(context: PersistenceController.preview.viewContext)
                profile.id = UUID()
                profile.name = "Tom Smith"
                profile.relationship = "child"
                profile.visaType = VisaType.dependant.rawValue
                profile.cardExpiry = Calendar.current.date(byAdding: .year, value: 1, to: Date())
                profile.isActive = false
                return profile
            }(),
            isActive: false
        )
    }
    .listStyle(.plain)
}
#endif
