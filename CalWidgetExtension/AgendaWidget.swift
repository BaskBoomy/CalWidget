import WidgetKit
import SwiftUI
import EventKit
import AppIntents
import OSLog

private let agendaLogger = Logger(subsystem: "com.jack.calwidget.widget", category: "AgendaWidget")

private let agendaDayCount = 5

struct AgendaEvent: Hashable {
    let title: String
    let start: Date
    let isAllDay: Bool
    let red: Double
    let green: Double
    let blue: Double

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }
}

struct DayAgenda: Hashable {
    let date: Date
    let events: [AgendaEvent]
    let isToday: Bool
}

struct AgendaEntry: TimelineEntry {
    let date: Date
    let days: [DayAgenda]
    let permissionGranted: Bool
}

struct AgendaProvider: AppIntentTimelineProvider {
    typealias Entry = AgendaEntry
    typealias Intent = SelectCalendarsIntent

    private let store = EKEventStore()

    func placeholder(in context: Context) -> AgendaEntry {
        AgendaEntry(date: Date(), days: sampleDays(), permissionGranted: true)
    }

    func snapshot(for configuration: SelectCalendarsIntent, in context: Context) async -> AgendaEntry {
        buildEntry(configuration: configuration)
    }

    func timeline(for configuration: SelectCalendarsIntent, in context: Context) async -> Timeline<AgendaEntry> {
        let entry = buildEntry(configuration: configuration)
        let nextReload = Date().addingTimeInterval(30 * 60)
        agendaLogger.info("timeline: days=\(entry.days.count), totalEvents=\(entry.days.reduce(0) { $0 + $1.events.count }), nextReload=\(nextReload, privacy: .public)")
        return Timeline(entries: [entry], policy: .after(nextReload))
    }

    private func buildEntry(configuration: SelectCalendarsIntent) -> AgendaEntry {
        let now = Date()
        let cal = Calendar.current

        let status = EKEventStore.authorizationStatus(for: .event)
        let granted = (status == .fullAccess || status == .authorized)
        guard granted else {
            return AgendaEntry(date: now, days: [], permissionGranted: false)
        }

        let calendars = resolveCalendars(from: configuration)
        let startOfToday = cal.startOfDay(for: now)
        guard let endRange = cal.date(byAdding: .day, value: agendaDayCount, to: startOfToday) else {
            return AgendaEntry(date: now, days: [], permissionGranted: true)
        }

        let predicate = store.predicateForEvents(withStart: startOfToday, end: endRange, calendars: calendars)
        let events = store.events(matching: predicate)

        var byDay: [Date: [AgendaEvent]] = [:]
        for ev in events {
            let info = AgendaEvent.from(ev)
            var cursor = max(ev.startDate, startOfToday)
            let endBound = min(ev.endDate, endRange)
            while cursor < endBound {
                let key = cal.startOfDay(for: cursor)
                byDay[key, default: []].append(info)
                guard let next = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: cursor)) else { break }
                cursor = next
            }
        }

        var days: [DayAgenda] = []
        for offset in 0..<agendaDayCount {
            guard let date = cal.date(byAdding: .day, value: offset, to: startOfToday) else { continue }
            let evs = (byDay[date] ?? []).sorted { lhs, rhs in
                if lhs.isAllDay != rhs.isAllDay { return lhs.isAllDay && !rhs.isAllDay }
                if lhs.start != rhs.start { return lhs.start < rhs.start }
                return lhs.title < rhs.title
            }
            days.append(DayAgenda(date: date, events: evs, isToday: offset == 0))
        }

        return AgendaEntry(date: now, days: days, permissionGranted: true)
    }

    private func resolveCalendars(from configuration: SelectCalendarsIntent) -> [EKCalendar]? {
        guard let selected = configuration.calendars, !selected.isEmpty else { return nil }
        let selectedIDs = Set(selected.map(\.id))
        let allCalendars = store.calendars(for: .event)
        let matched = allCalendars.filter { selectedIDs.contains($0.calendarIdentifier) }
        return matched.isEmpty ? nil : matched
    }

    private func sampleDays() -> [DayAgenda] {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: Date())
        return (0..<agendaDayCount).compactMap { offset in
            guard let date = cal.date(byAdding: .day, value: offset, to: startOfToday) else { return nil }
            let events: [AgendaEvent] = {
                switch offset {
                case 0: return [
                    AgendaEvent(title: "팀 회의", start: date.addingTimeInterval(9 * 3600), isAllDay: false, red: 0.2, green: 0.5, blue: 0.9),
                    AgendaEvent(title: "점심 약속", start: date.addingTimeInterval(12 * 3600), isAllDay: false, red: 0.9, green: 0.4, blue: 0.3)
                ]
                case 1: return [AgendaEvent(title: "출장", start: date, isAllDay: true, red: 0.7, green: 0.3, blue: 0.7)]
                case 3: return [AgendaEvent(title: "디자인 리뷰", start: date.addingTimeInterval(14 * 3600), isAllDay: false, red: 0.3, green: 0.7, blue: 0.4)]
                default: return []
                }
            }()
            return DayAgenda(date: date, events: events, isToday: offset == 0)
        }
    }
}

