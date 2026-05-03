import SwiftUI
import EventKit
import WidgetKit

struct ContentView: View {
    @State private var status: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    private let store = EKEventStore()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "calendar")
                    .font(.system(size: 72))
                    .foregroundStyle(.blue)
                    .padding(.top, 32)

                Text("CalWidget")
                    .font(.largeTitle.bold())

                Text("월간 캘린더 위젯")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                permissionSection

                Divider()

                instructionSection

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var permissionSection: some View {
        switch status {
        case .fullAccess, .authorized:
            VStack(spacing: 8) {
                Label("캘린더 접근 허용됨", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
                Text("홈 화면을 길게 눌러 위젯을 추가하세요.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("위젯 새로고침") {
                    WidgetCenter.shared.reloadAllTimelines()
                }
                .buttonStyle(.bordered)
            }
        case .notDetermined:
            Button("캘린더 접근 권한 요청") {
                Task { await requestAccess() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        case .denied, .restricted, .writeOnly:
            VStack(spacing: 8) {
                Label("권한이 필요합니다", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.headline)
                Text("설정 → CalWidget → 캘린더 에서 '전체 접근'을 허용해 주세요.")
                    .multilineTextAlignment(.center)
                    .font(.callout)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Link("설정 열기", destination: url)
                        .buttonStyle(.bordered)
                }
            }
        @unknown default:
            Text("알 수 없는 권한 상태")
        }
    }

    private var instructionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Google 캘린더 연동")
                .font(.headline)
            Text("설정 → 캘린더 → 계정 → 계정 추가 → Google 에서 Google 계정을 추가하면 동기화된 일정이 위젯에 자동으로 표시됩니다.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("표시할 캘린더가 너무 많다면 기본 캘린더 앱에서 원하는 캘린더만 체크해 두세요.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func requestAccess() async {
        do {
            if #available(iOS 17.0, *) {
                _ = try await store.requestFullAccessToEvents()
            }
            await MainActor.run {
                status = EKEventStore.authorizationStatus(for: .event)
                WidgetCenter.shared.reloadAllTimelines()
            }
        } catch {
            print("EventKit access error: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
