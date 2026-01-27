//
//  profile-list-view.swift
//  ZairyuMate
//
//  List view for displaying all profiles with CRUD operations
//  Supports swipe to delete, active profile indicator, and navigation
//

import SwiftUI

struct ProfileListView: View {
    @State private var viewModel = ProfileListViewModel()
    @State private var showingAddProfile = false
    @State private var selectedProfile: Profile?

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.hasProfiles {
                    List {
                        ForEach(viewModel.profiles) { profile in
                            NavigationLink {
                                ProfileDetailView(profile: profile)
                            } label: {
                                ProfileRowView(
                                    profile: profile,
                                    isActive: profile.isActive
                                )
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.deleteProfiles(at: IndexSet(integer: viewModel.profiles.firstIndex(of: profile) ?? 0))
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    selectedProfile = profile
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                if !profile.isActive {
                                    Button {
                                        Task {
                                            await viewModel.setActiveProfile(profile)
                                        }
                                    } label: {
                                        Label("Set Active", systemImage: "star.fill")
                                    }
                                    .tint(.green)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                } else if viewModel.isLoading {
                    ProgressView()
                } else {
                    // Empty state
                    VStack(spacing: Spacing.lg) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.zmTextSecondary)

                        Text("No Profiles")
                            .font(.zmTitle)
                            .foregroundColor(.zmTextPrimary)

                        Text("Add your profile to get started")
                            .font(.zmBody)
                            .foregroundColor(.zmTextSecondary)
                            .multilineTextAlignment(.center)

                        Button {
                            showingAddProfile = true
                        } label: {
                            Text("Add Profile")
                                .font(.zmHeadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, Spacing.xl)
                                .padding(.vertical, Spacing.md)
                                .background(Color.zmPrimary)
                                .cornerRadius(CornerRadius.button)
                        }
                    }
                    .padding(Spacing.xl)
                }
            }
            .navigationTitle("Profiles")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddProfile = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProfile) {
                ProfileFormView()
                    .onDisappear {
                        Task {
                            await viewModel.loadProfiles()
                        }
                    }
            }
            .sheet(item: $selectedProfile) { profile in
                ProfileFormView(profile: profile)
                    .onDisappear {
                        Task {
                            await viewModel.loadProfiles()
                        }
                        selectedProfile = nil
                    }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .overlay(alignment: .bottom) {
                if viewModel.showingUndoAlert {
                    UndoDeleteAlert(
                        profileName: viewModel.deletedProfile?.displayName ?? "",
                        onUndo: {
                            viewModel.undoDelete()
                        }
                    )
                    .padding(.bottom, Spacing.md)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .task {
                await viewModel.loadProfiles()
            }
        }
    }
}

// MARK: - Undo Delete Alert

struct UndoDeleteAlert: View {
    let profileName: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text("\(profileName) deleted")
                .font(.zmBody)
                .foregroundColor(.white)

            Spacer()

            Button {
                onUndo()
            } label: {
                Text("Undo")
                    .font(.zmHeadline)
                    .foregroundColor(.zmPrimary)
            }
        }
        .padding(Spacing.md)
        .background(Color.black.opacity(0.9))
        .cornerRadius(CornerRadius.md)
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding(.horizontal, Spacing.screenHorizontal)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("With Profiles") {
    ProfileListView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}

#Preview("Empty State") {
    ProfileListView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}

#Preview("Dark Mode") {
    ProfileListView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
        .preferredColorScheme(.dark)
}
#endif
