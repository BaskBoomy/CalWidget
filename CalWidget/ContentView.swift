import SwiftUI
import EventKit
import WidgetKit
import OSLog

struct ContentView: View {
    @State private var status: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    @State private var manualOpenResult: String = ""
    @EnvironmentObject private var diag: Diagnostics
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

                diagnosticsSection

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
                    appLogger.info("Manual reloadAllTimelines")
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

    private var diagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🔍 위젯 탭 진단")
                .font(.headline)

            schemeRow(label: "googlecalendar://", scheme: "googlecalendar://")
            schemeRow(label: "comgooglecalendar://", scheme: "comgooglecalendar://")
            schemeRow(label: "x-google-calendar://", scheme: "x-google-calendar://")

            Divider().padding(.vertical, 4)

            Text("URL scheme 직접 호출 테스트").font(.caption.bold())
            HStack {
                Button("googlecalendar://") {
                    manualOpen("googlecalendar://")
                }
                Button("comgooglecalendar://") {
                    manualOpen("comgooglecalendar://")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            if !manualOpenResult.isEmpty {
                Text(manualOpenResult)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            Divider().padding(.vertical, 4)

            Text("위젯 탭 시 이 앱이 받은 URL").font(.caption.bold())
            if let url = diag.lastURL, let at = diag.lastAt {
                VStack(alignment: .leading, spacing: 2) {
                    Text(url).font(.caption.monospaced())
                    Text("at \(at.formatted())")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                Text("⚠️ 이 칸이 위젯 탭 후 채워져있다면 = URL이 외부 앱이 아닌 우리 앱으로 라우팅됨 (버그)")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            } else {
                Text("(앱이 외부 URL 받은 기록 없음 — 정상)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func schemeRow(label: String, scheme: String) -> some View {
        let url = URL(string: scheme)!
        let can = UIApplication.shared.canOpenURL(url)
        return HStack(spacing: 8) {
            Image(systemName: can ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(can ? .green : .red)
            Text(label).font(.caption.monospaced())
            Spacer()
            Text(can ? "인식됨" : "미등록")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func manualOpen(_ scheme: String) {
        let url = URL(string: scheme)!
        appLogger.info("Manual open attempt: \(scheme, privacy: .public)")
        UIApplication.shared.open(url, options: [:]) { ok in
            appLogger.info("Manual open result: scheme=\(scheme, privacy: .public), success=\(ok)")
            DispatchQueue.main.async {
                manualOpenResult = "→ \(scheme): \(ok ? "✅ 열림" : "❌ 실패")"
            }
        }
    }

    private var instructionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Google 캘린더 연동")
                .font(.headline)
            Text("설정 → 캘린더 → 계정 → 계정 추가 → Google 에서 Google 계정을 추가하면 동기화된 일정이 위젯에 자동으로 표시됩니다.")
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
            appLogger.error("EventKit access error: \(error.localizedDescription, privacy: .public)")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(Diagnostics.shared)
}
