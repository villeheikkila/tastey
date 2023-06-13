extension Array where Element: Equatable {
    mutating func remove(object: Element) {
        guard let index = firstIndex(of: object) else { return }
        remove(at: index)
    }
}

extension Array where Element: Equatable {
    mutating func replace(_ element: Element, with new: Element) {
        if let toReplace = firstIndex(where: { $0 == element }) {
            self[toReplace] = new
        }
    }
}

extension Array {
    func unique(selector: (Element, Element) -> Bool) -> [Element] {
        reduce([Element]()) { result, element in
            if let last = result.last {
                return selector(last, element) ? result : result + [element]
            } else {
                return [element]
            }
        }
    }
}

extension [String] {
    func joinComma() -> String {
        joined(separator: ", ")
    }
}

extension Array {
    func joinOptionalSpace<T>() -> String where T: ExpressibleByStringLiteral, Element == T? {
        compactMap { $0 as? String }.joined(separator: " ")
    }
}
