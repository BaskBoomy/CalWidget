import AppIntents
import EventKit

struct SelectCalendarsIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "캘린더 선택"
    static var description = IntentDescription("위젯에 표시할 캘린더를 선택하세요. 비워두면 모든 캘린더가 표시됩니다.")

    @Parameter(title: "표시할 캘린더")
    var calendars: [CalendarEntity]?

    init() {}

    init(calendars: [CalendarEntity]?) {
        self.calendars = calendars
    }
}

struct CalendarEntity: AppEntity {
    let id: String
    let title: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "캘린더")
    static var defaultQuery = CalendarQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct CalendarQuery: EntityQuery {
    func entities(for identifiers: [CalendarEntity.ID]) async throws -> [CalendarEntity] {
        let store = EKEventStore()
        return store.calendars(for: .event)
            .filter { identifiers.contains($0.calendarIdentifier) }
            .map { CalendarEntity(id: $0.calendarIdentifier, title: $0.title) }
    }

    func suggestedEntities() async throws -> [CalendarEntity] {
        let store = EKEventStore()
        return store.calendars(for: .event)
            .sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
            .map { CalendarEntity(id: $0.calendarIdentifier, title: $0.title) }
    }
}
