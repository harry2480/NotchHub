/// The only permitted notch expansion triggers (要件定義.md §5.2, AGENTS.md
/// "ノッチ UI の鉄則"). Hover and cursor proximity are deliberately absent.
enum NotchTrigger: Equatable {
    /// A drag approached the top-centre of the screen.
    case dragApproach
    /// The user clicked the notch.
    case click
    /// An AI CLI raised an approval request.
    case aiApproval
}
