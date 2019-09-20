import Foundation

extension Array {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    /// From https://stackoverflow.com/questions/25329186/safe-bounds-checked-array-lookup-in-swift-through-optional-bindings
    subscript (safe index: Index) -> Element? {
        get {
            return indices.contains(index) ? self[index] : nil
        }
        set(newValue) {
            guard let val = newValue else {
                return
            }
            if indices.contains(index) {
                self[index] = val
            } else {
                self.insert(val, at: index)
            }
        }
    }
}

extension Array where Element: Hashable {
    /// From https://stackoverflow.com/questions/25738817/removing-duplicate-elements-from-an-array-in-swift
    var uniques: Array {
        var buffer = Array()
        var added = Set<Element>()
        for elem in self {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }
}

