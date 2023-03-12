import SwiftUI

struct CategoryNameView: View {
  let category: Category

  var body: some View {
    Text(category.label)
      .font(.caption).bold()
  }
}

struct CategoryNameView_Previews: PreviewProvider {
  static var previews: some View {
    CategoryNameView(category: Category(id: 0, name: "beverage"))
  }
}
