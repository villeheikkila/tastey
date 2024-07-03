import Components
import MapKit
import Models
import OSLog
import Repositories
import SwiftUI

struct LocationAdminSheet: View {
    let logger = Logger(category: "LocationEditSheet")
    @Environment(\.dismiss) private var dismiss
    @Environment(Repository.self) private var repository
    @Environment(Router.self) private var router
    @State private var location: Location
    @State private var showDeleteConfirmation = false

    let onEdit: (_ location: Location) async -> Void
    let onDelete: (_ location: Location) async -> Void

    init(location: Location, onEdit: @escaping (_ location: Location) async -> Void, onDelete: @escaping (_ location: Location) async -> Void) {
        _location = State(initialValue: location)
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    var body: some View {
        Form {
            Section("location.admin.section.location") {
                HStack {
                    if let coordinate = location.location?.coordinate {
                        MapThumbnail(location: location, coordinate: coordinate, distance: nil)
                    }
                    VStack(alignment: .leading) {
                        Text(location.name)
                        if let title = location.title {
                            Text(title)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .openOnTap(.screen(.location(location)))
            }

            Section("location.admin.section.creator") {
                HStack {
                    if let createdBy = location.createdBy {
                        Avatar(profile: createdBy)
                    }
                    VStack(alignment: .leading) {
                        Text(location.createdBy?.preferredName ?? "-")
                        if let createdAt = location.createdAt {
                            Text(createdAt, format:
                                .dateTime
                                    .year()
                                    .month(.wide)
                                    .day())
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .contentShape(.rect)
                .ifLet(location.createdBy) { view, createdBy in
                    view.openOnTap(.screen(.profile(createdBy)))
                }
            }

            Section("location.admin.section.details") {
                VStack {
                    LabeledContent("labels.id", value: "\(location.id)")
                        .textSelection(.enabled)
                        .multilineTextAlignment(.trailing)
                    LabeledContent("location.mapKitIdentifier.label", value: "\(location.mapKitIdentifier ?? "-")")
                        .textSelection(.enabled)
                }
            }

            Section {
                RouterLink("location.admin.changeLocation.label", systemImage: "map.circle", open: .sheet(.locationSearch(initialLocation: location, initialSearchTerm: location.name, onSelect: { location in
                    Task {
                        await updateLocation(self.location.copyWith(mapKitIdentifier: location.mapKitIdentifier))
                    }
                })))
                RouterLink("location.admin.merge.label", systemImage: "arrow.triangle.merge", open: .sheet(.mergeLocationSheet(location: location, onMerge: { newLocation in
                    await onDelete(location)
                    withAnimation {
                        location = newLocation
                    }
                })))
            }

            Section {
                Button("labels.delete", systemImage: "trash", role: .destructive) {
                    showDeleteConfirmation = true
                }
                .tint(.red)
                .confirmationDialog("labels.delete", isPresented: $showDeleteConfirmation, presenting: location) { location in
                    ProgressButton("labels.delete", role: .destructive, action: {
                        await deleteLocation(location)
                    })
                }
            }
        }
        .navigationTitle("location.admin.location.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarDismissAction()
    }

    public func updateLocation(_ location: Location) async {
        switch await repository.location.update(request: .init(id: location.id, mapKitIdentifier: location.mapKitIdentifier)) {
        case let .success(location):
            withAnimation {
                self.location = location
            }
            await onEdit(location)
        case let .failure(error):
            guard !error.isCancelled else { return }
            logger.error("Failed to update location: '\(location.id)'. Error: \(error) (\(#file):\(#line))")
        }
    }

    private func deleteLocation(_ location: Location) async {
        switch await repository.location.delete(id: location.id) {
        case .success:
            await onDelete(location)
            dismiss()
        case let .failure(error):
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Failed to delete location. Error: \(error) (\(#file):\(#line))")
        }
    }
}