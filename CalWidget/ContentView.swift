import SwiftUI
import EventKit
import WidgetKit

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var todayEvents = TodayEvents()
    @State private var status: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    @State private var didRefresh = false

    private let store = EKEventStore()
    private let googleCalendarURL = URL(string: "googlecalendar://")!

    var body: some View {
        NavigationStack {
            List {
                heroSection
                quickActionsSection
                upcomingEventsSection
                permissionSection
                googleAccountSection
                widgetGuideSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(backgroundGradient)
            .navigationTitle("CalWidget")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                status = EKEventStore.authorizationStatus(for: .event)
                todayEvents.reload()
            }
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "calendar")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(.white)
                    .frame(width: 96, height: 96)
                    .background(
                        LinearGradient(
                            colors: [.blue, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .indigo.opacity(0.25), radius: 12, y: 6)

                VStack(spacing: 4) {
                    Text("월간 캘린더 위젯")
                        .font(.title3.weight(.semibold))
                    Text("Google 캘린더를 홈 화면에서 한눈에")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var quickActionsSection: some View {
        Section("빠른 실행") {
            Button {
                openURL(googleCalendarURL)
            } label: {
                ActionRow(
                    icon: "arrow.up.right.square.fill",
                    iconColor: .blue,
                    title: "Google 캘린더 열기",
                    subtitle: "공식 앱으로 바로 이동"
                )
            }
            .buttonStyle(.plain)

            Button {
                refreshWidgets()
            } label: {
                ActionRow(
                    icon: "arrow.clockwise",
                    iconColor: .green,
                    title: didRefresh ? "위젯 새로고침됨" : "위젯 새로고침",
                    subtitle: "강제로 timeline 갱신"
                )
            }
            .buttonStyle(.plain)
            .disabled(didRefresh)
        }
    }

    @ViewBuilder
    private var upcomingEventsSection: some View {
        if status == .fullAccess || status == .authorized {
            Section {
                if todayEvents.events.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 6) {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("앞으로 7일 동안 일정이 없습니다")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 12)
                        Spacer()
                    }
                } else {
                    ForEach(todayEvents.events) { event in
                        EventListRow(event: event)
                    }
                }
            } header: {
                HStack {
                    Text("다가오는 일정")
                    Spacer()
                    if !todayEvents.events.isEmpty {
                        Text("\(todayEvents.events.count)건")
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                if !todayEvents.events.isEmpty {
                    Text("앞으로 7일 일정 (최대 15건)")
                }
            }
        }
    }

    @ViewBuilder
    private var permissionSection: some View {
        Section("권한") {
            HStack(spacing: 12) {
                Image(systemName: permissionIcon)
                    .font(.title3)
                    .foregroundStyle(permissionTint)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("캘린더 접근")
                        .font(.body)
                    Text(permissionDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 4)

            switch status {
            case .notDetermined:
                Button {
                    Task { await requestAccess() }
                } label: {
                    Label("권한 요청", systemImage: "hand.raised.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .listRowBackground(Color.clear)
            case .denied, .restricted, .writeOnly:
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Label("설정 열기", systemImage: "gear")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .listRowBackground(Color.clear)
            default:
                EmptyView()
            }
        }
    }

    private var googleAccountSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label {
                    Text("iOS 캘린더에 Google 계정 연결")
                        .font(.subheadline.weight(.semibold))
                } icon: {
                    Image(systemName: "link")
                        .foregroundStyle(.blue)
                }

                Text("**설정 → 캘린더 → 계정 → 계정 추가 → Google** 에서 Google 계정을 추가하면 일정이 자동 동기화되어 위젯에 표시됩니다.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Google 캘린더 연동")
        }
    }

    private var widgetGuideSection: some View {
        Section("위젯 추가 방법") {
            StepRow(number: 1, text: "홈 화면 빈 곳을 길게 누름")
            StepRow(number: 2, text: "좌상단 + 버튼 → \"CalWidget\" 검색")
            StepRow(number: 3, text: "Large / Medium / 잠금화면 위젯 추가")
            StepRow(number: 4, text: "위젯 길게 눌러 \"Edit Widget\" 으로 표시할 캘린더 선택")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("버전")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Link(destination: URL(string: "https://github.com/BaskBoomy/CalWidget")!) {
                Label("GitHub 저장소", systemImage: "chevron.left.forwardslash.chevron.right")
            }
        } header: {
            Text("정보")
        } footer: {
            Text("Made with EventKit · WidgetKit")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
    }

    // MARK: - Computed

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(.systemGroupedBackground), Color(.systemGroupedBackground).opacity(0.85)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var permissionIcon: String {
        switch status {
        case .fullAccess, .authorized: return "checkmark.circle.fill"
        case .notDetermined: return "questionmark.circle.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }

    private var permissionTint: Color {
        switch status {
        case .fullAccess, .authorized: return .green
        case .notDetermined: return .orange
        default: return .red
        }
    }

    private var permissionDescription: String {
        switch status {
        case .fullAccess, .authorized: return "전체 접근 허용됨"
        case .notDetermined: return "아래 버튼으로 권한을 요청하세요"
        case .denied: return "거부됨 — 설정에서 변경 가능"
        case .restricted: return "제한됨"
        case .writeOnly: return "쓰기 전용 — 전체 접근 필요"
        @unknown default: return "알 수 없음"
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    // MARK: - Actions

    private func refreshWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        withAnimation { didRefresh = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { didRefresh = false }
        }
    }

    private func requestAccess() async {
        if #available(iOS 17.0, *) {
            _ = try? await store.requestFullAccessToEvents()
        }
        await MainActor.run {
            status = EKEventStore.authorizationStatus(for: .event)
            WidgetCenter.shared.reloadAllTimelines()
            todayEvents.reload()
        }
    }
}

// MARK: - Subviews

private struct ActionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(iconColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}

private struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.blue.gradient))
            Text(text)
                .font(.callout)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ContentView()
}
