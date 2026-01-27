//
//  profile-selector-view.swift
//  ZairyuMate
//
//  Segmented control for switching between multiple profiles
//  Displays profile names with selection state
//

import SwiftUI

struct ProfileSelectorView<T: Hashable & Identifiable>: View {
    let profiles: [T]
    @Binding var selectedProfile: T?
    let displayName: (T) -> String

    var body: some View {
        if profiles.isEmpty {
            EmptyView()
        } else if profiles.count == 1 {
            // Single profile - just display name
            Text(displayName(profiles[0]))
                .font(.zmHeadline)
                .foregroundColor(.zmTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(Spacing.sm)
                .background(Color.zmBackground)
                .cornerRadius(CornerRadius.sm)
        } else {
            // Multiple profiles - show picker
            Picker("Profile", selection: $selectedProfile) {
                ForEach(profiles) { profile in
                    Text(displayName(profile))
                        .tag(profile as T?)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Profile selector")
            .accessibilityValue(selectedProfile.map(displayName) ?? "None selected")
        }
    }
}

// MARK: - Preview Models

#if DEBUG
struct Profile: Identifiable, Hashable {
    let id: String
    let name: String
}

#Preview("Multiple Profiles") {
    struct PreviewWrapper: View {
        @State private var selectedProfile: Profile?

        let profiles = [
            Profile(id: "1", name: "山田太郎"),
            Profile(id: "2", name: "田中花子"),
            Profile(id: "3", name: "佐藤次郎")
        ]

        var body: some View {
            VStack(spacing: Spacing.lg) {
                ProfileSelectorView(
                    profiles: profiles,
                    selectedProfile: $selectedProfile,
                    displayName: { $0.name }
                )
                .onAppear {
                    selectedProfile = profiles[0]
                }

                if let selectedProfile = selectedProfile {
                    Text("Selected: \(selectedProfile.name)")
                        .font(.zmBody)
                        .foregroundColor(.zmTextSecondary)
                }
            }
            .screenPadding()
            .background(Color.zmBackground)
        }
    }

    return PreviewWrapper()
}

#Preview("Two Profiles") {
    struct PreviewWrapper: View {
        @State private var selectedProfile: Profile?

        let profiles = [
            Profile(id: "1", name: "Self"),
            Profile(id: "2", name: "Spouse")
        ]

        var body: some View {
            VStack(spacing: Spacing.lg) {
                ProfileSelectorView(
                    profiles: profiles,
                    selectedProfile: $selectedProfile,
                    displayName: { $0.name }
                )
                .onAppear {
                    selectedProfile = profiles[0]
                }
            }
            .screenPadding()
            .background(Color.zmBackground)
        }
    }

    return PreviewWrapper()
}

#Preview("Single Profile") {
    struct PreviewWrapper: View {
        @State private var selectedProfile: Profile?

        let profiles = [
            Profile(id: "1", name: "山田太郎")
        ]

        var body: some View {
            VStack(spacing: Spacing.lg) {
                ProfileSelectorView(
                    profiles: profiles,
                    selectedProfile: $selectedProfile,
                    displayName: { $0.name }
                )
                .onAppear {
                    selectedProfile = profiles[0]
                }

                Text("Single profile - no selector needed")
                    .font(.zmCaption)
                    .foregroundColor(.zmTextSecondary)
            }
            .screenPadding()
            .background(Color.zmBackground)
        }
    }

    return PreviewWrapper()
}

#Preview("Dark Mode") {
    struct PreviewWrapper: View {
        @State private var selectedProfile: Profile?

        let profiles = [
            Profile(id: "1", name: "山田太郎"),
            Profile(id: "2", name: "田中花子")
        ]

        var body: some View {
            VStack(spacing: Spacing.lg) {
                ProfileSelectorView(
                    profiles: profiles,
                    selectedProfile: $selectedProfile,
                    displayName: { $0.name }
                )
                .onAppear {
                    selectedProfile = profiles[0]
                }
            }
            .screenPadding()
            .background(Color.zmBackground)
            .preferredColorScheme(.dark)
        }
    }

    return PreviewWrapper()
}
#endif
