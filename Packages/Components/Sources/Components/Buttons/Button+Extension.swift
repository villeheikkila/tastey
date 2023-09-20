import SwiftUI

public typealias ButtonLabelView = Label

public extension Button where Label == ButtonLabelView<Text, Image> {
    init(_ titleKey: LocalizedStringKey, systemImage: String, role: ButtonRole? = nil,
         action: @escaping () -> Void)
    {
        self.init(role: role, action: action, label: {
            ButtonLabelView(titleKey, systemImage: systemImage)
        })
    }
}