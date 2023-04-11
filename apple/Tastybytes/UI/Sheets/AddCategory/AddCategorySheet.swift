import SwiftUI

struct AddCategorySheet: View {
  @State private var newCategoryName = ""

  let onSubmit: (_ newCategoryName: String) -> Void

  var body: some View {
    DismissableSheet(title: "Add Category") { dismiss in
      Form {
        TextField("Name", text: $newCategoryName)
        Button(action: {
          onSubmit(newCategoryName)
          dismiss()
        }, label: {
          Text("Add")
        }).disabled(newCategoryName.isEmpty)
      }
    }
  }
}
