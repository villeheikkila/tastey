import SwiftUI

struct FlavorSheet: View {
    @Environment(AppDataManager.self) private var appDataManager
    @Environment(FeedbackManager.self) private var feedbackManager
    @Environment(\.dismiss) private var dismiss
    @Binding var pickedFlavors: [Flavor]
    @State private var searchTerm = ""

    private let maxFlavors = 4

    var body: some View {
        List {
            if !pickedFlavors.isEmpty {
                Section("Picked flavors") {
                    ForEach(pickedFlavors) { pickedFlavor in
                        Button(action: { toggleFlavor(pickedFlavor) }, label: {
                            HStack {
                                Text(pickedFlavor.name.capitalized)
                                Spacer()
                            }
                        })
                    }
                }
            }

            if !searchTerm.isEmpty, !filteredFlavors.contains(where: { flavor in !pickedFlavors.contains(flavor) }) {
                Section {
                    Text("No flavors found with the search term")
                }
            }

            Section {
                ForEach(filteredFlavors.filter { !pickedFlavors.contains($0) }) { flavor in
                    Button(action: { toggleFlavor(flavor) }, label: {
                        HStack {
                            Text(flavor.label)
                            Spacer()
                            if pickedFlavors.contains(flavor) {
                                Label("Picked flavor", systemSymbol: .checkmark)
                                    .labelStyle(.iconOnly)
                            }
                        }
                    })
                }
            } header: {
                if filteredFlavors.contains(where: { flavor in !pickedFlavors.contains(flavor) }) {
                    Text("Available flavors")
                }
            }
        }
        .searchable(text: $searchTerm)
        .navigationTitle("Flavors")
        .toolbar {
            toolbarContent
        }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("Done", action: { dismiss() })
                .bold()
        }
    }

    private var filteredFlavors: [Flavor] {
        if searchTerm.isEmpty {
            return appDataManager.flavors
        } else {
            return appDataManager.flavors.filter { $0.name.lowercased().contains(searchTerm.lowercased()) }
        }
    }

    private func toggleFlavor(_ flavor: Flavor) {
        if pickedFlavors.contains(flavor) {
            pickedFlavors.remove(object: flavor)
        } else if pickedFlavors.count < maxFlavors {
            pickedFlavors.append(flavor)
        } else {
            feedbackManager.toggle(.warning("You can only add \(maxFlavors) flavors"))
        }
    }
}