//
//  form-selection-view.swift
//  ZairyuMate
//
//  View for selecting form type to fill
//  Displays available MOJ visa forms
//

import SwiftUI

struct FormSelectionView: View {

    // MARK: - Properties

    let profile: Profile

    // MARK: - Body

    var body: some View {
        List {
            Section {
                ForEach(FormType.allCases) { formType in
                    NavigationLink {
                        PDFPreviewView(profile: profile, formType: formType)
                    } label: {
                        FormRowView(formType: formType)
                    }
                }
            } header: {
                Text("Available Forms")
                    .font(.zmHeadline)
            } footer: {
                Text("Select a form to auto-fill with your profile data")
                    .font(.zmFootnote)
                    .foregroundColor(.zmTextSecondary)
            }

            Section {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("Profile Information", systemImage: "person.circle.fill")
                        .font(.zmHeadline)
                        .foregroundColor(.zmPrimary)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(profile.name)
                            .font(.zmBody)
                            .foregroundColor(.zmTextPrimary)

                        if let nationality = profile.nationality {
                            Text("Nationality: \(nationality)")
                                .font(.zmCallout)
                                .foregroundColor(.zmTextSecondary)
                        }

                        if let visaType = profile.visaType {
                            Text("Visa: \(visaType)")
                                .font(.zmCallout)
                                .foregroundColor(.zmTextSecondary)
                        }
                    }
                }
                .padding(.vertical, Spacing.sm)
            } header: {
                Text("Form Data Source")
                    .font(.zmHeadline)
            }
        }
        .navigationTitle("Select Form")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Form Row View

private struct FormRowView: View {
    let formType: FormType

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.zmPrimary.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: formType.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.zmPrimary)
            }

            // Content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(formType.shortName)
                    .font(.zmHeadline)
                    .foregroundColor(.zmTextPrimary)

                Text(formType.description)
                    .font(.zmCallout)
                    .foregroundColor(.zmTextSecondary)
                    .lineLimit(2)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.zmTextSecondary)
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        FormSelectionView(profile: PreviewData.sampleProfile)
    }
}

private enum PreviewData {
    static var sampleProfile: Profile {
        let context = PersistenceController.preview.container.viewContext
        let profile = Profile(context: context)
        profile.id = UUID()
        profile.name = "John Doe"
        profile.nationality = "USA"
        profile.visaType = "Engineer"
        return profile
    }
}
#endif
