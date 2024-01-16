import Components
import EnvironmentModels
import Extensions
import Models
import OSLog
import Repositories
import SwiftUI

@MainActor
struct ActivityScreen: View {
    private let logger = Logger(category: "CheckInList")
    @Environment(Repository.self) private var repository
    @Environment(ProfileEnvironmentModel.self) private var profileEnvironmentModel
    @Environment(ImageUploadEnvironmentModel.self) private var imageUploadEnvironmentModel
    @State private var loadingCheckInsOnAppear: Task<Void, Error>?
    // Scroll position
    @Binding var scrollToTop: Int
    @State private var scrolledID: Int?
    // Feed state
    @State private var refreshId = 0
    @State private var resultId: Int?
    @State private var isRefreshing = false
    @State private var isLoading = false
    @State private var page = 0
    // Check-ins
    @State private var checkIns = [CheckIn]()
    @State private var showCheckInsFrom: CheckInSegment = .everyone
    @State private var currentShowCheckInsFrom: CheckInSegment = .everyone
    // Dialogs
    @State private var alertError: AlertError?
    @State private var errorContentUnavailable: AlertError?

    private let pageSize = 10

    var isContentUnavailable: Bool {
        refreshId == 1 && checkIns.isEmpty && !isLoading
    }

    var body: some View {
        @Bindable var imageUploadEnvironmentModel = imageUploadEnvironmentModel
        ScrollView {
            LazyVStack {
                CheckInListContent(checkIns: $checkIns, alertError: $alertError, loadedFrom: .activity(profileEnvironmentModel.profile), onLoadMore: {
                    onLoadMore()
                })
                ProgressView()
                    .frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .center)
                    .opacity(isLoading && !isRefreshing ? 1 : 0)
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $scrolledID)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .sensoryFeedback(.success, trigger: isRefreshing) { oldValue, newValue in
            oldValue && !newValue
        }
        .overlay {
            if errorContentUnavailable != nil {
                ContentUnavailableView {
                    Label("Feed couldn't be loaded", systemImage: "exclamationmark.triangle")
                } actions: {
                    Button("Reload") {
                        refreshId += 1
                    }
                }
            } else if isContentUnavailable {
                EmptyActivityFeed()
            } else {
                EmptyView()
            }
        }
        .alertError($alertError)
        .onChange(of: scrollToTop) {
            guard let first = checkIns.first else { return }
            withAnimation {
                scrolledID = first.id
            }
        }
        .task(id: refreshId) { [refreshId] in
            guard refreshId != resultId else {
                logger.info("Already loaded data with id: \(refreshId)")
                return
            }
            if refreshId == 0 {
                logger.info("Loading initial check-in feed data")
                await fetchFeedItems()
                resultId = refreshId
                return
            }
            logger.info("Refreshing check-in feed data with id: \(refreshId)")
            isRefreshing = true
            await fetchFeedItems(reset: true)
            isRefreshing = false
            resultId = refreshId
        }
        .task(id: showCheckInsFrom) { [showCheckInsFrom] in
            if showCheckInsFrom == currentShowCheckInsFrom {
                return
            }
            logger.info("Loading check-ins for scope: \(showCheckInsFrom.rawValue)")
            await fetchFeedItems(reset: true, onComplete: { @MainActor _ in
                currentShowCheckInsFrom = showCheckInsFrom
                logger.info("Loaded check-ins for scope: \(showCheckInsFrom.rawValue)")
            })
        }
        .onDisappear {
            loadingCheckInsOnAppear?.cancel()
        }
        #if !targetEnvironment(macCatalyst)
        .refreshable {
            refreshId += 1
        }
        #endif
        .onChange(of: imageUploadEnvironmentModel.uploadedImageForCheckIn) { _, newValue in
            if let updatedCheckIn = newValue {
                imageUploadEnvironmentModel.uploadedImageForCheckIn = nil
                if let index = checkIns.firstIndex(where: { $0.id == updatedCheckIn.id }) {
                    checkIns[index] = updatedCheckIn
                }
            }
        }
    }

    func onLoadMore() {
        guard loadingCheckInsOnAppear == nil else { return }
        logger.info("Loading more items invoked")
        loadingCheckInsOnAppear = Task {
            await fetchFeedItems()
            loadingCheckInsOnAppear = nil
        }
    }

    func fetchFeedItems(
        reset: Bool = false,
        onComplete: (@Sendable (_ checkIns: [CheckIn]) async -> Void)? = nil
    ) async {
        let (from, to) = getPagination(page: reset ? 0 : page, size: pageSize)
        isLoading = true
        errorContentUnavailable = nil
        switch await repository.checkIn.getActivityFeed(from: from, to: to) {
        case let .success(fetchedCheckIns):
            withAnimation {
                if reset {
                    checkIns = fetchedCheckIns
                } else {
                    checkIns.append(contentsOf: fetchedCheckIns)
                }
            }
            page += 1
            if let onComplete {
                await onComplete(checkIns)
            }
        case let .failure(error):
            guard !error.isCancelled else { return }
            let e = AlertError(title: "Error occured while trying to load check-ins")
            if checkIns.isEmpty {
                errorContentUnavailable = e
            } else {
                alertError = e
            }
            logger.error("Fetching check-ins failed. Error: \(error) (\(#file):\(#line))")
        }
        isLoading = false
    }
}
