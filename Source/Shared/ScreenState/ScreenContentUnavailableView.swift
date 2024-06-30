import SwiftUI

struct ScreenContentUnavailableView: View {
    @State private var isTaskRunning = false

    let errors: [Error]
    var description: LocalizedStringKey?
    let action: () async -> Void

    var label: some View {
        if errors.isNetworkUnavailable {
            Label("screen.error.networkUnavailable", systemImage: "wifi.slash")
        } else {
            Label("screen.error.unexpectedError", systemImage: "exclamationmark.triangle")
        }
    }

    var descriptionText: Text? {
        if let description {
            Text(description)
        } else {
            nil
        }
    }

    var body: some View {
        ContentUnavailableView(label: { label }, description: { descriptionText }, actions: {
            Button("labels.tryAgain") {
                if !isTaskRunning {
                    isTaskRunning = true
                    Task {
                        await action()
                        isTaskRunning = false
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isTaskRunning)
        })
    }
}
