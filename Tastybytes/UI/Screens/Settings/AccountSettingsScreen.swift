import EnvironmentModels
import Models
import OSLog
import PhotosUI
import Repositories
import SwiftUI

private let logger = Logger(category: "AccountSettingsScreen")

struct AccountSettingsScreen: View {
    @Environment(\.repository) private var repository
    @Environment(ProfileEnvironmentModel.self) private var profileEnvironmentModel
    @Environment(FeedbackEnvironmentModel.self) private var feedbackEnvironmentModel
    @State private var showDeleteConfirmation = false
    @State private var showEmailConfirmation = false
    @State private var showPasswordConfirmation = false
    @State private var showAccountDeleteScreen = false
    @State private var email = ""
    @State private var newPassword = "" {
        didSet {
            passwordCheck()
        }
    }

    @State private var newPasswordConfirmation = "" {
        didSet {
            passwordCheck()
        }
    }

    @State var csvExport: CSVFile? = nil {
        didSet {
            showingExporter.toggle()
        }
    }

    @State var showingExporter = false

    private func passwordCheck() {
        withAnimation {
            showPasswordConfirmation = newPassword == newPasswordConfirmation && newPassword.count >= 8
        }
    }

    var body: some View {
        @Bindable var profileEnvironmentModel = profileEnvironmentModel
        Form {
            emailSection
            updatePassword
            deleteAccount
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showAccountDeleteScreen, content: {
            AccountDeletedScreen()
        })
        .transaction { transaction in
            if showAccountDeleteScreen {
                transaction.disablesAnimations = true
            }
        }
        .onChange(of: profileEnvironmentModel.email) {
            withAnimation {
                showEmailConfirmation = email != profileEnvironmentModel.email
            }
        }
        .onAppear {
            email = profileEnvironmentModel.email
        }
        .fileExporter(isPresented: $showingExporter,
                      document: csvExport,
                      contentType: UTType.commaSeparatedText,
                      defaultFilename: "\(Config.appName.lowercased())_export_\(Date().customFormat(.fileNameSuffix)).csv")
        { result in
            switch result {
            case .success:
                feedbackEnvironmentModel.toggle(.success("Data was exported as CSV"))
            case .failure:
                feedbackEnvironmentModel.toggle(.error(.custom("Error occurred while trying to export data")))
            }
        }
        .confirmationDialog(
            "Are you sure you want to permanently delete your account? All data will be lost.",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            ProgressButton(
                "Delete Account",
                role: .destructive,
                action: {
                    await profileEnvironmentModel.deleteCurrentAccount(onAccountDeletion: {
                        showAccountDeleteScreen = true
                    })
                }
            )
        }
    }

    private var updatePassword: some View {
        Section {
            HStack {
                Image(systemSymbol: .key)
                    .accessibility(hidden: true)
                SecureField("New Password", text: $newPassword)
                    .textContentType(.newPassword)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            HStack {
                Image(systemSymbol: .key)
                    .accessibility(hidden: true)
                SecureField("Confirm New Password", text: $newPasswordConfirmation)
                    .textContentType(.newPassword)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            if showPasswordConfirmation {
                ProgressButton(
                    "Update password",
                    action: { await profileEnvironmentModel.updatePassword(newPassword: newPassword) }
                )
            }
        } header: {
            Text("Change password")
        } footer: {
            Text("Password must be at least 8 characters")
        }
        .headerProminence(.increased)
    }

    private var emailSection: some View {
        Section {
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if showEmailConfirmation {
                ProgressButton(
                    "Send Verification Link",
                    action: { await profileEnvironmentModel.sendEmailVerificationLink() }
                )
                .transition(.slide)
            }

        } header: {
            Text("Email")
        } footer: {
            Text("Email is only used for login and is not shown for other users.")
        }
        .headerProminence(.increased)
    }

    private var deleteAccount: some View {
        Section {
            Group {
                ProgressButton(
                    "Export CSV",
                    systemSymbol: .squareAndArrowUp,
                    action: { await exportData() }
                )
                Button(
                    "Delete Account",
                    systemSymbol: .personCropCircleBadgeMinus,
                    role: .destructive,
                    action: { showDeleteConfirmation = true }
                ).foregroundColor(.red)
            }.fontWeight(.medium)
        }
    }

    func exportData() async {
        switch await repository.profile.currentUserExport() {
        case let .success(csvText):
            csvExport = CSVFile(initialText: csvText)
            showingExporter = true
        case let .failure(error):
            guard !error.localizedDescription.contains("cancelled") else { return }
            feedbackEnvironmentModel.toggle(.error(.unexpected))
            logger.error("Failed to export check-in csv. Error: \(error) (\(#file):\(#line))")
        }
    }
}
