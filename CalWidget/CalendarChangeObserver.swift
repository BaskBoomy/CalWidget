import Foundation
import EventKit
import WidgetKit
import OSLog

private let observerLogger = Logger(subsystem: "com.jack.calwidget", category: "CalendarChangeObserver")

@MainActor
final class CalendarChangeObserver: ObservableObject {
    private let store = EKEventStore()
    private var token: NSObjectProtocol?

    init() {
        token = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { _ in
            observerLogger.info("EKEventStoreChanged → reloading widget timelines")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    deinit {
        if let token {
            NotificationCenter.default.removeObserver(token)
        }
    }
}