extension AgendaEvent {
    static func from(_ ev: EKEvent) -> AgendaEvent {
        let cg = ev.calendar.cgColor ?? CGColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1)
        let comps = cg.components ?? [0.3, 0.5, 0.9, 1]
        let r = Double(comps.indices.contains(0) ? comps[0] : 0.3)
        let g = Double(comps.indices.contains(1) ? comps[1] : 0.5)
        let b = Double(comps.indices.contains(2) ? comps[2] : 0.9)
        return AgendaEvent(
            title: ev.title ?? "",
            start: ev.startDate,
            isAllDay: ev.isAllDay,
            red: r, green: g, blue: b
        )
    }
}

struct AgendaWidget: Widget {
    let kind = "AgendaWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectCalendarsIntent.self,
            provider: AgendaProvider()
        ) { entry in
            AgendaView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("일정 목록")
        .description("앞으로 \(agendaDayCount)일의 일정을 시간순으로 보여줍니다.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct AgendaView: View {
    let entry: AgendaEntry

    var body: some View {
        if !entry.permissionGranted {
            permissionPrompt
        } else {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("다가오는 일정")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "calendar")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, 2)

            VStack(spacing: 4) {
                ForEach(entry.days, id: \.date) { day in
                    AgendaRow(day: day)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var permissionPrompt: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("캘린더 접근 권한 필요")
                .font(.callout.weight(.semibold))
            Text("앱에서 권한을 허용해 주세요")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct AgendaRow: View {
    let day: DayAgenda

    var body: some View {
        if let url = dayURL(day.date) {
            Link(destination: url) { rowBody }
        } else {
            rowBody
        }
    }

    private var rowBody: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            dayLabel
                .frame(width: 38, alignment: .leading)

            if day.events.isEmpty {
                Text("일정 없음")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else {
                HStack(spacing: 4) {
                    ForEach(Array(day.events.prefix(3).enumerated()), id: \.offset) { _, ev in
                        eventChip(ev)
                    }
                    if day.events.count > 3 {
                        Text("+\(day.events.count - 3)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: 22)
    }

    private var dayLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(weekdayText)
                .font(.system(size: 11, weight: day.isToday ? .bold : .medium))
                .foregroundStyle(day.isToday ? Color.red : .primary)
            Text("\(Calendar.current.component(.day, from: day.date))")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private func eventChip(_ ev: AgendaEvent) -> some View {
        if ev.isAllDay {
            Text(ev.title)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(ev.color)
                .foregroundStyle(.white)
                .clipShape(Capsule())
        } else {
            HStack(spacing: 3) {
                Circle().fill(ev.color).frame(width: 5, height: 5)
                Text(timeString(ev.start))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Text(ev.title)
                    .font(.system(size: 10))
                    .lineLimit(1)
            }
        }
    }

    private var weekdayText: String {
        if day.isToday { return "오늘" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "EEE"
        return f.string(from: day.date)
    }

    private func timeString(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "H:mm"
        return f.string(from: d)
    }

    private func dayURL(_ date: Date) -> URL? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyyMMdd"
        let yyyymmdd = f.string(from: date)
        return URL(string: "googlecalendar://?action=showRange&start=\(yyyymmdd)&end=\(yyyymmdd)")
    }
}

#Preview(as: .systemMedium) {
    AgendaWidget()
} timeline: {
    let cal = Calendar.current
    let start = cal.startOfDay(for: Date())
    AgendaEntry(
        date: Date(),
        days: (0..<5).map { offset in
            let date = cal.date(byAdding: .day, value: offset, to: start)!
            let events: [AgendaEvent] = offset == 0 ? [
                AgendaEvent(title: "팀 회의", start: date.addingTimeInterval(9 * 3600), isAllDay: false, red: 0.2, green: 0.5, blue: 0.9),
                AgendaEvent(title: "점심", start: date.addingTimeInterval(12 * 3600), isAllDay: false, red: 0.9, green: 0.4, blue: 0.3)
            ] : offset == 1 ? [
                AgendaEvent(title: "출장", start: date, isAllDay: true, red: 0.7, green: 0.3, blue: 0.7)
            ] : offset == 3 ? [
                AgendaEvent(title: "리뷰", start: date.addingTimeInterval(14 * 3600), isAllDay: false, red: 0.3, green: 0.7, blue: 0.4)
            ] : []
            return DayAgenda(date: date, events: events, isToday: offset == 0)
        },
        permissionGranted: true
    )
}
