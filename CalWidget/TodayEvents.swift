import Foundation
import SwiftUI
import EventKit
import OSLog

private let todayLogger = Logger(subsystem: "com.jack.calwidget", category: "TodayEvents")

struct EventRow: Identifiable, Hashable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool
    let calendarTitle: String
    let red: Double
    let green: Double
    let blue: Double

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }
}

@MainActor
final class TodayEvents: ObservableObject {
    @Published var events: [EventRow] = []
    @Published var lastReloadAt: Date?

    private let store = EKEventStore()
    private var token: NSObjectProtocol?

    init() {
        token = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            self?.reload()
        }
    }

    deinit {
        if let token {
            NotificationCenter.default.removeObserver(token)
        }
    }

    func reload() {
        let status = EKEventStore.authorizationStatus(for: .event)
        let granted = status == .fullAccess || status == .authorized
        guard granted else {
            events = []
            return
        }

        let now = Date()
        let cal = Calendar.current
        let endRange = cal.date(byAdding: .day, value: 7, to: cal.startOfDay(for: now)) ?? now.addingTimeInterval(86400 * 7)

        let predicate = store.predicateForEvents(withStart: now, end: endRange, calendars: nil)
        let raw = store.events(matching: predicate)
            .filter { $0.endDate > now }
            .sorted { lhs, rhs in
                if lhs.startDate != rhs.startDate { return lhs.startDate < rhs.startDate }
                return (lhs.title ?? "") < (rhs.title ?? "")
            }
            .prefix(15)

        events = raw.map { ev in
            let cg = ev.calendar.cgColor ?? CGColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1)
            let comps = cg.components ?? [0.3, 0.5, 0.9, 1]
            return EventRow(
                id: ev.eventIdentifier ?? UUID().uuidString,
                title: ev.title ?? "(제목 없음)",
                start: ev.startDate,
                end: ev.endDate,
                isAllDay: ev.isAllDay,
                calendarTitle: ev.calendar.title,
                red: Double(comps.indices.contains(0) ? comps[0] : 0.3),
                green: Double(comps.indices.contains(1) ? comps[1] : 0.5),
                blue: Double(comps.indices.contains(2) ? comps[2] : 0.9)
            )
        }
        lastReloadAt = Date()
        todayLogger.info("TodayEvents reloaded: \(self.events.count) events")
    }
}
