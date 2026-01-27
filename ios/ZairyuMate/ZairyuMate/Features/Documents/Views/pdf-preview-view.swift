//
//  pdf-preview-view.swift
//  ZairyuMate
//
//  View for previewing filled PDF forms
//  Supports export, share, and print to 7-Eleven
//

import SwiftUI
import PDFKit

struct PDFPreviewView: View {

    // MARK: - Properties

    let profile: Profile
    let formType: FormType

    @State private var viewModel: FormFillViewModel
    @State private var showShareSheet = false
    @State private var showErrorAlert = false

    // MARK: - Initialization

    init(profile: Profile, formType: FormType) {
        self.profile = profile
        self.formType = formType
        _viewModel = State(initialValue: FormFillViewModel(profile: profile, formType: formType))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if let document = viewModel.filledDocument {
                // PDF content
                PDFKitView(document: document)
                    .ignoresSafeArea(edges: .bottom)
            } else if viewModel.isLoading {
                // Loading state
                VStack(spacing: Spacing.lg) {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text("Generating PDF...")
                        .font(.zmHeadline)
                        .foregroundColor(.zmTextSecondary)
                }
            } else if viewModel.hasError {
                // Error state
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)

                    VStack(spacing: Spacing.sm) {
                        Text("Failed to Generate PDF")
                            .font(.zmHeadline)
                            .foregroundColor(.zmTextPrimary)

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.zmCallout)
                                .foregroundColor(.zmTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.xl)
                        }
                    }

                    Button {
                        Task {
                            await viewModel.generatePDF()
                        }
                    } label: {
                        Text("Retry")
                            .font(.zmHeadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.vertical, Spacing.md)
                            .background(Color.zmPrimary)
                            .cornerRadius(CornerRadius.button)
                    }
                }
            }
        }
        .navigationTitle(formType.shortName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if viewModel.filledDocument != nil {
                    Menu {
                        Button {
                            Task {
                                await viewModel.exportForSharing()
                                showShareSheet = true
                            }
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            Task {
                                await viewModel.saveToFiles()
                                if let url = viewModel.exportedURL {
                                    showShareSheet = true
                                }
                            }
                        } label: {
                            Label("Save to Files", systemImage: "folder")
                        }

                        Divider()

                        Button {
                            viewModel.openNetprint()
                        } label: {
                            Label("Print at 7-Eleven", systemImage: "printer")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.zmPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = viewModel.exportedURL {
                ShareSheet(pdfURL: url)
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            await viewModel.generatePDF()
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        PDFPreviewView(
            profile: PreviewData.sampleProfile,
            formType: .extensionForm
        )
    }
}

private enum PreviewData {
    static var sampleProfile: Profile {
        let context = PersistenceController.preview.container.viewContext
        let profile = Profile(context: context)
        profile.id = UUID()
        profile.name = "John Doe"
        profile.nameKatakana = "ジョン・ドウ"
        profile.dateOfBirth = Date()
        profile.nationality = "USA"
        profile.address = "Tokyo, Japan"
        profile.visaType = "Engineer"
        profile.decryptedCardNumber = "AB1234567"
        profile.cardExpiry = Date()
        profile.decryptedPassportNumber = "US123456789"
        profile.passportExpiry = Date()
        return profile
    }
}
#endif
