import Charts
import PhotosUI
import SwiftUI

struct LocationScreenView: View {
  @StateObject private var viewModel: ViewModel
  @State private var scrollToTop: Int = 0
  @State private var resetView: Int = 0

  init(location: Location) {
    _viewModel = StateObject(wrappedValue: ViewModel(location: location))
  }

  var body: some View {
    CheckInListView(fetcher: .location(viewModel.location), scrollToTop: $scrollToTop, resetView: $resetView) {
      if let summary = viewModel.summary, summary.averageRating != nil {
        Section {
          SummaryView(summary: summary)
        }
        .contextMenu {
          ShareLink("Share", item: NavigatablePath.profile(id: viewModel.location.id).url)
        }
      }
    }
    .navigationTitle(viewModel.location.name)
    .navigationBarTitleDisplayMode(.inline)
    .task {
      viewModel.getSummary()
    }
  }
}

extension LocationScreenView {
  @MainActor class ViewModel: ObservableObject {
    @Published var summary: Summary?
    let location: Location

    init(location: Location) {
      self.location = location
    }

    func getSummary() {
      Task {
        switch await repository.location.getSummaryById(id: location.id) {
        case let .success(summary):
          withAnimation {
            self.summary = summary
          }
        case let .failure(error):
          print(error)
        }
      }
    }
  }
}
