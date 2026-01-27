//
//  profile-detail-view.swift
//  ZairyuMate
//
//  Read-only detail view for profile information
//  Shows all profile fields in organized sections
//

import SwiftUI

struct ProfileDetailView: View {
    let profile: Profile
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.section) {
                // Header Card
                VStack(spacing: Spacing.md) {
                    // Profile indicator
                    if profile.isActive {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Active Profile")
                                .font(.zmCaption)
                                .foregroundColor(.zmTextSecondary)
                        }
                    }

                    // Name
                    Text(profile.fullDisplayName)
                        .font(.zmLargeTitle)
                        .foregroundColor(.zmTextPrimary)
                        .multilineTextAlignment(.center)

                    // Relationship
                    if let relationship = profile.relationship {
                        Text(relationship.capitalized)
                            .font(.zmSubheadline)
                            .foregroundColor(.zmTextSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.lg)
                .background(Color.zmBackground)
                .cornerRadius(CornerRadius.card)

                // Personal Information
                DetailSection(title: "Personal Information") {
                    if let dob = profile.dateOfBirth {
                        DetailRow(label: "Date of Birth", value: dob.displayFormatted)
                    }

                    if let age = profile.age {
                        DetailRow(label: "Age", value: "\(age) years old")
                    }

                    if let nationality = profile.nationality,
                       let country = Country.allCountries.first(where: { $0.code == nationality }) {
                        DetailRow(label: "Nationality", value: country.displayName)
                    }
                }

                // Address
                if let address = profile.address {
                    DetailSection(title: "Address") {
                        Text(address)
                            .font(.zmBody)
                            .foregroundColor(.zmTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Zairyu Card
                DetailSection(title: "Zairyu Card") {
                    if let cardNumber = profile.decryptedCardNumber {
                        DetailRow(label: "Card Number", value: cardNumber, isSecure: true)
                    }

                    if let expiry = profile.cardExpiry {
                        DetailRow(
                            label: "Expiry Date",
                            value: expiry.displayFormatted,
                            isWarning: profile.isExpiringSoon
                        )

                        if let days = profile.daysUntilExpiry {
                            if days < 0 {
                                DetailRow(
                                    label: "Status",
                                    value: "Expired \(abs(days)) days ago",
                                    isWarning: true
                                )
                            } else {
                                DetailRow(
                                    label: "Days Until Expiry",
                                    value: "\(days) days",
                                    isWarning: profile.isExpiringSoon
                                )
                            }
                        }
                    }

                    if let visaTypeStr = profile.visaType,
                       let visaType = VisaType.allCases.first(where: { $0.rawValue == visaTypeStr }) {
                        DetailRow(label: "Visa Type", value: visaType.localizedName)
                    }
                }

                // Passport (if available)
                if profile.decryptedPassportNumber != nil || profile.passportExpiry != nil {
                    DetailSection(title: "Passport") {
                        if let passportNumber = profile.decryptedPassportNumber {
                            DetailRow(label: "Passport Number", value: passportNumber, isSecure: true)
                        }

                        if let expiry = profile.passportExpiry {
                            DetailRow(label: "Expiry Date", value: expiry.displayFormatted)
                        }
                    }
                }

                // Metadata
                DetailSection(title: "Metadata") {
                    if let created = profile.createdAt {
                        DetailRow(label: "Created", value: created.displayFormatted)
                    }

                    if let updated = profile.updatedAt {
                        DetailRow(label: "Last Updated", value: updated.displayFormatted)
                    }
                }
            }
            .padding(Spacing.screenHorizontal)
        }
        .background(Color.zmBackground)
        .navigationTitle("Profile Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            ProfileFormView(profile: profile)
        }
    }
}

// MARK: - Detail Section

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(.zmHeadline)
                .foregroundColor(.zmTextSecondary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                content()
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    var isSecure: Bool = false
    var isWarning: Bool = false

    @State private var isRevealed = false

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.zmSubheadline)
                .foregroundColor(.zmTextSecondary)
                .frame(width: 120, alignment: .leading)

            if isSecure && !isRevealed {
                HStack(spacing: Spacing.xs) {
                    Text("••••••••")
                        .font(.zmBody)
                        .foregroundColor(.zmTextPrimary)

                    Button {
                        isRevealed = true
                    } label: {
                        Image(systemName: "eye")
                            .font(.zmCaption)
                            .foregroundColor(.zmPrimary)
                    }
                }
            } else {
                Text(value)
                    .font(.zmBody)
                    .foregroundColor(isWarning ? .orange : .zmTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Complete Profile") {
    NavigationStack {
        ProfileDetailView(profile: {
            let profile = Profile(context: PersistenceController.preview.viewContext)
            profile.id = UUID()
            profile.name = "山田太郎"
            profile.nameKatakana = "ヤマダ タロウ"
            profile.dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date())
            profile.nationality = "JPN"
            profile.relationship = "self"
            profile.address = "東京都渋谷区渋谷1-1-1 渋谷マンション101号室"
            profile.cardExpiry = Calendar.current.date(byAdding: .day, value: 60, to: Date())
            profile.visaType = VisaType.engineer.rawValue
            profile.passportExpiry = Calendar.current.date(byAdding: .year, value: 3, to: Date())
            profile.isActive = true
            profile.createdAt = Date()
            profile.updatedAt = Date()
            return profile
        }())
    }
}

#Preview("Expiring Soon") {
    NavigationStack {
        ProfileDetailView(profile: {
            let profile = Profile(context: PersistenceController.preview.viewContext)
            profile.id = UUID()
            profile.name = "Nguyen Van A"
            profile.relationship = "self"
            profile.nationality = "VNM"
            profile.address = "東京都新宿区西新宿2-2-2"
            profile.cardExpiry = Calendar.current.date(byAdding: .day, value: 30, to: Date())
            profile.visaType = VisaType.specifiedSkilled1.rawValue
            profile.isActive = false
            return profile
        }())
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        ProfileDetailView(profile: {
            let profile = Profile(context: PersistenceController.preview.viewContext)
            profile.id = UUID()
            profile.name = "John Smith"
            profile.relationship = "self"
            profile.nationality = "USA"
            profile.address = "東京都港区六本木6-6-6"
            profile.cardExpiry = Calendar.current.date(byAdding: .year, value: 2, to: Date())
            profile.visaType = VisaType.businessManager.rawValue
            profile.isActive = true
            return profile
        }())
    }
    .preferredColorScheme(.dark)
}
#endif
