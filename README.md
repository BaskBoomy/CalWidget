# CalWidget — iOS 월간 캘린더 위젯

Google 캘린더(또는 iOS 캘린더의 다른 계정) 일정을 한 달 grid로 보여주는 large 사이즈 홈 위젯.

## 동작 방식

- iOS 기본 캘린더 DB(EventKit)에서 이번 달 일정을 읽어옴
- 사전에 **설정 → 캘린더 → 계정 → Google 추가** 로 Google 캘린더를 동기화해 둬야 함
- 위젯 자체는 네트워크 통신 없음 → 빠르고 안정적

## 요구 사항

- macOS 14+
- Xcode 15+ (App Store에서 설치)
- 무료 Apple ID (App Store와 동일한 계정으로 충분)
- 본인 iPhone (iOS 17+)

## 최초 빌드 절차

### 1. Xcode 설치

App Store 에서 "Xcode" 검색 후 설치 (~10–15GB, ~30분).

설치 후 한 번 실행하여 라이선스 동의 + 추가 컴포넌트 설치.

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -version    # 버전 확인
```

### 2. xcodegen 설치

```sh
brew install xcodegen
```

### 3. Xcode 프로젝트 생성

```sh
cd ~/projects/CalWidget
xcodegen generate
open CalWidget.xcodeproj
```

### 4. 서명 설정 (Xcode GUI)

1. 프로젝트 navigator 에서 **CalWidget** 타겟 선택 → **Signing & Capabilities**
2. **Team** 드롭다운에서 본인 Apple ID 선택 (없으면 "Add an Account…" 로 추가)
3. **Bundle Identifier** 가 `com.jack.calwidget` 으로 되어 있으면 본인 ID 로 바꿈 (예: `com.본인이름.calwidget`)
4. **CalWidgetExtension** 타겟에서도 같은 Team 선택, Bundle ID 는 `<앱 번들ID>.widget`

### 5. iPhone 연결 후 빌드

1. iPhone 을 USB 로 연결
2. iPhone 에서 **설정 → 일반 → VPN 및 기기 관리** 에서 본인 개발자 인증서 신뢰 (최초 1회)
3. Xcode 상단 디바이스 선택에서 본인 iPhone 선택
4. **Run** (⌘R)

### 6. iPhone 에서 권한 + Google 동기화

1. 설치된 **CalWidget** 앱 열기 → "캘린더 접근 권한 요청" 탭 → "전체 접근" 허용
2. **설정 → 캘린더 → 계정 → 계정 추가 → Google** 로 Google 계정 연결
3. 동기화할 캘린더 선택 (캘린더 앱에서 좌하단 "캘린더" 버튼)
4. 홈 화면 길게 누름 → 좌상단 + → "CalWidget" 검색 → **Large** 위젯 추가

## 구조

```
CalWidget/
├── project.yml                       # xcodegen 설정
├── CalWidget/                        # 메인 앱 (권한 요청 화면)
│   ├── CalWidgetApp.swift
│   └── ContentView.swift
├── CalWidgetExtension/               # 위젯 extension
│   ├── CalWidgetBundle.swift
│   ├── MonthWidget.swift             # TimelineProvider + Widget config
│   └── MonthWidgetView.swift         # SwiftUI grid UI
└── README.md
```

## 동작 디테일

- **데이터 로드**: 30분마다 timeline reload + 메인 앱 실행 중 EKEventStoreChanged 감지 시 즉시 reload
- **셀 탭**: 해당 날짜로 Google 캘린더 앱 열림 (`googlecalendar://?action=showRange&start=YYYYMMDD`)
- **종일 일정**: 풀 너비 색 bar + 흰 텍스트
- **시간 일정**: 색상 dot + 본문 텍스트, 셀당 최대 2개 + 초과 시 `+N`
- **색상**: 캘린더별 색상 자동 반영
- **오늘**: 빨간 원 highlight
- **주말**: 일요일 빨강 / 토요일 파랑
- **VoiceOver**: 각 날짜 셀에 일정 정보 음성 안내

## 위젯 커스터마이징

위젯 길게 눌러 **Edit Widget** 을 탭하면 표시할 캘린더를 선택할 수 있음. 비워두면 모든 캘린더가 표시됨.

## 무료 계정 한계

- 무료 Apple ID 로 빌드한 앱은 **7일마다 재빌드/재서명** 필요
- 영구 사용하려면 Apple Developer Program ($99/년) 가입

## 커스터마이징

- 셀 폰트 크기: `MonthWidgetView.swift` 의 `.font(.system(size: 7))` 등 조정
- 표시 일정 개수: `cell.events.prefix(2)` 의 숫자 변경
- 일주일 시작 요일: iOS 시스템 설정 따름 (`Calendar.current.firstWeekday`)
- 색상 테마: `DayCellView.eventChip` 배경 opacity 조정

## 알려진 제약

- iPhone 만 지원 (iPad 는 빌드 가능하지만 레이아웃 미최적화)
- systemLarge 사이즈만 지원 (medium 은 셀 너무 좁아서 텍스트 안 들어감)
- 위젯 탭 인터랙션은 추후 추가 (`Link` 또는 `widgetURL` 로 캘린더 앱 deep link 가능)
