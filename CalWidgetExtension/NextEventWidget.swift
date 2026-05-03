import WidgetKit
import SwiftUI
import EventKit
import AppIntents
import OSLog

private let nextLogger = Logger(subsystem: "com.jack.calwidget.widget", category: "NextEventWidget")

struct NextEventInfo: Hashable {
    let title: String
    let start: Date
    let isAllDay: Bool
}

struct NextEventEntry: TimelineEntry {
    let date: Date
    let nextEvent: NextEventInfo?
    let todayRemaining: Int
    let permissionGranted: Bool
}

struct NextEventProvider: AppIntentTimelineProvider {
    typealias Entry = NextEventEntry
    typealias Intent = SelectCalendarsIntent

    private let store = EKEventStore()

    func placeholder(in context: Context) -> NextEventEntry {
        NextEventEntry(
            date: Date(),
            nextEvent: NextEventInfo(title: "팀 회의", start: Date().addingTimeInterval(3600), isAllDay: false),
            todayRemaining: 3,
            permissionGranted: true
        )
    }

    func snapshot(for configuration: SelectCalendarsIntent, in context: Context) async -> NextEventEntry {
        buildEntry(configuration: configuration)
    }

    func timeline(for configuration: SelectCalendarsIntent, in context: Context) async -> Timeline<NextEventEntry> {
        let entry = buildEntry(configuration: configuration)
        let nextReload = computeNextReload(after: entry)
        nextLogger.info("timeline: hasNext=\(entry.nextEvent != nil), todayRemaining=\(entry.todayRemaining), nextReload=\(nextReload, privacy: .public)")
        return Timeline(entries: [entry], policy: .after(nextReload))
    }

    private func computeNextReload(after entry: NextEventEntry) -> Date {
        let halfHour = Date().addingTimeInterval(30 * 60)
        guard let start = entry.nextEvent?.start else { return halfHour }
        let justAfter = start.addingTimeInterval(60)
        return min(halfHour, justAfter)
    }

    private func buildEntry(configuration: SelectCalendarsIntent) -> NextEventEntry {
        let now = Date()
        let cal = Calendar.current

        let status = EKEventStore.authorizationStatus(for: .event)
        let granted = (status == .fullAccess || status == .authorized)

        guard granted else {
            return NextEventEntry(date: now, nextEvent: nil, todayRemaining: 0, permissionGranted: false)
        }

        let calendars = resolveCalendars(from: configuration)

        let upcomingEnd = now.addingTimeInterval(48 * 3600)
        let upcomingPred = store.predicateForEvents(withStart: now, end: upcomingEnd, calendars: calendars)
        let upcoming = store.events(matching: upcomingPred)
            .filter { !$0.isAllDay && $0.endDate > now }
            .sorted { $0.startDate < $1.startDate }

        let nextEvent = upcoming.first.map {
            NextEventInfo(title: $0.title ?? "", start: $0.startDate, isAllDay: $0.isAllDay)
        }

        let endOfDay = cal.startOfDay(for: now.addingTimeInterval(86400))
        let todayPred = store.predicateForEvents(withStart: now, end: endOfDay, calendars: calendars)
        let todayCount = store.events(matching: todayPred).count

        return NextEventEntry(
            date: now,
            nextEvent: nextEvent,
            todayRemaining: todayCount,
            permissionGranted: granted
        )
    }

    private func resolveCalendars(from configuration: SelectCalendarsIntent) -> [EKCalendar]? {
        guard let selected = configuration.calendars, !selected.isEmpty else { return nil }
        let selectedIDs = Set(selected.map(\.id))
        let allCalendars = store.calendars(for: .event)
        let matched = allCalendars.filter { selectedIDs.contains($0.calendarIdentifier) }
        return matched.isEmpty ? nil : matched
    }
}

struct NextEventWidget: Widget {
    let kind = "NextEventWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectCalendarsIntent.self,
            provider: NextEventProvider()
        ) { entry in
            NextEventView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("다음 일정")
        .description("다가오는 일정을 잠금화면이나 홈에 표시합니다.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

struct NextEventView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NextEventEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular: rectangular
            case .accessoryCircular: circular
            case .accessoryInline: inline
            default: rectangular
            }
        }
        .widgetURL(URL(string: "googlecalendar://"))
    }

    @ViewBuilder
    private var rectangular: some View {
        if let ev = entry.nextEvent {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11, weight: .semibold))
                    Text(timeString(ev.start))
                        .font(.caption.monospacedDigit())
                        .lineLimit(1)
                }
                .foregroundStyle(.secondary)
                Text(ev.title)
                    .font(.headline)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("일정 없음")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: -2) {
                Image(systemName: "calendar")
                    .font(.system(size: 9, weight: .semibold))
                Text("\(entry.todayRemaining)")
                    .font(.system(size: 22, weight: .bold))
                    .minimumScaleFactor(0.5)
            }
        }
    }

    @ViewBuilder
    private var inline: some View {
        if let ev = entry.nextEvent {
            Label("\(timeString(ev.start)) \(ev.title)", systemImage: "calendar")
        } else {
            Label("오늘 일정 없음", systemImage: "calendar")
        }
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        let isToday = Calendar.current.isDateInToday(date)
        f.dateFormat = isToday ? "a h:mm" : "M/d a h:mm"
        return f.string(from: date)
    }
}

#Preview(as: .accessoryRectangular) {
    NextEventWidget()
} timeline: {
    NextEventEntry(
        date: Date(),
        nextEvent: NextEventInfo(title: "디자인 리뷰", start: Date().addingTimeInterval(3600), isAllDay: false),
        todayRemaining: 4,
        permissionGranted: true
    )
}

#Preview(as: .accessoryCircular) {
    NextEventWidget()
} timeline: {
    NextEventEntry(
        date: Date(),
        nextEvent: nil,
        todayRemaining: 4,
        permissionGranted: true
    )
}
