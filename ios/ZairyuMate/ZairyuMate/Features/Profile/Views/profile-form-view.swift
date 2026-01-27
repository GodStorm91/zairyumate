//
//  profile-form-view.swift
//  ZairyuMate
//
//  Form view for creating and editing profiles
//  Organized into sections: Personal, Address, Zairyu Card, Passport
//

import SwiftUI

struct ProfileFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ProfileFormViewModel()

    var profile: Profile?

    var body: some View {
        NavigationStack {
            Form {
                // Personal Information Section
                Section("Personal Information") {
                    StyledTextField(
                        title: "Name (Romaji)",
                        text: $viewModel.name,
                        placeholder: "e.g., Yamada Taro",
                        isRequired: true,
                        errorMessage: viewModel.error(for: "name"),
                        keyboardType: .default
                    )

                    StyledTextField(
                        title: "Name (Katakana)",
                        text: $viewModel.nameKatakana,
                        placeholder: "e.g., ヤマダ タロウ",
                        errorMessage: viewModel.error(for: "nameKatakana"),
                        keyboardType: .default
                    )

                    DatePickerField(
                        title: "Date of Birth",
                        date: $viewModel.dateOfBirth,
                        isRequired: true,
                        displayedComponents: .date
                    )

                    DropdownPickerField(
                        title: "Nationality",
                        options: Country.allCountries,
                        selection: Binding(
                            get: { Country.allCountries.first { $0.code == viewModel.nationality } },
                            set: { viewModel.nationality = $0?.code ?? "VNM" }
                        ),
                        displayText: { $0.displayName },
                        isRequired: true
                    )

                    DropdownPickerField(
                        title: "Relationship",
                        options: [
                            RelationshipType(id: "self", name: "Self"),
                            RelationshipType(id: "spouse", name: "Spouse"),
                            RelationshipType(id: "child", name: "Child"),
                            RelationshipType(id: "dependent", name: "Dependent")
                        ],
                        selection: Binding(
                            get: {
                                let types = [
                                    RelationshipType(id: "self", name: "Self"),
                                    RelationshipType(id: "spouse", name: "Spouse"),
                                    RelationshipType(id: "child", name: "Child"),
                                    RelationshipType(id: "dependent", name: "Dependent")
                                ]
                                return types.first { $0.id == viewModel.relationship }
                            },
                            set: { viewModel.relationship = $0?.id ?? "self" }
                        ),
                        displayText: { $0.name },
                        isRequired: true
                    )
                }

                // Address Section
                Section("Address") {
                    StyledTextField(
                        title: "Japanese Address",
                        text: $viewModel.address,
                        placeholder: "東京都渋谷区...",
                        isRequired: true,
                        errorMessage: viewModel.error(for: "address"),
                        keyboardType: .default
                    )
                }

                // Zairyu Card Section
                Section("Zairyu Card") {
                    StyledTextField(
                        title: "Card Number",
                        text: $viewModel.cardNumber,
                        placeholder: "AB12345678CD",
                        isRequired: true,
                        errorMessage: viewModel.error(for: "cardNumber"),
                        keyboardType: .default
                    )
                    .onChange(of: viewModel.cardNumber) { _, _ in
                        viewModel.formatCardNumber()
                    }

                    DatePickerField(
                        title: "Expiry Date",
                        date: $viewModel.cardExpiry,
                        isRequired: true,
                        displayedComponents: .date
                    )

                    DropdownPickerField(
                        title: "Visa Type",
                        options: VisaType.allCases,
                        selection: Binding(
                            get: { viewModel.visaType },
                            set: { viewModel.visaType = $0 ?? .engineer }
                        ),
                        displayText: { $0.localizedName },
                        isRequired: true
                    )
                }

                // Passport Section (Optional)
                Section("Passport (Optional)") {
                    StyledTextField(
                        title: "Passport Number",
                        text: $viewModel.passportNumber,
                        placeholder: "AB1234567",
                        errorMessage: viewModel.error(for: "passportNumber"),
                        keyboardType: .default
                    )
                    .onChange(of: viewModel.passportNumber) { _, _ in
                        viewModel.formatPassportNumber()
                    }

                    DatePickerField(
                        title: "Expiry Date",
                        date: $viewModel.passportExpiry,
                        displayedComponents: .date
                    )
                }
            }
            .navigationTitle(viewModel.formTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.saveButtonTitle) {
                        Task {
                            do {
                                try await viewModel.save()
                                dismiss()
                            } catch {
                                // Error already handled in viewModel
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .disabled(viewModel.isLoading)
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                if let profile = profile {
                    viewModel.loadProfile(profile)
                }
            }
        }
    }
}

// MARK: - Helper Types

struct RelationshipType: Identifiable, Hashable {
    let id: String
    let name: String
}

// MARK: - Preview

#if DEBUG
#Preview("New Profile") {
    ProfileFormView()
}

#Preview("Edit Profile") {
    ProfileFormView(profile: {
        let profile = Profile(context: PersistenceController.preview.viewContext)
        profile.id = UUID()
        profile.name = "山田太郎"
        profile.nameKatakana = "ヤマダ タロウ"
        profile.dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date())
        profile.nationality = "JPN"
        profile.relationship = "self"
        profile.address = "東京都渋谷区渋谷1-1-1"
        profile.cardExpiry = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        profile.visaType = VisaType.engineer.rawValue
        return profile
    }())
}
#endif
