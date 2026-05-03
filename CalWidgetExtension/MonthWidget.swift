import WidgetKit
import SwiftUI
import EventKit

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

struct MonthProvider: TimelineProvider {
    private let store = EKEventStore()

    func placeholder(in context: Context) -> MonthEntry {
        MonthEntry(
            date: Date(),
            monthStart: Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date(),
            eventsByDay: sampleEvents(),
            permissionGranted: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthEntry) -> Void) {
        completion(buildEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthEntry>) -> Void) {
        let entry = buildEntry()
        let nextMidnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(60 * 60 * 24))
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func buildEntry() -> MonthEntry {
        let now = Date()
        let cal = Calendar.current
        let interval = cal.dateInterval(of: .month, for: now) ?? DateInterval(start: now, duration: 86400 * 30)

        let status = EKEventStore.authorizationStatus(for: .event)
        let granted = (status == .fullAccess || status == .authorized)

        guard granted else {
            return MonthEntry(date: now, monthStart: interval.start, eventsByDay: [:], permissionGranted: false)
        }

        let predicate = store.predicateForEvents(withStart: interval.start, end: interval.end, calendars: nil)
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
        StaticConfiguration(kind: kind, provider: MonthProvider()) { entry in
            MonthWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("월간 캘린더")
        .description("이번 달 일정을 한눈에 보여줍니다.")
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
            22: [
                EventInfo(title: "마감", red: 0.9, green: 0.3, blue: 0.3, isAllDay: false),
                EventInfo(title: "회식", red: 0.5, green: 0.5, blue: 0.9, isAllDay: false),
                EventInfo(title: "택배", red: 0.6, green: 0.6, blue: 0.4, isAllDay: false)
            ],
        ],
        permissionGranted: true
    )
}
