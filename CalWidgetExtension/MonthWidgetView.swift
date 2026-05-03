import SwiftUI
import WidgetKit

struct DayCell {
    let day: Int?
    let date: Date?
    let isToday: Bool
    let inCurrentMonth: Bool
    let events: [EventInfo]
}

struct MonthWidgetView: View {
    let entry: MonthEntry

    var body: some View {
        if entry.permissionGranted {
            content
        } else {
            permissionPrompt
        }
    }

    private var content: some View {
        VStack(spacing: 4) {
            header
            weekdayRow
            grid
        }
    }

    private var header: some View {
        HStack {
            Text(monthTitle)
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            Text("\(totalEventCount)건")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private var weekdayRow: some View {
        HStack(spacing: 1) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { idx, symbol in
                Text(symbol)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(weekdayColor(for: idx))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        VStack(spacing: 1) {
            ForEach(weeks.indices, id: \.self) { wi in
                HStack(spacing: 1) {
                    ForEach(weeks[wi].indices, id: \.self) { di in
                        DayCellView(cell: weeks[wi][di])
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
    }

    private var permissionPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("캘린더 접근 권한 필요")
                .font(.headline)
            Text("CalWidget 앱을 열어 권한을 허용해 주세요.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월"
        return f.string(from: entry.monthStart)
    }

    private var totalEventCount: Int {
        entry.eventsByDay.values.reduce(0) { $0 + $1.count }
    }

    private var weekdaySymbols: [String] {
        let cal = Calendar.current
        let symbols = ["일", "월", "화", "수", "목", "금", "토"]
        let first = cal.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private func weekdayColor(for idx: Int) -> Color {
        let firstWeekday = Calendar.current.firstWeekday
        let actualWeekday = ((firstWeekday - 1 + idx) % 7) + 1
        if actualWeekday == 1 { return .red }
        if actualWeekday == 7 { return .blue }
        return .secondary
    }

    private var weeks: [[DayCell]] {
        let cal = Calendar.current
        let monthStart = entry.monthStart
        guard let range = cal.range(of: .day, in: .month, for: monthStart) else { return [] }

        let firstWeekday = cal.component(.weekday, from: monthStart)
        var leading = firstWeekday - cal.firstWeekday
        if leading < 0 { leading += 7 }

        let today = Date()
        let isCurrentMonth = cal.isDate(today, equalTo: monthStart, toGranularity: .month)
        let todayDay = cal.component(.day, from: today)

        var cells: [DayCell] = Array(
            repeating: DayCell(day: nil, date: nil, isToday: false, inCurrentMonth: false, events: []),
            count: leading
        )

        for d in range {
            var comps = cal.dateComponents([.year, .month], from: monthStart)
            comps.day = d
            cells.append(DayCell(
                day: d,
                date: cal.date(from: comps),
                isToday: isCurrentMonth && d == todayDay,
                inCurrentMonth: true,
                events: entry.eventsByDay[d] ?? []
            ))
        }

        while cells.count % 7 != 0 {
            cells.append(DayCell(day: nil, date: nil, isToday: false, inCurrentMonth: false, events: []))
        }

        return stride(from: 0, to: cells.count, by: 7).map {
            Array(cells[$0..<$0 + 7])
        }
    }
}

struct DayCellView: View {
    let cell: DayCell

    var body: some View {
        if let date = cell.date {
            Link(destination: Self.googleCalendarURL(for: date)) {
                cellBody
            }
        } else {
            cellBody
        }
    }

    private var cellBody: some View {
        VStack(alignment: .leading, spacing: 1) {
            dayNumber
            ForEach(Array(cell.events.prefix(2).enumerated()), id: \.offset) { _, ev in
                eventChip(ev)
            }
            if cell.events.count > 2 {
                Text("+\(cell.events.count - 2)")
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 2)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private static func googleCalendarURL(for date: Date) -> URL {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyyMMdd"
        let yyyymmdd = f.string(from: date)
        return URL(string: "googlecalendar://?action=showRange&start=\(yyyymmdd)&end=\(yyyymmdd)")!
    }

    @ViewBuilder
    private var dayNumber: some View {
        if let d = cell.day {
            Text("\(d)")
                .font(.system(size: 10, weight: cell.isToday ? .bold : .regular))
                .foregroundStyle(cell.isToday ? Color.white : .primary)
                .frame(width: 14, height: 14)
                .background(cell.isToday ? Color.red : Color.clear)
                .clipShape(Circle())
                .padding(.bottom, 1)
        } else {
            Color.clear.frame(height: 14)
        }
    }

    @ViewBuilder
    private func eventChip(_ ev: EventInfo) -> some View {
        if ev.isAllDay {
            Text(ev.title)
                .font(.system(size: 7, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ev.color)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 2))
        } else {
            HStack(spacing: 2) {
                Circle()
                    .fill(ev.color)
                    .frame(width: 4, height: 4)
                Text(ev.title)
                    .font(.system(size: 7, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var accessibilityDescription: String {
        guard let d = cell.day else { return "" }
        var parts: [String] = ["\(d)일"]
        if cell.isToday { parts.append("오늘") }
        if cell.events.isEmpty {
            parts.append("일정 없음")
        } else {
            parts.append("일정 \(cell.events.count)개")
            let titles = cell.events.map(\.title).joined(separator: ", ")
            parts.append(titles)
        }
        return parts.joined(separator: ", ")
    }
}
