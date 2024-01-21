import Components
import EnvironmentModels
import Extensions
import Models
import OSLog
import Repositories
import SwiftUI

struct CheckInCommentRow: View {
    private let logger = Logger(category: "CheckInScreen")
    @Environment(Repository.self) private var repository
    @Environment(ProfileEnvironmentModel.self) private var profileEnvironmentModel
    @State private var sheet: Sheet?
    @State private var showDeleteCommentAsModeratorConfirmation = false
    @State private var deleteAsCheckInCommentAsModerator: CheckInComment? {
        didSet {
            if deleteAsCheckInCommentAsModerator != nil {
                showDeleteCommentAsModeratorConfirmation = true
            }
        }
    }

    let comment: CheckInComment
    @Binding var checkInComments: [CheckInComment]

    var body: some View {
        CheckInCommentView(comment: comment)
            .sheets(item: $sheet)
            .confirmationDialog(
                "Are you sure you want to delete comment as a moderator?",
                isPresented: $showDeleteCommentAsModeratorConfirmation,
                titleVisibility: .visible,
                presenting: deleteAsCheckInCommentAsModerator
            ) { presenting in
                ProgressButton(
                    "Delete comment from \(presenting.profile.preferredName)",
                    role: .destructive,
                    action: { await deleteCommentAsModerator(presenting) }
                )
            }
            .contextMenu {
                if comment.profile == profileEnvironmentModel.profile {
                    Button("Edit", systemImage: "pencil") {
                        sheet = .editComment(checkInComment: comment, checkInComments: $checkInComments)
                    }
                    ProgressButton("Delete", systemImage: "trash.fill", role: .destructive) {
                        await deleteComment(comment)
                    }
                } else {
                    ReportButton(sheet: $sheet, entity: .comment(comment))
                }
                Divider()
                if profileEnvironmentModel.hasRole(.moderator) {
                    Menu {
                        if profileEnvironmentModel.hasPermission(.canDeleteComments) {
                            Button("Delete as Moderator", systemImage: "trash.fill", role: .destructive) {
                                deleteAsCheckInCommentAsModerator = comment
                            }
                        }
                    } label: {
                        Label("Moderation", systemImage: "gear")
                            .labelStyle(.iconOnly)
                    }
                }
            }
    }

    func deleteComment(_ comment: CheckInComment) async {
        switch await repository.checkInComment.deleteById(id: comment.id) {
        case .success:
            withAnimation {
                checkInComments.remove(object: comment)
            }
        case let .failure(error):
            guard !error.isCancelled else { return }
            logger.error("Failed to delete comment '\(comment.id)'. Error: \(error) (\(#file):\(#line))")
        }
    }

    func deleteCommentAsModerator(_ comment: CheckInComment) async {
        switch await repository.checkInComment.deleteAsModerator(comment: comment) {
        case .success:
            withAnimation {
                checkInComments.remove(object: comment)
            }
        case let .failure(error):
            guard !error.isCancelled else { return }
            logger.error("Failed to delete comment as moderator'\(comment.id)'. Error: \(error) (\(#file):\(#line))")
        }
    }
}
