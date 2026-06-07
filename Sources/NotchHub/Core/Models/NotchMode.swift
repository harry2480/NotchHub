/// The notch window's display mode (要件定義.md §5).
///
/// The notch is collapsed (assimilated) by default and only expands on the
/// explicit triggers in ``NotchTrigger`` — never on hover or proximity.
enum NotchMode: Equatable, CaseIterable {
    /// Assimilated into the notch; shows at most one ``MinimalStatus``.
    case collapsed
    /// Drag in progress near the notch; shows the 3 drop zones.
    case dragging
    /// Fully expanded content (tabs).
    case expanded
}
