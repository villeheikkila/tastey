import SwiftUI

struct CompanySheetView: View {
  @StateObject private var viewModel = ViewModel()
  @EnvironmentObject private var profileManager: ProfileManager
  @Environment(\.dismiss) private var dismiss
  @State private var companyName = ""

  let onSelect: (_ company: Company, _ createdNew: Bool) -> Void

  var body: some View {
    List {
      ForEach(viewModel.searchResults, id: \.id) { company in
        Button(action: {
          self.onSelect(company, false)
          dismiss()
        }) {
          Text(company.name)
        }
      }

      if profileManager.hasPermission(.canCreateCompanies) {
        switch viewModel.status {
        case .searched:
          Section {
            Button(action: {
              viewModel.createNew()
            }) {
              Text("Add")
            }
          } header: {
            Text("Didn't find the company you were looking for?")
          }.textCase(nil)
        case .add:
          Section {
            TextField("Name", text: $viewModel.companyName)
            Button("Create") {
              viewModel.createNewCompany(onSuccess: {
                company in self.onSelect(company, true)
                dismiss()
              })
            }
            .disabled(!validateStringLength(str: viewModel.companyName, type: .normal))
          } header: {
            Text("Add new company")
          }
        case .none:
          EmptyView()
        }
      }
    }
    .navigationTitle("Search companies")
    .navigationBarItems(trailing: Button(action: {
      dismiss()
    }) {
      Text("Cancel").bold()
    })
    .searchable(text: $viewModel.searchText)
    .onSubmit(of: .search) { viewModel.searchCompanies() }
  }
}

extension CompanySheetView {
  enum Status {
    case add
    case searched
  }

  @MainActor class ViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var searchResults = [Company]()
    @Published var status: Status?
    @Published var companyName = ""

    func createNew() {
      companyName = searchText
      status = Status.add
    }

    func searchCompanies() {
      Task {
        switch await repository.company.search(searchTerm: searchText) {
        case let .success(searchResults):
          self.searchResults = searchResults
          self.status = Status.searched
        case let .failure(error):
          print(error)
        }
      }
    }

    func createNewCompany(onSuccess: @escaping (_ company: Company) -> Void) {
      let newCompany = Company.NewRequest(name: companyName)
      Task {
        switch await repository.company.insert(newCompany: newCompany) {
        case let .success(newCompany):
          onSuccess(newCompany)
        case let .failure(error):
          print(error)
        }
      }
    }
  }
}