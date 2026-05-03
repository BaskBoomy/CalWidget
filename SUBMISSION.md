# App Store 출시 체크리스트

이 문서는 CalWidget 을 App Store 에 출시하기 위한 단계별 가이드입니다. **모든 단계는 Jack 이 직접 Macbook 또는 웹에서 수행해야 합니다.** 코드/에셋 준비는 모두 완료되어 있습니다.

---

## Phase 1 — 사전 준비

### ☐ 1. Apple Developer Program 가입 ($99/년)

1. https://developer.apple.com/programs/enroll/ 접속
2. 본인 Apple ID 로 로그인
3. 개인 (Individual) 또는 단체 (Organization) 선택 — 개인 권장
4. 결제 + 신원 확인 (운전면허증/여권 사진)
5. **승인까지 보통 24–48시간 소요**

> Macbook 환경 (macOS Tahoe 26.4.1 + Xcode 26) 은 이미 App Store 제출 요건을 만족하므로 OS/Xcode 업그레이드는 불필요.

---

## Phase 2 — 프로젝트 준비 (Macbook)

### ☐ 4. 최신 코드 가져오기

```sh
cd ~/projects/CalWidget
git pull
xcodegen generate
open CalWidget.xcodeproj
```

### ☐ 5. Bundle ID 변경 (App Store 충돌 회피)

`com.jack.calwidget` 은 본인 팀에서만 유효. App Store 제출 전 본인의 Apple Developer Team Identifier 와 결합한 고유 ID 로 변경.

Xcode 에서:
1. 좌측 navigator → **CalWidget** 프로젝트 → **CalWidget** 타겟 → **Signing & Capabilities**
2. Bundle Identifier 를 예: `com.baskboomy.calwidget` 또는 회사 도메인 역순으로 변경
3. **CalWidgetExtension** 타겟도 동일하게: `com.baskboomy.calwidget.widget`
4. Team 드롭다운 → 본인 유료 Developer 계정 선택 (Phase 1 가입 후 보임)
5. "Automatically manage signing" 체크

### ☐ 6. 빌드 검증

- 시뮬레이터에서 ⌘R → 정상 동작 확인
- iOS 26 SDK 관련 경고/에러 있으면 알려주세요 (수정 필요할 수 있음)

---

## Phase 3 — App Store Connect 설정

### ☐ 7. 앱 레코드 생성

https://appstoreconnect.apple.com → **My Apps** → **+** → **New App**

- **Platforms**: iOS
- **Name**: `CalWidget` (이미 사용 중이면 `Cal Widget` / `CalWidget Pro` 등 시도)
- **Primary Language**: Korean
- **Bundle ID**: Phase 2-5 에서 만든 ID 선택
- **SKU**: 임의 (예: `CALWIDGET2026`)
- **User Access**: Full Access

### ☐ 8. 개인정보 처리방침 호스팅

App Store 는 **공개 URL** 의 개인정보 처리방침이 필수입니다. GitHub Pages 로 무료 호스팅:

1. https://github.com/BaskBoomy/CalWidget/settings/pages
2. **Source**: Deploy from a branch
3. **Branch**: `main` / `root`
4. **Save**
5. 1–2분 후 https://baskboomy.github.io/CalWidget/PRIVACY 에서 확인 가능

이 URL 을 App Store Connect 의 **App Information → Privacy Policy URL** 에 입력.

### ☐ 9. App Information 입력

App Store Connect → 본인 앱 → **App Information**:

- **Privacy Policy URL**: https://baskboomy.github.io/CalWidget/PRIVACY
- **Subtitle**: `월간 캘린더 위젯` (최대 30자)
- **Category**:
  - Primary: **Productivity**
  - Secondary: **Utilities**
- **Content Rights**: "Does not contain third-party content" 체크
- **Age Rating**: 모든 항목 None → 4+

### ☐ 10. App Privacy (Privacy Nutrition Labels)

App Store Connect → **App Privacy**:

- **Data Collected**: "No, we do not collect data" 선택
- 이미 `PrivacyInfo.xcprivacy` 가 같은 내용을 선언 → 매치 확인

### ☐ 11. Pricing & Availability

