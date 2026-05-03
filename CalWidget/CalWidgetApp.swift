import SwiftUI
import OSLog

let appLogger = Logger(subsystem: "com.jack.calwidget", category: "App")

@main
struct CalWidgetApp: App {
    @StateObject private var diag = Diagnostics.shared

    init() {
        appLogger.info("App init at \(Date(), privacy: .public)")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(diag)
                .onOpenURL { url in
                    appLogger.info("App.onOpenURL received: \(url.absoluteString, privacy: .public)")
                    diag.record(url: url)
                }
        }
    }
}

final class Diagnostics: ObservableObject {
    static let shared = Diagnostics()

    @Published var lastURL: String?
    @Published var lastAt: Date?

    private let urlKey = "diag_last_url"
    private let atKey = "diag_last_at"

    init() {
        lastURL = UserDefaults.standard.string(forKey: urlKey)
        lastAt = UserDefaults.standard.object(forKey: atKey) as? Date
    }

    func record(url: URL) {
        let s = url.absoluteString
        UserDefaults.standard.set(s, forKey: urlKey)
        UserDefaults.standard.set(Date(), forKey: atKey)
        DispatchQueue.main.async {
            self.lastURL = s
            self.lastAt = Date()
        }
    }
}
