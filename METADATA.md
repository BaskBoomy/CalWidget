# App Store Connect 메타데이터 초안

이 문서의 텍스트를 App Store Connect 의 해당 필드에 그대로 복사 붙여넣기 하세요. 한국어가 기본 언어, 영어는 보조 (선택).

---

## 한국어 (Primary)

### App Name (최대 30자)
```
CalWidget
```

### Subtitle (최대 30자)
```
월간 캘린더 위젯
```

### Promotional Text (최대 170자, 출시 후 수시 변경 가능)
```
홈 화면에서 한 달 일정을 한눈에. iOS 기본 캘린더와 동기화된 모든 일정 (Google · 회사 · iCloud)을 깔끔한 월간 grid로 보여줍니다.
```

### Description (최대 4000자)
```
CalWidget은 iOS 캘린더에 동기화된 모든 일정을 홈 화면 위젯으로 한눈에 보여주는 앱입니다. Google 캘린더, iCloud, Outlook, 회사 캘린더 등 iOS 시스템 캘린더에 추가된 모든 계정의 일정을 자동으로 통합합니다.

[주요 기능]

• 월간 위젯 (Large)
한 달 전체 일정을 7×6 grid 로 표시. 셀당 일정 2개와 +N 카운트, 종일 일정은 색상 bar 로 강조.

• 일정 목록 위젯 (Medium / Large)
앞으로 5일의 일정을 시간순으로 표시. 각 행 탭 시 해당 날짜로 즉시 이동.

• 다음 일정 위젯 (잠금화면)
잠금화면 rectangular / circular / inline 3종 — 다가오는 일정 또는 오늘의 남은 일정 수.

• 표시할 캘린더 선택
위젯을 길게 눌러 Edit Widget → 표시할 캘린더만 골라서 깔끔하게.

• 실시간 업데이트
일정 추가/수정 시 즉시 반영. 30분 주기로도 자동 갱신.

• 셀 탭 → Google 캘린더 즉시 이동
어떤 날짜든 탭 한 번으로 Google 캘린더 앱의 해당 날짜 화면으로 이동.

• 다크 모드 + 접근성
시스템 다크 모드 자동 적응. VoiceOver 레이블 완전 지원.

[프라이버시]

CalWidget 은 어떠한 개인정보도 수집하지 않으며, 외부 서버나 제3자에게 데이터를 전송하지 않습니다. 모든 일정 데이터는 디바이스 내부에서만 처리됩니다. 분석 도구, 광고 SDK, 추적 식별자도 일절 사용하지 않습니다.

[설정 방법]

1. 설정 → 캘린더 → 계정 → 계정 추가 → Google 로 Google 계정 연결 (이미 했으면 skip)
2. CalWidget 앱 열기 → 캘린더 권한 허용
3. 홈 화면 길게 눌러 + → "CalWidget" 검색 → 원하는 사이즈 선택
4. 위젯 길게 눌러 Edit Widget → 표시할 캘린더 선택

iOS 17.0 이상.

문의 / 버그 제보: https://github.com/BaskBoomy/CalWidget/issues
```

### Keywords (최대 100자, 쉼표로 구분, 공백 포함)
```
캘린더,위젯,월간,일정,스케줄,calendar,widget,month,홈화면,잠금화면,일정관리
```

### Support URL
```
https://github.com/BaskBoomy/CalWidget/issues
```

### Marketing URL (선택, 비워둬도 됨)
```
https://github.com/BaskBoomy/CalWidget
```

### What's New in This Version (1.0 신규 출시)
```
• CalWidget 첫 출시
• 월간 grid · 일정 목록 · 다음 일정 위젯 3종
• 캘린더 필터, 다크 모드, VoiceOver 지원
```

---

## English (Optional Secondary)

### App Name
```
CalWidget
```

### Subtitle
```
Monthly Calendar Widget
```

### Promotional Text
```
See your entire month at a glance on your home screen. Works with Google Calendar, iCloud, Outlook, and any account synced to iOS Calendar.
```

### Description
```
CalWidget shows your iOS Calendar events as elegant home screen widgets. Any account synced through iOS Calendar — Google, iCloud, Outlook, work calendars — appears automatically.

[Features]

• Month Widget (Large)
A full 7×6 grid showing the entire month. Up to 2 event titles per cell with a +N counter; all-day events render as colored bars for instant scanning.

• Agenda Widget (Medium / Large)
The next 5 days listed chronologically. Each row deep-links to that date in Google Calendar.

• Next Event Widget (Lock Screen)
Three accessory variants — rectangular, circular, inline — showing your upcoming event or today's remaining count.

• Calendar Filter
Long-press the widget → Edit Widget to pick exactly which calendars to show.

• Live Updates
Edits propagate immediately while the app is open; otherwise refreshed every 30 minutes.

• Tap to Navigate
Tap any cell to jump straight to that day in Google Calendar.

• Dark Mode + Accessibility
Adapts automatically to system appearance. Complete VoiceOver label support.

[Privacy]

CalWidget collects nothing. All calendar data stays on your device — no servers, no analytics, no tracking, no third-party SDKs.

[Setup]

1. Settings → Calendar → Accounts → Add Account → Google
2. Open CalWidget → grant calendar access
3. Long-press home screen → + → search "CalWidget" → choose a size
4. Long-press widget → Edit Widget → pick which calendars to show

Requires iOS 17.0 or later.

Issues / feedback: https://github.com/BaskBoomy/CalWidget/issues
```

### Keywords
```
calendar,widget,month,schedule,agenda,events,homescreen,lockscreen,productivity,planner
```

---

## App Privacy 정답 모음 (App Store Connect → App Privacy)

질문에 그대로 답하세요:

- **Do you or your third-party partners collect data from this app?** → **No, we do not collect data from this app**

이걸 선택하면 추가 질문 없이 끝납니다.

---

## App Review 추가 정보 (App Review Information)

### Sign-In Information
- 로그인 기능 없음 → 비워둠

### Contact Information
- First name / Last name: 본인 이름
- Email / Phone: 응답 가능한 연락처
- (Apple reviewer 가 문의 시 사용)

### Notes for Reviewer
```
This app reads events from iOS Calendar (EventKit) to display them in widgets and on the main app screen. It does not collect, transmit, or store any user data externally.

The app uses the googlecalendar:// URL scheme to open Google Calendar (third-party app) when users tap a date cell. This is documented in the description.

To test:
1. Settings → Calendar → Accounts → add a Google or iCloud account so calendar events are available
2. Open CalWidget → grant calendar access
3. Add the CalWidget Large widget to home screen — month grid appears

Privacy policy: https://baskboomy.github.io/CalWidget/PRIVACY.html
```

### Demo Account
- 로그인 없으므로 불필요 → 비워둠

### Attachment
- 불필요
