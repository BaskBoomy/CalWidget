import WidgetKit
import SwiftUI
import EventKit
import AppIntents
import OSLog

private let logger = Logger(subsystem: "com.jack.calwidget.widget", category: "MonthWidget")

struct EventInfo: Hashable {
    let title: String
    let red: Double
    let green: Double
    let blue: Double
    let isAllDay: Bool

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }
}

struct MonthEntry: TimelineEntry {
    let date: Date
    let monthStart: Date
    let eventsByDay: [Int: [EventInfo]]
    let permissionGranted: Bool
}

struct MonthProvider: AppIntentTimelineProvider {
    typealias Entry = MonthEntry
    typealias Intent = SelectCalendarsIntent

    private let store = EKEventStore()

    func placeholder(in context: Context) -> MonthEntry {
        MonthEntry(
            date: Date(),
            monthStart: Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date(),
            eventsByDay: sampleEvents(),
            permissionGranted: true
        )
    }

    func snapshot(for configuration: SelectCalendarsIntent, in context: Context) async -> MonthEntry {
        buildEntry(configuration: configuration)
    }

    func timeline(for configuration: SelectCalendarsIntent, in context: Context) async -> Timeline<MonthEntry> {
        let entry = buildEntry(configuration: configuration)
        let nextReload = Date().addingTimeInterval(30 * 60)
        logger.info("timeline: granted=\(entry.permissionGranted), days=\(entry.eventsByDay.count), filterCount=\(configuration.calendars?.count ?? 0), nextReload=\(nextReload, privacy: .public)")
        return Timeline(entries: [entry], policy: .after(nextReload))
    }

    private func buildEntry(configuration: SelectCalendarsIntent) -> MonthEntry {
        let now = Date()
        let cal = Calendar.current
        let interval = cal.dateInterval(of: .month, for: now) ?? DateInterval(start: now, duration: 86400 * 30)

        let status = EKEventStore.authorizationStatus(for: .event)
        let granted = (status == .fullAccess || status == .authorized)

        guard granted else {
            return MonthEntry(date: now, monthStart: interval.start, eventsByDay: [:], permissionGranted: false)
        }

        let filteredCalendars = resolveCalendars(from: configuration)
        let predicate = store.predicateForEvents(withStart: interval.start, end: interval.end, calendars: filteredCalendars)
        let events = store.events(matching: predicate)

        var byDay: [Int: [EventInfo]] = [:]
        for ev in events {
            let info = makeInfo(from: ev)
            var cursor = max(ev.startDate, interval.start)
            let endBound = min(ev.endDate, interval.end)
            while cursor < endBound {
                let day = cal.component(.day, from: cursor)
                byDay[day, default: []].append(info)
                guard let next = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: cursor)) else { break }
                cursor = next
            }
        }

        return MonthEntry(date: now, monthStart: interval.start, eventsByDay: byDay, permissionGranted: true)
    }

    private func resolveCalendars(from configuration: SelectCalendarsIntent) -> [EKCalendar]? {
        guard let selected = configuration.calendars, !selected.isEmpty else { return nil }
        let selectedIDs = Set(selected.map(\.id))
        let allCalendars = store.calendars(for: .event)
        let matched = allCalendars.filter { selectedIDs.contains($0.calendarIdentifier) }
        return matched.isEmpty ? nil : matched
    }

    private func makeInfo(from ev: EKEvent) -> EventInfo {
        let cg = ev.calendar.cgColor ?? CGColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1)
        let comps = cg.components ?? [0.3, 0.5, 0.9, 1]
        let r = Double(comps.indices.contains(0) ? comps[0] : 0.3)
        let g = Double(comps.indices.contains(1) ? comps[1] : 0.5)
        let b = Double(comps.indices.contains(2) ? comps[2] : 0.9)
        return EventInfo(
            title: ev.title ?? "",
            red: r, green: g, blue: b,
            isAllDay: ev.isAllDay
        )
    }

    private func sampleEvents() -> [Int: [EventInfo]] {
        [
            3: [EventInfo(title: "팀 회의", red: 0.2, green: 0.5, blue: 0.9, isAllDay: false)],
            8: [
                EventInfo(title: "점심 약속", red: 0.9, green: 0.4, blue: 0.3, isAllDay: false),
                EventInfo(title: "운동", red: 0.3, green: 0.7, blue: 0.4, isAllDay: false)
            ],
            15: [EventInfo(title: "출장", red: 0.7, green: 0.3, blue: 0.7, isAllDay: true)],
            22: [
                EventInfo(title: "프로젝트 마감", red: 0.9, green: 0.3, blue: 0.3, isAllDay: false),
                EventInfo(title: "회식", red: 0.5, green: 0.5, blue: 0.9, isAllDay: false),
                EventInfo(title: "택배", red: 0.6, green: 0.6, blue: 0.4, isAllDay: false)
            ],
        ]
    }
}

struct MonthWidget: Widget {
    let kind = "MonthWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectCalendarsIntent.self,
            provider: MonthProvider()
        ) { entry in
            MonthWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("월간 캘린더")
        .description("이번 달 일정을 한눈에 보여줍니다. 위젯을 길게 눌러 표시할 캘린더를 선택할 수 있습니다.")
        .supportedFamilies([.systemLarge])
    }
}

#Preview(as: .systemLarge) {
    MonthWidget()
} timeline: {
    MonthEntry(
        date: Date(),
        monthStart: Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date(),
        eventsByDay: [
            3: [EventInfo(title: "팀 회의", red: 0.2, green: 0.5, blue: 0.9, isAllDay: false)],
            8: [
                EventInfo(title: "점심 약속", red: 0.9, green: 0.4, blue: 0.3, isAllDay: false),
                EventInfo(title: "운동", red: 0.3, green: 0.7, blue: 0.4, isAllDay: false)
            ],
            15: [EventInfo(title: "출장", red: 0.7, green: 0.3, blue: 0.7, isAllDay: true)],
            22: [
                EventInfo(title: "마감", red: 0.9, green: 0.3, blue: 0.3, isAllDay: false),
                EventInfo(title: "회식", red: 0.5, green: 0.5, blue: 0.9, isAllDay: false),
                EventInfo(title: "택배", red: 0.6, green: 0.6, blue: 0.4, isAllDay: false)
            ],
        ],
        permissionGranted: true
    )
}
