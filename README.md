# 락인 포커스 (Lockin Focus)

> 손이 움직이기 전에 생각하게 만드는 iOS 집중 강화 앱.

![iOS](https://img.shields.io/badge/iOS-16%2B-black)
![Swift](https://img.shields.io/badge/Swift-5.9-F05138)
![UI](https://img.shields.io/badge/UI-SwiftUI-0091FF)
![FamilyControls](https://img.shields.io/badge/FamilyControls-individual-4B7BEC)
![Tests](https://img.shields.io/badge/tests-540%2B-2E7D57)

---

## 이 앱이 하는 일

락인 포커스는 사용자가 SNS/쇼핑 앱을 **무의식적으로 열기 전에** 자각 공간을 만든다.
설계 철학:

1. **충동(Impulse)** — 손가락이 아이콘으로 향한다.
2. **인지(Awareness)** — iOS Shield 가 먼저 끼어들어 "왜 열려 해요?" 라고 묻는다.
3. **선택(Choice)** — 카운트다운 뒤 돌아갈지 계속할지 **직접** 선택한다.

허용할 앱 3–10개만 사용자가 고르고, 나머지는 `.all(except:)` 역-화이트리스트로 일괄 차단.
Shield 버튼 탭 → 메인 앱 인터셉트 UI 유도. **금지가 아니라 재질문.**

---

## 기능

### 핵심
- **5 스텝 온보딩** (가치 · 권한 · 프리셋 · 앱 선택 · 스케줄 · 앱 비밀번호)
- **홈 대시보드** — 오늘 집중 점수, 허용 앱, 다음 스케줄, 7일 스트릭 점, 명언 카드
- **허용 앱 재선택** (FamilyActivityPicker 래퍼)
- **스케줄 편집** — 프리셋 + 요일·시간 커스텀
- **인터셉트 플로우** — 첫 해제는 10초 파형 + 문장 입력 + 6자리 비번, 이후 30/60초 축소

### 집중 강화
- **엄격 모드** — 설정한 시간까지 어떤 방법으로도 해제 불가 (시계 조작 탐지 포함)
- **게이미피케이션** — 나무 성장 6단계 (씨앗 → 열매) + 점수 규칙
- **뱃지 시스템** — 26개 (집중 시간·스트릭·점수·엄격 완주·순위 구간)
- **뱃지 축하 모달** + **뱃지 모음 회전 상세 카드**
- **햅틱 피드백** — 뱃지 획득·인터셉트 돌아가기·엄격 만료

### 소셜
- **CloudKit 퍼블릭 랭킹** — 일간/주간/월간
- **친구 초대 링크** — `lockinfocus://friend?uid=X&nick=Y`
- **그룹 랭킹** — 전체/친구 scope 전환
- **iCloud KV** — 같은 Apple ID 기기 간 닉네임/userID 동기화

### 리포트 & 알림
- **주간 리포트** — 일/주/월 분석 + Swift Charts
- **일요일 20:00 로컬 알림** — 주간 리포트 유도
- **위젯** — FocusScore (S/M/L + accessory 3종), Quote
- **Live Activity + Dynamic Island** — 집중 세션 활성 중 남은 시간/점수

### 국제화 & 접근성
- **6개 언어** — 한국어 · 영어 · 일본어 · 중국어 간체 · 프랑스어 · 힌디어
- **Dynamic Type** — `@ScaledMetric` 기반 스케일 폰트
- **iPad 레이아웃** — `readingWidth()` 모디파이어로 가독 폭 제한

---

## 기술 스택

- **언어/UI**: Swift 5.9 · SwiftUI · iOS 16.0+
- **핵심 프레임워크**:
  - `FamilyControls` — 권한, FamilyActivityPicker, FamilyActivitySelection
  - `ManagedSettings` — Shield 정책 (`.all(except:)`)
  - `DeviceActivity` — 스케줄 모니터링
  - `ActivityKit` (iOS 16.2+) — Live Activity / Dynamic Island
  - `CloudKit` — 퍼블릭 랭킹
  - `WidgetKit` — 홈/잠금 위젯
- **DI**: `AppDependencies` (ObservableObject) — live/preview/simulator 분기
- **Persistence**: App Group UserDefaults + Codable, iCloud KV Store
- **빌드**: XcodeGen (`Project.yml`)
- **테스트**: XCTest 469 케이스 + ViewInspector

---

## 프로젝트 구조

```
Lockin Focus/
├── LockinFocus/                         # 메인 앱
│   ├── App/                             # @main, RootView
│   ├── Core/
│   │   ├── Activities/                  # Live Activity (attributes + service)
│   │   ├── BlockingEngine/              # ManagedSettings + Noop
│   │   ├── DI/                          # AppDependencies
│   │   ├── DeepLink/                    # RouteParser, FriendInviteLink
│   │   ├── Leaderboard/                 # CloudKit service + protocol
│   │   ├── Models/                      # Schedule, InterceptEvent, Badge, TreeStage, DailyFocus
│   │   ├── MonitoringEngine/            # DeviceActivityCenter + Noop
│   │   ├── Persistence/                 # UserDefaults + iCloud KV store
│   │   ├── Protocols/                   # 경계 프로토콜
│   │   ├── Shared/                      # AppGroup, SharedKeys
│   │   ├── Theme/                       # AppColors, scaledFont
│   │   └── UI/                          # Haptics, Toast, ReadingWidth
│   ├── Features/
│   │   ├── AppSelection/                # FamilyActivityPicker 래퍼
│   │   ├── Badges/                      # BadgesView + CelebrationView + DetailCard
│   │   ├── Dashboard/                   # 점수/앱/스케줄 + 7일 스트릭 + 수동 토글 + FocusEndConfirm
│   │   ├── Intercept/                   # 10/30/60초 카운트다운
│   │   ├── Leaderboard/                 # 전체/친구 랭킹 + FriendsManagement + NicknameSetup
│   │   ├── Onboarding/                  # 5 스텝 + 비밀번호
│   │   ├── Quotes/                      # 명언 상세
│   │   ├── Report/                      # 일/주/월 리포트 + 차트
│   │   ├── Schedule/                    # 요일·시간 편집
│   │   ├── Settings/                    # 재선택 · 편집 · 엄격 시작 · 비번 · 버전
│   │   └── Shared/                      # PrimaryButton 등
│   └── Resources/                       # Assets + Localizable.strings (ko/en/ja/zh-Hans/fr/hi)
├── DeviceActivityMonitorExtension/      # 스케줄 경계 훅
├── ShieldConfigurationExtension/        # Shield UI
├── ShieldActionExtension/               # Shield 버튼 탭 → 큐 적재
├── LockinFocusWidgets/                  # FocusScore + Quote + FocusActivity 위젯
├── LockinFocusTests/                    # XCTest 469 케이스
├── docs/                                # 설계·리뷰·프라이버시·릴리스 체크리스트
└── Project.yml                          # XcodeGen 스펙
```

### 타깃 구조

| 타깃 | 종류 | 목적 |
|---|---|---|
| `LockinFocus` | application | 메인 앱 |
| `DeviceActivityMonitorExtension` | app-extension | 스케줄 경계 훅 |
| `ShieldConfigurationExtension` | app-extension | Shield UI |
| `ShieldActionExtension` | app-extension | Shield 버튼 처리 |
| `LockinFocusWidgets` | app-extension | 위젯 + Live Activity |
| `LockinFocusTests` | bundle.unit-test | 단위/계약 테스트 |

5 타깃 전체가 App Group `group.com.moonkj.LockinFocus` 공유.

---

## 빠른 시작

필수: Xcode 16+, macOS Sonoma+, Apple Developer 계정 (Family Controls capability 필요).

```bash
brew install xcodegen
xcodegen generate
open LockinFocus.xcodeproj
```

시뮬레이터 빌드:

```bash
xcodebuild -project LockinFocus.xcodeproj \
           -scheme LockinFocus \
           -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
           CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
           build
```

시뮬레이터에선 `AppDependencies.live()` 가 `#if targetEnvironment(simulator)` 분기로
Noop 엔진을 주입하므로 UI 흐름은 되지만 Shield 는 뜨지 않는다. **Shield/DeviceActivity 검증은 실기기 전용.**

`DEVELOPMENT_TEAM` 은 Xcode 에서 본인 팀으로 지정한다.

---

## 테스트

```bash
xcodebuild test -project LockinFocus.xcodeproj \
                -scheme LockinFocus \
                -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

- 540+ 케이스 — Core 로직 95%+, 메인 앱 전체 ~88%.
- iOS 26 + ViewInspector + `AccessibilityImageLabel` 블로커로 일부 뷰 테스트는 현재 통과 불가 (외부 라이브러리 이슈, 프로덕션 영향 없음).
- 핵심 계약 회귀 방어:
  - `InterceptEventTests.testRawValueStability_*` — 5 키 안정성
  - `WidgetProviderTests` + `WidgetContractExtendedTests` — App Group UserDefaults 경계
  - `FriendInviteLinkTests` — URL 왕복
  - `FocusActivityAttributesTests` — Codable/Hashable 계약

---

## Family Controls Entitlement

- **개발**: Xcode Capabilities → Family Controls 추가. 본인 팀 provisioning 으로 실기기 설치 가능.
- **배포**: Apple 별도 승인 필요 — [developer.apple.com/contact/request/family-controls-distribution](https://developer.apple.com/contact/request/family-controls-distribution). 5–14 영업일 소요.

---

## 릴리스 체크리스트

상세: [`docs/ReleaseChecklist.md`](docs/ReleaseChecklist.md)

### 외부 차단 항목
- ⬜ Family Controls 배포 승인 신청
- ⬜ CloudKit Production 스키마 배포
- ⬜ GitHub Pages 활성화 (Settings → Pages → Source: GitHub Actions)
- ⬜ App Store Connect 메타데이터 + 스크린샷

### 코드 완료
- ✅ Privacy Policy — 6 언어 (`docs/PrivacyPolicy.md` → [moonkj.github.io/lockin/PrivacyPolicy/](https://moonkj.github.io/lockin/PrivacyPolicy/))
- ✅ Entitlements — Family Controls + App Group + CloudKit + iCloud KV
- ✅ Info.plist — 딥링크 스킴, `NSSupportsLiveActivities`, `CFBundleLocalizations`
- ✅ Dynamic Type + iPad 레이아웃
- ✅ 6 언어 로컬라이제이션

---

## 핵심 설계 결정

### 역-화이트리스트 (`.all(except:)`)
`FamilyActivitySelection` 은 기본 blocklist 구조라, `.shield.applicationCategories = .all(except: selection.applicationTokens)` 패턴으로 whitelist 를 근사한다. 설치 앱 enumerate API 가 없어 이게 유일한 접근. 시스템 앱 일부는 카테고리 밖이라 온보딩 프리셋이 안전판.

### Shield → Queue → Intercept
앱이 열리기 "직전"에 뷰를 삽입하는 공식 API 는 없음. **Shield → 버튼 탭 → ShieldActionExtension → App Group 큐 적재 → 메인 앱 포그라운드 진입 시 드레인 → InterceptView 자동 프레젠테이션.** Shield 자체가 1차 인지 개입.

### 3 Screen Time Extension 타깃
DeviceActivityMonitor / ShieldConfiguration / ShieldAction 은 독립 확장 포인트. 각각 전용 entitlement.

### Live Activity 는 별도 Widget 아님
`LockinFocusWidgets` 번들 안의 `ActivityConfiguration(for:)` 로 같은 extension process 에서 호스팅. `FocusActivityAttributes` 는 메인 앱 + widget target 양쪽에 소스 공유.

### 엄격 모드 시계 조작 방어
`strictModeStartAt` 와 `strictModeEndAt` 둘 다 기록. 현재 시각이 start 보다 이전이면 사용자가 시계를 되돌린 것으로 판정하고 엄격 모드 유지.

---

## 한계 & Phase 5+

- iOS 26 + ViewInspector 0.10.3 이 `AccessibilityImageLabel` 을 traversal 블로커로 남김. 81 건 뷰 테스트가 이 영향 (인프라 이슈).
- `temporarilyAllow(token:for:)` 구현은 `.all(except:)` associated value 역추출 API 부재로 전체 5분 해제 + 자동 재차단 으로 단순화.
- Widget 타깃 내부 렌더 테스트는 별도 test target 없이는 부재. 계약 테스트(UserDefaults 경계)로 대체.

---

## 문서

- **설계**: [`docs/02_UX_Design.md`](docs/02_UX_Design.md), [`docs/03_Architecture.md`](docs/03_Architecture.md)
- **진행 로그**: [`Tasklist.md`](Tasklist.md)
- **Privacy Policy**: [`docs/PrivacyPolicy.md`](docs/PrivacyPolicy.md)
- **릴리스 체크리스트**: [`docs/ReleaseChecklist.md`](docs/ReleaseChecklist.md)
- **Xcode 셋업**: [`docs/01_Xcode_Setup_Guide.md`](docs/01_Xcode_Setup_Guide.md)

---

## 라이선스

TBD

---

## 연락처

- Email: imurmkj@naver.com
- GitHub Issues: [moonkj/lockin/issues](https://github.com/moonkj/lockin/issues)
