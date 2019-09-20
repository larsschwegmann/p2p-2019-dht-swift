import Foundation

extension Array {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
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
