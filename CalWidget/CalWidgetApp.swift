import SwiftUI
import OSLog

let appLogger = Logger(subsystem: "com.jack.calwidget", category: "App")

private let externalSchemes: Set<String> = ["googlecalendar", "comgooglecalendar", "x-google-calendar"]

@main
struct CalWidgetApp: App {
    @StateObject private var calendarObserver = CalendarChangeObserver()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(calendarObserver)
                .onOpenURL { url in
                    redispatchIfExternal(url)
                }
        }
    }

    private func redispatchIfExternal(_ url: URL) {
        guard let scheme = url.scheme?.lowercased(),
              externalSchemes.contains(scheme) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            UIApplication.shared.open(url, options: [:]) { ok in
                appLogger.info("Redispatch \(url.absoluteString, privacy: .public) → success=\(ok)")
            }
        }
    }
}
