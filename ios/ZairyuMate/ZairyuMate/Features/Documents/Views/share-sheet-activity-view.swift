//
//  share-sheet-activity-view.swift
//  ZairyuMate
//
//  UIViewControllerRepresentable wrapper for UIActivityViewController
//  Provides native iOS share sheet for PDF sharing
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {

    // MARK: - Properties

    let items: [Any]
    var applicationActivities: [UIActivity]? = nil
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: applicationActivities
        )

        controller.excludedActivityTypes = excludedActivityTypes

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Convenience Initializer

extension ShareSheet {
    /// Create share sheet for PDF file
    init(pdfURL: URL) {
        self.items = [pdfURL]
        self.applicationActivities = nil
        self.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks,
            .postToFacebook,
            .postToTwitter,
            .postToWeibo,
            .postToVimeo,
            .postToFlickr,
            .postToTencentWeibo
        ]
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    ShareSheet(items: ["Test share content"])
}
#endif
