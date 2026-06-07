/// A transient message shown after an action (要件定義.md §7.4 Toast / Undo).
struct ToastMessage: Equatable {
    let text: String
    /// Whether an Undo affordance should be offered alongside the toast.
    let isUndoable: Bool

    init(text: String, isUndoable: Bool = false) {
        self.text = text
        self.isUndoable = isUndoable
    }
}