- **Price**: Free
- **Availability**: 전 세계 또는 대한민국만 — 본인 선택

---

## Phase 4 — 메타데이터 + 스크린샷

### ☐ 12. 버전 메타데이터 입력

App Store Connect → **iOS App** → **1.0 Prepare for Submission**:

`METADATA.md` 파일에 한/영 description, keywords 등 미리 작성해뒀습니다. 그대로 복사 붙여넣기.

### ☐ 13. 스크린샷 촬영 (필수)

1290×2796 (iPhone 6.7") **최소 1장, 권장 3–5장**.

권장 화면:
1. 메인 앱 — 다가오는 일정 리스트가 보이는 화면
2. 홈 화면 — Large 월간 위젯이 추가된 화면
3. 홈 화면 — Medium agenda 위젯
4. 위젯 추가 화면 (위젯 galary 에서 CalWidget 보이는 모습)
5. 잠금 화면 — accessoryRectangular 위젯

**촬영 방법:**
- iPhone 16 Pro Max 시뮬레이터 사용 (Xcode 에서 시뮬레이터 선택 → iPhone 16 Pro Max)
- ⌘S 로 스크린샷 저장
- 실제 폰 촬영 시: iOS 18+ 인 경우 1290×2796 자동
- App Store Connect 에 업로드

### ☐ 14. App Store Connect 에 스크린샷 업로드

1.0 버전 화면 → **iPhone 6.7" Display** 섹션 → 드래그 업로드

---

## Phase 5 — 빌드 업로드 + 제출

### ☐ 15. Archive 빌드

Xcode 에서:
1. 상단 디바이스 선택 → **Any iOS Device (arm64)**
2. **Product → Archive** (~5분 소요)
3. Organizer 창이 자동으로 열림

### ☐ 16. App Store 에 업로드

Organizer → 방금 만든 archive 선택 → **Distribute App**:
1. **App Store Connect** 선택
2. **Upload** 선택
3. Distribution 자동 서명
4. 업로드 (~5–10분)
5. App Store Connect 에서 **TestFlight** 탭으로 가서 빌드 처리 완료 대기 (~10–30분)

### ☐ 17. 빌드를 버전에 연결

App Store Connect → **iOS App** → **1.0** → **Build** 섹션 → **+** → 방금 업로드한 빌드 선택

### ☐ 18. 심사 제출

화면 하단 **"Add for Review"** → **"Submit to App Review"**

추가 답변:
- Export Compliance: "Does not use encryption" 또는 "Uses standard iOS encryption only" → 후자 선택, 추가 서류 불필요
- Content Rights: 기존 답변 유지
- Advertising Identifier (IDFA): "No, my app does not use IDFA"

---

## Phase 6 — 심사

### ☐ 19. 심사 대기

- 평균 24–48시간 (성수기 길어짐)
- 진행 상태: App Store Connect 에 표시
- 거절 시 reviewer 메시지를 보고 대응 (이 채팅에서 함께 처리)

### ☐ 20. 출시

- 승인 시 **자동 출시** 또는 **수동 출시** (Phase 5-17 단계에서 옵션 선택)
- App Store 에서 검색 가능까지 ~1시간

---

## 흔한 거절 사유 + 대응

| 사유 | 우리 대응 |
|---|---|
| 단독 기능 부족 ("metadata-only" 앱) | 메인 앱에 네이티브 일정 리스트 추가됨 ✅ |
| 권한 사용 이유 불충분 | NSCalendarsFullAccessUsageDescription 명시 ✅ |
| 개인정보 처리방침 누락 | PRIVACY.md + GitHub Pages ✅ |
| 트레이드마크 침해 (Google) | 앱 이름에 Google 미사용. description 에서만 "Google 캘린더와 호환" 형태로 언급 ✅ |
| 충돌/오류 | 시뮬레이터 + 실기기 빌드 검증됨 ✅ |
| 데이터 수집 미공시 | PrivacyInfo.xcprivacy = 수집 없음 ✅ |

---

## 도움 요청

각 단계 진행 중 막히는 부분 있으면 다음을 알려주세요:
1. 어느 단계에서
2. 화면에 뜨는 메시지/에러
3. 가능하면 스크린샷

함께 풀어나갑시다.
