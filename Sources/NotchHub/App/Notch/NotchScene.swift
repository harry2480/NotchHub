/// Bundles the view models the notch UI renders, assembled by the Composition
/// Root. Keeps the window controller and views from taking a long parameter
/// list as features are added.
@MainActor
final class NotchScene {
    let notch: NotchViewModel
    let shelf: ShelfViewModel
    let calendar: CalendarViewModel
    let media: MediaViewModel
    let ai: AIMonitorViewModel
    let settings: SettingsStore

    init(
        notch: NotchViewModel,
        shelf: ShelfViewModel,
        calendar: CalendarViewModel,
        media: MediaViewModel,
        ai: AIMonitorViewModel,
        settings: SettingsStore
    ) {
        self.notch = notch
        self.shelf = shelf
        self.calendar = calendar
        self.media = media
        self.ai = ai
        self.settings = settings
    }
}
