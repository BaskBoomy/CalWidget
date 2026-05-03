import SwiftUI

struct EventListRow: View {
    let event: EventRow

    var body: some View {
        HStack(spacing: 12) {
            timeColumn
                .frame(width: 50)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(event.color)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.body)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                HStack(spacing: 6) {
                    Text(dayLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(event.calendarTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    @ViewBuilder
    private var timeColumn: some View {
        if event.isAllDay {
            Text("종일")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text(timeString(event.start))
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                Text(timeString(event.end))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var dayLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(event.start) { return "오늘" }
        if cal.isDateInTomorrow(event.start) { return "내일" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 EEE"
        return f.string(from: event.start)
    }

    private func timeString(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        return f.string(from: d)
    }

    private var accessibilityDescription: String {
        var parts: [String] = [dayLabel]
        if event.isAllDay {
            parts.append("종일")
        } else {
            let f = DateFormatter()
            f.locale = Locale(identifier: "ko_KR")
            f.timeStyle = .short
            parts.append("\(f.string(from: event.start))부터 \(f.string(from: event.end))까지")
        }
        parts.append(event.title)
        parts.append("캘린더: \(event.calendarTitle)")
        return parts.joined(separator: ", ")
    }
}
