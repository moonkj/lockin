# 03 — Lockin Focus 아키텍처 설계 요약

> 작성: Architect 에이전트 / 2026-04-23
> 대상: Coder, Debugger, Test Engineer, Performance Engineer, UX Designer
> 이 문서의 목적: iOS Screen Time API의 **실제 제약**을 정직하게 정리하고, MVP + 확장을 수용할 모듈 구조를 확정하여 Coder가 바로 착수 가능하도록 한다.
> 근거 표기 규약: `(근거)` = Apple 공식 문서/WWDC 세션에서 확인됨, `(추정)` = 문서 확인 실패로 추론, `(경험적)` = 커뮤니티/개발자 관행에서 알려진 사항.
> 본 리서치는 `WebFetch` 기반. 일부 Apple 문서 페이지는 JS 렌더링으로 본문 취득 실패 → WWDC 세션 트랜스크립트(공식)를 1차 근거로 사용함.

---

## 0. 요약 (Executive Summary)

- **Whitelist 방식은 API 수준에서 "완전한 화이트리스트"로는 불가능하지만, `ShieldSettings.ActivityCategoryPolicy.allExcept(_:)` 를 활용한 "역-화이트리스트"로 **근사 가능**. 단, FamilyActivityPicker가 반환하는 앱만 "예외(허용)"로 지정할 수 있고, 시스템의 나머지 모든 앱을 **카테고리 수준에서 일괄 차단**하는 방식. 정확히는 "카테고리 전체 차단 + 사용자가 고른 앱만 면제". 설치된 모든 써드파티 앱을 개별 ApplicationToken으로 enumerate하는 API는 존재하지 않는다. (근거 + 경험적)
- **"중간 인터셉트 UI"는 Shield를 대체할 수 없다**. iOS는 다른 앱의 포그라운드 전환을 강제하지 않는다. 현실적 경로는 **(a) ShieldAction Extension에서 사용자의 "10초 생각하기" 탭 → 딥링크로 메인 앱을 여는 방식** 뿐이며, 이 경우 Shield 화면을 먼저 보여주고 그 위에 "인터셉트 UX의 1차 트리거 버튼"을 얹는 형태가 된다. Shield 자체를 우회하여 앱 실행 "직전"에 임의 뷰를 삽입하는 공식 수단은 없다.
- **카테고리 자동분류 (도파민 디톡스 모드)**: Apple이 제공하는 `ActivityCategoryToken`은 **불투명(opaque)** 이라 "이 토큰이 SNS 카테고리인가?" 같은 질의가 불가능. 그러나 `FamilyActivityPicker` UI는 Apple의 카테고리 분류대로 앱을 그룹화해서 사용자에게 보여주므로, **사용자가 "SNS 카테고리 체크" → 해당 카테고리 토큰이 그대로 저장됨** 경로로 "반-자동" 분류가 가능. 순수 자동(앱이 내부에서 카테고리 판단)은 불가.
- **상태 저장**은 `UserDefaults(suiteName: App Group)` + `Codable` 로 충분. FamilyActivitySelection이 `Codable`이므로 그대로 직렬화 가능. SwiftData/CoreData는 MVP 범위에서는 over-engineering — 확장 단계(주간 리포트 그래프)에서 도입.

---

## 1. iOS Screen Time API 제약 조사

### 1.1 FamilyControls Authorization 흐름

#### 1.1.1 개인(Individual) vs 자녀(Child) — iOS 16의 핵심 변화

**iOS 15** (초기 도입): `requestAuthorization()` 호출 시 **자녀 계정 + 부모의 iCloud 인증**이 필수였음. 즉 "Family Sharing" 구성원인 어린이만 제어 대상. (근거: WWDC22 "What's New in Screen Time API" 트랜스크립트)

**iOS 16+**: `requestAuthorization(for: .individual)` 도입. 사용자가 **자기 자신의 기기에** 스크린타임 제어를 위임할 수 있음. 자기 관리(self-management) 앱의 문이 열림.

```swift
import FamilyControls

let center = AuthorizationCenter.shared
Task {
    do {
        try await center.requestAuthorization(for: .individual)
    } catch {
        print("Failed to enroll with error: \(error)")
    }
}
```

(근거: WWDC22 공식 트랜스크립트)

**핵심 차이** (근거 + 추정):
- `.individual` (iOS 16+): 여러 개의 앱이 동시 승인 가능. iCloud 로그아웃/앱 삭제에 대한 암묵적 제약이 **걸리지 않음**. 락인 포커스는 이 모드를 써야 함.
- `.child`: 한 기기에 1개 앱만 승인. Family Sharing + 부모 Apple ID 인증. 부모 관리용 앱이 아니므로 본 프로젝트 대상 아님.

**권한 상태 체크**:
```swift
let status = AuthorizationCenter.shared.authorizationStatus
// .notDetermined / .denied / .approved
```
(경험적: `AuthorizationStatus` enum 존재는 커뮤니티 예제에서 일관됨)

**실패 모드** (추정):
- 디바이스가 Family Sharing에 child로 이미 등록된 경우 `.individual` 요청 실패 가능.
- 스크린타임 패스코드가 걸려있고 본인이 모르는 경우(부모 제어 중) 차단.
- **시뮬레이터에서는 대부분 실패 또는 제한됨** — 실기기 테스트 필수.

#### 1.1.2 Entitlement 신청

- **개발용**: Xcode에 "Family Controls" capability 추가 시 `com.apple.developer.family-controls` entitlement가 자동 발급됨. 자신의 팀 provisioning으로 실기기 설치/테스트 가능. (근거: `docs/01_Xcode_Setup_Guide.md`, Apple Developer 문서 관행)
- **배포용**: App Store 배포 시 Apple에 별도 신청 필요 — `https://developer.apple.com/contact/request/family-controls-distribution`. 승인까지 수 일~수 주 (경험적). 이유·사용 목적·앱 설명 기재 필요. **설계/UI 구현 병행하면서 신청 권장**.

### 1.2 FamilyActivityPicker 와 불투명 토큰 (ApplicationToken / ActivityCategoryToken)

#### 1.2.1 토큰의 정체 (근거: WWDC21 "Meet the Screen Time API")

- `FamilyActivityPicker`는 SwiftUI 모달. 사용자에게 **자기 기기에 설치된 앱/웹사이트/카테고리**를 Apple이 보여주고, 선택한 것들을 `FamilyActivitySelection` 으로 돌려줌.
- 선택 결과에는 세 가지 토큰 집합이 들어있음:
  - `applicationTokens: Set<ApplicationToken>`
  - `categoryTokens: Set<ActivityCategoryToken>`
  - `webDomainTokens: Set<WebDomainToken>`
- **토큰은 완전히 불투명(opaque)**. 앱 코드에서 Bundle ID, 이름, 아이콘, 카테고리 이름을 "읽을" API가 **존재하지 않음**. (근거: WWDC21 트랜스크립트 — "no one outside a single Family Sharing group knows what apps/websites are being monitored")

#### 1.2.2 이것이 의미하는 바

- **앱이 "사용자가 Instagram을 골랐는지" 코드로 알 수 없다**. 알 수 있는 것은 토큰의 동등성(Equality)과 Hash, 그리고 SwiftUI 뷰에서 `Label(app)` 형태로 **렌더링만** 가능.
- 즉 "도파민 디톡스: SNS 자동분류" 같은 기능은 **앱이 자체적으로 판단 불가**. 실현 경로는:
  1. 사용자가 FamilyActivityPicker에서 카테고리(예: "Social")를 체크 → 그 토큰을 저장 → Shield에 반영. "반자동".
  2. 앱 내부에서 "SNS 프리셋 가져오기" 버튼을 제공해도, 우리가 토큰 생성을 할 수 없음. 결국 Picker를 띄워 사용자가 직접 체크.
- **결론**: 7.3 도파민 디톡스 모드는 "카테고리 프리셋 안내 UI + 사용자가 Picker에서 체크" 형태로 다운그레이드해야 함.

#### 1.2.3 FamilyActivitySelection 직렬화

- `FamilyActivitySelection`은 `Codable`을 준수 (경험적: 커뮤니티 전역 관행). `JSONEncoder` 로 Data화하여 App Group `UserDefaults` 에 저장 가능.
- **주의**: 토큰은 디바이스 내부 식별자와 결합되어 있으므로, iCloud 동기화 시 기기 간에 의미가 유지되지 않을 수 있음 (추정). MVP는 로컬 저장 전제.

### 1.3 Whitelist(허용 앱) 방식 — API 수준 가능성 평가

#### 1.3.1 문제 정의

사용자 요구: **"허용 앱 N개만 체크 → 나머지 모든 앱 차단"**. Apple의 API는 근본적으로 **blocklist** (차단할 대상을 명시) 구조. 그러나 결정적 단서:

**`ManagedSettingsStore.shield.applicationCategories = .all(except: Set<ApplicationToken>)`** 패턴이 존재 (근거: `ShieldSettings.ActivityCategoryPolicy` 의 `.all` / `.allExcept(_:)` 케이스).

#### 1.3.2 구현 전략: "역-화이트리스트"

```swift
let store = ManagedSettingsStore()
let selection: FamilyActivitySelection // 사용자가 "허용할" 앱들

// 카테고리 전체를 차단하되, 사용자가 선택한 앱은 예외로
store.shield.applicationCategories = .all(except: selection.applicationTokens)
store.shield.webDomainCategories = .all(except: selection.webDomainTokens)
```

이렇게 하면:
- Apple이 분류한 **모든 카테고리의 모든 앱** 이 shield 적용 대상 ← "차단"
- 단, 사용자가 Picker에서 고른 `applicationTokens` 는 예외 ← "허용"

**한계**:
- **카테고리에 분류되지 않은 앱** (시스템 앱, 일부 기본 앱): 차단되지 않을 수 있음 (추정). 실기기 검증 필요.
- **"모든 앱 차단"이 과격**: 전화, 메시지, 설정 등 Apple 기본 앱까지 차단할 가능성 → UX에서 "허용 앱" 기본 세트에 전화/메시지/설정을 포함시키도록 안내.
- 사용자가 선택하지 않은 앱의 토큰을 **우리가 생성할 수 없음** → "허용"만 가능, "차단 대상 목록을 우리가 enumerate"는 불가능. 이 방식이 사실상 유일한 해법.

#### 1.3.3 Fallback (안전장치)

`allExcept`가 기대만큼 동작하지 않는 경우, **Blocklist 방식도 지원**:
```swift
store.shield.applications = selection.applicationTokens  // 차단 대상
store.shield.applicationCategories = .specific(selection.categoryTokens)
```
→ UX에서 "Whitelist / Blocklist 모드 토글"을 설정 화면에 제공 (확장 단계). MVP는 Whitelist 고정 + `allExcept` 전략.

### 1.4 "카테고리 자동분류" (7.3 도파민 디톡스)

- Apple 카테고리는 **App Store 카테고리**에 기반 (Games, Social Networking, Entertainment 등). `FamilyActivityPicker` UI는 사용자에게 카테고리 섹션으로 보여줌 (근거: WWDC21).
- 앱 코드에서 "이 사용자 디바이스에 설치된 SNS 앱을 자동으로 고르기"는 **불가**. 이유: (a) 설치 앱 enumerate API 없음, (b) 토큰 불투명.
- **현실적 UX 경로**:
  1. 온보딩 또는 설정에서 "도파민 디톡스 프리셋" 설명 화면 표시.
  2. 버튼 탭 → `FamilyActivityPicker` 모달 오픈, "사용자가 직접 Social Networking 카테고리 체크" 유도.
  3. 결과 저장.
- UX Designer에게 이 한계를 공유해야 함 (§7 참조).

### 1.5 Shield 커스터마이징 한계

#### 1.5.1 ShieldConfiguration Extension

Shield가 표시될 때, 앱의 **별도 Extension**(ShieldConfigurationExtension)이 호출되어 어떤 UI를 보여줄지 결정. 반환 타입은 `ShieldConfiguration` 구조체이며, 아래 필드들만 설정 가능 (경험적 + 추정):

- `backgroundBlurStyle: UIBlurEffect.Style?` — 배경 블러 스타일
- `backgroundColor: UIColor?` — 배경색
- `icon: UIImage?` — 중앙 아이콘
- `title: ShieldConfiguration.Label` — 제목 (텍스트 + 색상)
- `subtitle: ShieldConfiguration.Label` — 부제
- `primaryButtonLabel: ShieldConfiguration.Label?` — 주 버튼 라벨
- `primaryButtonBackgroundColor: UIColor?`
- `secondaryButtonLabel: ShieldConfiguration.Label?` — 보조 버튼 라벨

**핵심 제약**:
- **완전 커스텀 SwiftUI 뷰 불가**. UIKit/SwiftUI 뷰를 그려 넣을 수 없음. 정해진 필드만 채운다.
- 이미지, 텍스트 2줄, 버튼 2개가 한계. 애니메이션/카운트다운/입력 폼 불가.
- 확장은 **on-demand**로 실행됨. 메모리·시간 제한 있음 (정확치는 비공개/추정; Extension 일반 기준 수 MB, 수 초).

#### 1.5.2 ShieldConfigurationDataProvider 메서드 (경험적)

```swift
class MyShieldConfigDataProvider: ShieldConfigurationDataProvider {
    override func configuration(shielding application: Application) -> ShieldConfiguration { ... }
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration { ... }
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration { ... }
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration { ... }
}
```

### 1.6 "중간 인터셉트 UI" 실현 경로 — 정직한 평가

요구사항: 앱을 열려는 "찰나"에 Shield 대신 우리 앱의 10초 지연 화면을 보여주기.

#### 옵션 (a) ShieldAction Extension → 딥링크로 메인 앱 열기 ← **유일한 현실 경로**

```swift
class MyShieldActionExtension: ShieldActionDelegate {
    override func handle(action: ShieldAction,
                         for application: ApplicationToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // "10초 생각하기" 또는 "정말 열래요?" 버튼
            // 딥링크로 메인 앱 열기 + App Group에 "intercept 요청" 기록
            completionHandler(.defer) // 또는 .close
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }
}
```

- Shield 화면에 **"잠깐, 10초만"** 버튼 → 탭 시 메인 앱으로 URL Scheme 이동 → 거기서 호흡/카운트다운 UI.
- `.defer` 는 "잠시 Shield를 해제하여 사용자 작업을 이어가게 허용", `.close` 는 "Shield 유지하고 닫기".
- **주의**: 사용자의 "원래 열려던 앱"으로 돌아가려면 `.defer` 후 그 앱을 직접 탭해야 함. iOS는 임의 앱 런칭 불가.

#### 옵션 (b) DeviceActivityMonitor 이벤트 훅 → 실시간 인터셉트?

- `eventDidReachThreshold` 가 특정 앱 사용 시간이 임계에 도달했을 때 호출됨. 그러나 이것은 "사용 중일 때" 발화되며 **"사용 직전"은 아님**.
- 이 콜백 안에서 앱을 열 수 있는 API는 **없음**. 할 수 있는 것: Shield를 동적으로 적용/해제, 로컬 노티 발송. 즉 "인터셉트"는 불가, "사용 후 경고"는 가능.

#### 옵션 (c) 앱 포그라운드 강제 전환

- **불가능**. iOS 보안 모델상 한 앱이 다른 앱을 포그라운드로 끌어올릴 수 없음.

#### 결론

"10초 지연 개입"의 실제 흐름은:
```
사용자가 Instagram 탭
  → iOS가 Shield 화면 표시 (우리의 ShieldConfiguration: "멈춰. 정말 열래요?")
    → 사용자가 "10초 생각하기" 버튼 탭
      → ShieldAction Extension 실행
        → App Group에 "intercept 요청" 기록 + 메인 앱으로 딥링크
          → 메인 앱의 InterceptView 표시 (10초 카운트다운, 호흡, 목표 리마인드)
            → 10초 후 "그래도 열기" / "안 열기" 버튼
              → "그래도 열기": Shield 임시 해제 (일정 시간) 후 사용자가 직접 Instagram 재탭
              → "안 열기": Shield 유지
```

**UX적 대가**: 사용자가 Shield를 반드시 한 번 본다. 완전 무봉합(seamless) 인터셉트는 불가. UX Designer와 조율 필요 (§7).

### 1.7 DeviceActivityMonitor 이벤트

`DeviceActivityMonitorExtension` 의 콜백 (근거: WWDC21 + 경험적):

```swift
class LockinMonitor: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) { ... }
    override func intervalDidEnd(for activity: DeviceActivityName) { ... }
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                         activity: DeviceActivityName) { ... }
    override func intervalWillStartWarning(for activity: DeviceActivityName) { ... }
    override func intervalWillEndWarning(for activity: DeviceActivityName) { ... }
    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name,
                                                 activity: DeviceActivityName) { ... }
}
```

#### 1.7.1 스케줄과 임계값 패턴

```swift
let schedule = DeviceActivitySchedule(
    intervalStart: DateComponents(hour: 9, minute: 0),
    intervalEnd:   DateComponents(hour: 18, minute: 0),
    repeats: true
)

let event = DeviceActivityEvent(
    applications: selection.applicationTokens,
    threshold: DateComponents(minute: 15)
)

let center = DeviceActivityCenter()
try center.startMonitoring(
    DeviceActivityName("LockinFocusWorkHours"),
    during: schedule,
    events: [.init("LockinThreshold15min"): event]
)
```

- `intervalDidStart` 에 Shield 적용, `intervalDidEnd` 에 Shield 해제.
- `eventDidReachThreshold` 로 "N분 써도 되던 앱" 같은 추가 규칙.

#### 1.7.2 Extension 제약

- Extension은 Apple이 필요할 때 호출하며, 메모리·시간 제한이 있음 (추정: 수 MB, 수 초). **무거운 로직은 메인 앱에**, Extension은 "Shield 적용/해제 + 로그 쓰기"만.
- App Group `UserDefaults` / shared file 외에는 메인 앱과 통신 수단 제한적 (Darwin notification 가능하나 복잡).

### 1.8 Background Modes / 배터리 영향

- DeviceActivity Extension은 Apple 스케줄러가 호출 → 우리가 임의 주기로 돌리는 것이 아님. 배터리 영향 **적음** (경험적).
- Background fetch / Background processing 은 **통계 집계, 주간 리포트 생성** 등 확장 기능에 사용. MVP는 불필요.
- Shield 적용/해제는 즉시성이 있으므로 별도 백그라운드 모드 없이 Extension 콜백에서 수행.

### 1.9 Entitlement 신청 프로세스

| 단계 | 개발용 | 배포용 |
|---|---|---|
| 자격 | 유료 Apple Developer 계정 | 좌동 + 앱 상세 설명 |
| 발급 | Xcode Capabilities에 추가 → 자동 | `developer.apple.com/contact/request/family-controls-distribution` 폼 제출 |
| 소요 | 즉시 | 수 일 ~ 수 주 |
| 범위 | 개발 provisioning에서만 유효 | App Store 배포 번들에 포함 |

**전략**: Xcode 세팅 → 개발용 entitlement 즉시 확보하여 구현 진행 + 배포용은 UX/MVP 완성 단계에 맞춰 병행 신청.

---

## 2. 모듈 / 타깃 구조

### 2.1 타깃 구성

```
LockinFocus.xcodeproj
├── LockinFocus                          (메인 앱, iOS 16+)
│   └── Entitlements: family-controls, app-groups
├── DeviceActivityMonitorExtension       (DA Monitor Extension)
│   └── Entitlements: family-controls, app-groups
├── ShieldConfigurationExtension         (Shield UI Extension)
│   └── Entitlements: family-controls, app-groups
├── ShieldActionExtension                (Shield 버튼 동작 Extension)
│   └── Entitlements: family-controls, app-groups
├── LockinFocusTests                     (단위 테스트)
└── LockinFocusUITests                   (UI 테스트)
```

App Group: `group.com.imurmkj.LockinFocus` — 모든 타깃이 공유.

### 2.2 폴더 구조 (제안)

```
LockinFocus/
├── App/
│   ├── LockinFocusApp.swift          # @main
│   ├── RootView.swift                # 권한 상태별 루트 라우팅
│   └── AppDelegate.swift             # 딥링크 수신
├── Features/
│   ├── Onboarding/
│   │   ├── OnboardingFlow.swift
│   │   ├── PermissionStep.swift
│   │   └── WhitelistIntroStep.swift
│   ├── AppSelection/
│   │   ├── AppSelectionView.swift    # FamilyActivityPicker 래핑
│   │   └── AppSelectionViewModel.swift
│   ├── Schedule/
│   │   ├── ScheduleEditorView.swift
│   │   └── ScheduleViewModel.swift
│   ├── Intercept/
│   │   ├── InterceptView.swift       # 10초 카운트다운
│   │   ├── InterceptViewModel.swift
│   │   └── Variants/                 # 확장: 호흡, 문장입력, 타이머
│   │       ├── BreathVariant.swift
│   │       ├── CountdownVariant.swift
│   │       └── SentenceVariant.swift
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   └── FocusScoreCard.swift
│   └── Settings/
│       └── SettingsView.swift
├── Core/
│   ├── BlockingEngine/
│   │   ├── BlockingEngine.swift      # ManagedSettings 래퍼
│   │   └── ShieldPolicy.swift        # .allExcept / .specific 정책
│   ├── MonitoringEngine/
│   │   ├── MonitoringEngine.swift    # DeviceActivityCenter 래퍼
│   │   └── ScheduleModel.swift
│   ├── Authorization/
│   │   └── AuthorizationService.swift
│   ├── Persistence/
│   │   ├── PersistenceStore.swift
│   │   ├── SharedDefaults.swift      # App Group UserDefaults
│   │   └── Models/
│   │       ├── StoredSelection.swift # FamilyActivitySelection Codable 래퍼
│   │       ├── StoredSchedule.swift
│   │       └── FocusRecord.swift     # 집중 점수 이력
│   ├── DeepLink/
│   │   └── DeepLinkRouter.swift      # lockin://intercept?token=...
│   └── Theme/
│       ├── AppColors.swift           # 흰색 기반 팔레트
│       ├── AppTypography.swift
│       └── AppSpacing.swift
└── Shared/                           # 세 Extension 타깃에 멤버십 추가
    ├── Constants/
    │   ├── AppGroupID.swift          # "group.com.imurmkj.LockinFocus"
    │   └── SharedKeys.swift          # UserDefaults 키 모음
    ├── Models/
    │   └── InterceptRequest.swift    # Codable, Extension↔App 통신용
    └── Utilities/
        └── SharedLogger.swift        # 공통 로깅

DeviceActivityMonitorExtension/
├── DeviceActivityMonitorExtension.swift  # class LockinMonitor: DeviceActivityMonitor
└── Info.plist

ShieldConfigurationExtension/
├── ShieldConfigurationDataProvider.swift # configuration(shielding:) 4종
└── Info.plist

ShieldActionExtension/
├── ShieldActionDelegate.swift        # handle(action:for:completionHandler:)
└── Info.plist
```

### 2.3 의존성 다이어그램

```
┌─────────────────────────────────────────────────────┐
│                   메인 앱 (UI)                      │
│  Onboarding · AppSelection · Schedule · Intercept   │
│  Dashboard · Settings                               │
└──────┬────────────┬─────────────┬───────────────────┘
       │            │             │
       ▼            ▼             ▼
┌──────────┐ ┌───────────┐ ┌──────────────┐
│Blocking  │ │Monitoring │ │Authorization │
│ Engine   │ │  Engine   │ │   Service    │
└────┬─────┘ └─────┬─────┘ └──────────────┘
     │             │
     ▼             ▼
┌─────────────────────────┐
│  PersistenceStore       │◄─────── Shared/Constants
│  (SharedDefaults)       │         Shared/Models
└──────────┬──────────────┘
           │ App Group UserDefaults
           │ (group.com.imurmkj.LockinFocus)
           │
    ┌──────┴────────┬──────────────┐
    ▼               ▼              ▼
┌─────────┐   ┌──────────┐   ┌────────────┐
│DAMonitor│   │ Shield   │   │Shield      │
│Extension│   │ Config   │   │Action      │
│         │   │Extension │   │Extension   │
└─────────┘   └──────────┘   └──────┬─────┘
                                    │ URL Scheme
                                    │ lockin://intercept?...
                                    ▼
                             메인 앱 재진입
```

### 2.4 메인 ↔ Extension 통신 (데이터 공유 방식)

| 채널 | 사용 목적 | 신뢰도 |
|---|---|---|
| **App Group `UserDefaults`** | FamilyActivitySelection, 스케줄, 플래그 (엄격 모드 on/off 등), 인터셉트 요청 큐 | 1순위, 즉시 반영 |
| **App Group 공유 파일** | 대용량/구조적 로그 (집중 기록, 주간 집계) | 2순위, 확장 단계 |
| **URL Scheme (딥링크)** | Shield Action → 메인 앱 포그라운드 전환 | 유일한 Extension→App 활성화 수단 |
| **Darwin Notification** | 실시간 신호 (메인 앱이 떠있을 때 Extension에서 푸시) | 선택, MVP 불필요 |

**원칙**:
- Extension은 **읽기 위주, 작은 쓰기**. 무거운 연산·UI 렌더 금지.
- 메인 앱은 **쓰기 + 집계**. Extension이 쓴 작은 이벤트를 주기적으로 흡수하여 SwiftData 등으로 구조화.

### 2.5 어느 로직이 어디에?

| 로직 | 위치 | 이유 |
|---|---|---|
| `AuthorizationCenter.requestAuthorization` | 메인 앱 | UI 컨텍스트 필요 |
| `ManagedSettingsStore.shield = ...` | **양쪽 모두 가능** | 메인 앱에서도 적용, Extension에서도 스케줄 트리거 시 적용 |
| `DeviceActivityCenter.startMonitoring` | 메인 앱 | 사용자가 스케줄 저장 시 호출 |
| DAMonitor 콜백 핸들링 (interval start/end) | DAMonitor Extension | Apple이 호출 |
| Shield 화면 구성 (텍스트/아이콘) | ShieldConfig Extension | Apple이 호출 |
| Shield 버튼 탭 처리 | ShieldAction Extension | Apple이 호출 |
| Intercept UI (10초) | 메인 앱 | 풀 SwiftUI UX 필요 |
| 통계 집계, 그래프 | 메인 앱 | 메모리 여유 |

---

## 3. 상태 관리

### 3.1 저장해야 할 상태 목록

| 상태 | 자료형 | 위치 | 설명 |
|---|---|---|---|
| 권한 상태 | `AuthorizationStatus` | 휘발 (AuthorizationCenter.shared가 소스 오브 트루스) | 매 실행 시 체크 |
| 허용 앱 선택 | `FamilyActivitySelection` (Codable) | App Group UserDefaults | Picker 결과 |
| 스케줄 | `[StoredSchedule]` (Codable) | App Group UserDefaults | 시작/종료 시간, 반복 요일 |
| 엄격 모드 플래그 | `Bool` | App Group UserDefaults | 확장 기능 |
| 지연 해제 단계 | `Int` (1,2,3…) | App Group UserDefaults | 확장 |
| 인터셉트 요청 큐 | `[InterceptRequest]` (Codable) | App Group UserDefaults | Action→App 통신 |
| 집중 점수 이력 | `[FocusRecord]` | MVP: UserDefaults / 확장: SwiftData | 일별 점수·시도 횟수 |
| 온보딩 완료 | `Bool` | `@AppStorage` (메인 앱 로컬) | 확장 타깃과 공유 불필요 |

### 3.2 저장소 선택

| 옵션 | 장 | 단 | 판정 |
|---|---|---|---|
| `@AppStorage` | SwiftUI 바인딩 간결 | 기본 UserDefaults (Extension과 공유 어려움) | **메인 앱 전용 로컬 값** (온보딩 플래그 등) |
| App Group `UserDefaults(suiteName:)` | Extension 공유 가능, 빠름, Codable 직렬화 간편 | 구조화 쿼리 불가 | **MVP 핵심 저장소** |
| SwiftData (iOS 17+) | 관계/쿼리/마이그레이션 강력 | iOS 16 배제, App Group 공유 세팅 복잡 | **확장 단계** (주간 리포트 그래프) |
| CoreData | 성숙, App Group 공유 가능 | 보일러플레이트 많음 | 필요 시 SwiftData 대신 대체 |

**판정**: MVP는 **`UserDefaults(suiteName: "group.com.imurmkj.LockinFocus")` + Codable** 단일 전략. iOS 17+ 지원이 확정되면 SwiftData로 리포트 확장.

### 3.3 공유 키 정의 (Shared/Constants/SharedKeys.swift)

```swift
enum SharedKeys {
    static let selection           = "selection.v1"
    static let schedules           = "schedules.v1"
    static let strictModeEnabled   = "strictMode.enabled.v1"
    static let unlockStage         = "unlock.stage.v1"
    static let interceptQueue      = "intercept.queue.v1"
    static let focusRecords        = "focus.records.v1"
    static let lastInterceptAt     = "intercept.lastAt.v1"
}

enum AppGroupID {
    static let value = "group.com.imurmkj.LockinFocus"
}
```

버전 접미사(`.v1`)로 향후 스키마 마이그레이션 대비.

---

## 4. 핵심 컴포넌트 설계

### 4.1 AuthorizationService

```swift
@MainActor
final class AuthorizationService: ObservableObject {
    @Published private(set) var status: AuthorizationStatus = .notDetermined

    func refresh() {
        status = AuthorizationCenter.shared.authorizationStatus
    }

    /// iOS 16+ 개인 모드. 에러는 UI에서 분기 처리.
    func requestIndividual() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        refresh()
    }
}
```

- 의존성: `FamilyControls`.
- 책임: 권한 요청·갱신만. 정책 판단은 상위 ViewModel.

### 4.2 BlockingEngine

```swift
protocol BlockingEngineProtocol {
    func applyWhitelist(_ selection: FamilyActivitySelection)
    func applyBlocklist(_ selection: FamilyActivitySelection)
    func clear()
}

final class BlockingEngine: BlockingEngineProtocol {
    private let store = ManagedSettingsStore(named: .lockinPrimary)

    /// 역-화이트리스트: 모든 카테고리 차단, 선택 앱 예외.
    func applyWhitelist(_ selection: FamilyActivitySelection) {
        store.shield.applicationCategories = .all(except: selection.applicationTokens)
        store.shield.webDomainCategories   = .all(except: selection.webDomainTokens)
        // 개별 앱 차단은 사용하지 않음 (whitelist 전략)
        store.shield.applications = nil
        store.shield.webDomains   = nil
    }

    /// 대안: 사용자가 고른 것만 차단 (설정에서 모드 전환 시).
    func applyBlocklist(_ selection: FamilyActivitySelection) {
        store.shield.applications        = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
        store.shield.webDomains          = selection.webDomainTokens
        store.shield.webDomainCategories = .none
    }

    func clear() { store.clearAllSettings() }
}

extension ManagedSettingsStore.Name {
    static let lockinPrimary = Self("com.imurmkj.LockinFocus.primary")
}
```

- 의존성: `ManagedSettings`, `FamilyControls`.
- 책임: Shield 상태 적용/해제만. 스케줄 로직 없음.
- 명명된 Store를 사용하여 향후 "집중/휴식" 2개 store 분리 가능성 대비.

### 4.3 MonitoringEngine

```swift
struct FocusSchedule: Codable, Hashable, Identifiable {
    let id: UUID
    let name: String
    let startHour: Int; let startMinute: Int
    let endHour: Int;   let endMinute: Int
    let weekdays: Set<Int>   // 1=일 … 7=토
    let thresholdMinutes: Int?
}

protocol MonitoringEngineProtocol {
    func start(_ schedule: FocusSchedule,
               selection: FamilyActivitySelection) throws
    func stop(_ scheduleID: UUID)
    func stopAll()
}

final class MonitoringEngine: MonitoringEngineProtocol {
    private let center = DeviceActivityCenter()

    func start(_ schedule: FocusSchedule,
               selection: FamilyActivitySelection) throws {
        let daSchedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: schedule.startHour,
                                          minute: schedule.startMinute),
            intervalEnd:   DateComponents(hour: schedule.endHour,
                                          minute: schedule.endMinute),
            repeats: true
        )

        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        if let t = schedule.thresholdMinutes {
            events[.init("threshold_\(schedule.id.uuidString)")] =
                DeviceActivityEvent(
                    applications: selection.applicationTokens,
                    threshold: DateComponents(minute: t)
                )
        }

        try center.startMonitoring(
            DeviceActivityName(schedule.id.uuidString),
            during: daSchedule,
            events: events
        )
    }

    func stop(_ scheduleID: UUID) {
        center.stopMonitoring([DeviceActivityName(scheduleID.uuidString)])
    }

    func stopAll() { center.stopMonitoring() }
}
```

- 의존성: `DeviceActivity`, `FamilyControls`.
- 책임: 스케줄 시작/중지만. 콜백 수신은 DAMonitorExtension 쪽.

### 4.4 InterceptPresenter (메인 앱)

```swift
enum InterceptVariant: String, Codable {
    case countdown   // 기본: 10초 카운트다운
    case breath      // 호흡 4-7-8
    case sentence    // "왜 지금 열려고 하나요?" 한 문장 입력
    case goalRemind  // 오늘의 집중 목표 상기
}

struct InterceptRequest: Codable, Identifiable {
    let id: UUID
    let receivedAt: Date
    let applicationTokenData: Data?  // ApplicationToken을 Codable 직렬화
    let sourceHint: String?          // "shield_primary_button" 등
}

@MainActor
final class InterceptPresenter: ObservableObject {
    @Published var activeRequest: InterceptRequest?
    @Published var variant: InterceptVariant = .countdown

    private let store: PersistenceStoreProtocol

    init(store: PersistenceStoreProtocol) { self.store = store }

    /// 딥링크 수신 시 호출.
    func present(from url: URL) {
        guard let request = DeepLinkRouter.parseIntercept(url) else { return }
        variant = pickVariant()
        activeRequest = request
    }

    func dismiss(confirmed: Bool) {
        // confirmed == true: 사용자가 "그래도 열기" → Shield 임시 해제 로직 트리거
        // confirmed == false: "안 열기" → 집중 점수 +1 기록
        store.appendFocusRecord(.init(at: Date(), confirmed: confirmed))
        activeRequest = nil
    }

    private func pickVariant() -> InterceptVariant {
        // MVP: .countdown 고정. 확장: 랜덤/규칙 기반.
        .countdown
    }
}
```

### 4.5 PersistenceStore

```swift
protocol PersistenceStoreProtocol {
    var selection: FamilyActivitySelection? { get set }
    var schedules: [FocusSchedule] { get set }
    var strictModeEnabled: Bool { get set }
    func appendFocusRecord(_ record: FocusRecord)
    func fetchFocusRecords(range: ClosedRange<Date>) -> [FocusRecord]
    func enqueueIntercept(_ request: InterceptRequest)
    func dequeueIntercepts() -> [InterceptRequest]
}

final class PersistenceStore: PersistenceStoreProtocol {
    private let defaults: UserDefaults

    init(defaults: UserDefaults =
         UserDefaults(suiteName: AppGroupID.value)!) {
        self.defaults = defaults
    }

    var selection: FamilyActivitySelection? {
        get { decode(SharedKeys.selection) }
        set { encode(newValue, SharedKeys.selection) }
    }
    // ... 나머지 동일 패턴
}
```

- 의존성: `Foundation`, `FamilyControls` (FamilyActivitySelection의 Codable 보장 필요).
- 책임: 직렬화·역직렬화 + App Group UserDefaults 접근 단일화.

### 4.6 ShieldConfigurationExtension

```swift
class LockinShieldConfigProvider: ShieldConfigurationDataProvider {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: .white,
            icon: UIImage(named: "LockinShieldIcon"),
            title: .init(text: "잠깐, 멈춰요",
                         color: .black),
            subtitle: .init(text: "10초만 생각해볼까요?",
                            color: UIColor(white: 0.35, alpha: 1)),
            primaryButtonLabel: .init(text: "10초 생각하기",
                                      color: .white),
            primaryButtonBackgroundColor: UIColor(red: 0.10, green: 0.10,
                                                   blue: 0.12, alpha: 1),
            secondaryButtonLabel: .init(text: "닫기",
                                        color: UIColor(white: 0.25, alpha: 1))
        )
    }
    // configuration(shielding: in category:), configuration(shielding: WebDomain)
    // 3종 모두 유사하게 구현.
}
```

### 4.7 ShieldActionExtension

```swift
class LockinShieldAction: ShieldActionDelegate {
    override func handle(action: ShieldAction,
                         for application: ApplicationToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            enqueueInterceptRequest(for: application)
            openMainApp()
            completionHandler(.defer)
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    private func enqueueInterceptRequest(for token: ApplicationToken) {
        let data = try? JSONEncoder().encode(token)
        let req = InterceptRequest(id: UUID(),
                                   receivedAt: Date(),
                                   applicationTokenData: data,
                                   sourceHint: "shield_primary")
        var q = /* UserDefaults에서 읽기 */
        q.append(req)
        /* UserDefaults에 쓰기 */
    }

    private func openMainApp() {
        // Extension에서 UIApplication.shared.open 불가 → URL 스킴 기록만 남기고
        // 사용자가 .defer 응답 후 자연스레 홈 화면으로 돌아갈 때
        // push notification or "앱 열기 안내"로 유도.
        // 대안: NSExtensionContext.open(_:) 사용 (ShieldActionExtension이 지원하는지 확인 필요 — 추정)
    }
}
```

**중요 제약**: ShieldAction Extension에서 직접 메인 앱을 띄우는 공식 API는 제한적. `NSExtensionContext.open(_:)`을 사용 가능한 경우가 있으나 (추정) 검증 필요. 실패 시 대안:
- 로컬 노티피케이션 발송 → 사용자가 노티 탭 → 메인 앱 열림.
- `.defer` 후 홈 화면 복귀 → 사용자가 직접 메인 앱 탭 (UX 손실).

이 부분은 **실기기 검증 필수**. Debugger 에이전트의 최우선 점검 대상 (§7에 명시).

---

## 5. MVP 구현 단계 (Coder 착수용)

| # | 단계 | 산출물 | DoD (완료 기준) |
|---|---|---|---|
| 1 | Feature 폴더 트리 & 타깃 멤버십 정리 | `docs/01` 가이드의 폴더 구조 생성, Shared/ 는 Extension 3개에도 Target Membership 체크 | Xcode에서 빌드 성공 (`⌘B`) |
| 2 | Theme/AppColors | `AppColors.swift` (white/black/gray 3단 계조), `AppTypography.swift`, `AppSpacing.swift` | `Color.appBackground` 등 5개 이상 토큰 접근 가능 |
| 3 | PersistenceStore | App Group UserDefaults 래퍼, Codable 저장, InterceptRequest 큐 | 단위 테스트: 값 쓰고 읽기 round-trip 통과 |
| 4 | AuthorizationService | `.individual` 요청, 상태 observable | 실기기에서 권한 다이얼로그 노출 + `.approved` 수신 |
| 5 | AppSelectionView | `FamilyActivityPicker` 래핑, 선택 결과를 PersistenceStore에 저장 | 앱 3개 이상 선택 → 재실행 시 복원 |
| 6 | BlockingEngine | `applyWhitelist` 구현, `clear` | 선택 저장 후 applyWhitelist 호출 → 미선택 앱 실행 시 Shield 표시 |
| 7 | ScheduleEditor + MonitoringEngine | 시간 설정 UI, DeviceActivityCenter.startMonitoring 연동 | 테스트용 1분 스케줄 시작/종료 시 Shield on/off 확인 |
| 8 | Shield Extensions (Config + Action) | 지정된 ShieldConfiguration 반환, primary 버튼 → 딥링크 | 실기기에서 Shield 커스텀 문구 확인, 버튼 탭 → 메인 앱 Intercept 뷰 노출 |
| 9 | InterceptView (10초 카운트다운) | 카운트다운 UI, "그래도 열기"/"안 열기" | 10초 후 버튼 활성화, 선택 시 FocusRecord 기록 |
| 10 | Onboarding + Dashboard | 4단계 온보딩, 홈 카드 3개 (오늘 점수, 허용 앱 수, 다음 스케줄) | 첫 실행 시 온보딩, 완료 시 홈 진입 |

**우선순위**: 1→4→5→6 경로가 최소 기동. 7~9는 병렬 가능. 10은 마지막.

---

## 6. API 레벨에서 불가능/위험한 아이디어 (정직한 평가)

| 사용자 아이디어 | 판정 | 근거 / 대안 |
|---|---|---|
| "완전 강제 차단" (사용자가 절대 끌 수 없음) | **불가** | Apple은 사용자의 앱 삭제·권한 취소·스크린타임 패스코드 해제를 OS 수준에서 보장. 우리가 막을 수단 없음. 대안: 엄격 모드(지연/문장 입력) 로 심리적 장벽만 추가 |
| SNS 자동분류 (우리 앱이 판단) | **불가** | ActivityCategoryToken 불투명 + 설치 앱 enumerate 불가. 대안: 사용자가 Picker에서 카테고리 체크 (반-자동) |
| Shield 앞에 항상 우리 커스텀 풀뷰 인터셉트 삽입 | **불가** | Apple은 Shield를 먼저 띄운다. 우리는 Shield UI를 정해진 필드로 꾸미고, ShieldAction → 딥링크로 메인 앱 유도만 가능 |
| 앱 포그라운드 강제 전환 | **불가** | iOS 보안 모델 |
| 다른 앱의 사용 시간 실시간 조회 (초 단위) | **제한적** | DeviceActivity 임계 이벤트로 근사. 초 단위 실시간 스트림 API 없음 |
| 카운트다운을 Shield 안에서 (Shield 스스로 10초 지연) | **불가** | ShieldConfiguration은 정적. 동적 UI 불가 |
| 시뮬레이터에서 전체 플로우 동작 | **부분 불가** | Shield, DeviceActivity 콜백 대부분 실기기 필요 |
| 사용자 토큰을 iCloud 로 다기기 동기화 | **위험** | 토큰이 디바이스 결합. 동일 의미 보장 불확실 |
| "Instagram 30분 사용 시 자동 블록" — 사용 직후 즉시 | **가능하나 지연** | `eventDidReachThreshold` 콜백은 Apple 스케줄. 수 초~수 분 지연 있을 수 있음 (경험적) |
| 친구 경쟁 (7.4) | **가능하나 복잡** | 서버 필요 + 토큰 공유 불가(프라이버시 모델 위반). "집중 시간"만 숫자로 공유 가능 |

---

## 7. UX Designer와 조율해야 할 항목

병렬로 `docs/02_UX_Design.md`를 작성 중인 UX Designer 에이전트에게 **반드시 확인** 해야 할 의제. 과학적 토론을 위해 "질문 + 우리 제안" 형태로.

1. **Shield 화면 = "1차 인터셉트"로 수용 가능한가?** 완전 무봉합(seamless) 인터셉트는 불가. Shield를 먼저 본 뒤 사용자가 "10초 생각하기" 버튼을 탭해야 우리 앱이 열림. Shield 자체를 "1차 개입 UI" 로 디자인하는 방향을 제안. (질문: 이 흐름으로 UX 스토리보드 수정 가능한가?)

2. **Shield 디자인 필드 한계** 공유. 텍스트 2줄 + 아이콘 1개 + 버튼 2개. 이 제약 안에서 "흰색 기반, 따뜻한 문구"를 어떻게 표현할지 문구 후보 5세트 요청.

3. **허용 앱(Whitelist) 최소 세트**. `.all(except:)` 전략은 시스템 앱(전화/메시지/설정)까지 차단할 수 있음. 온보딩 첫 스텝에서 "전화·메시지·설정·시계"를 기본 허용으로 추가하도록 UX 가이드 필요. 사용자 동의 문구 초안 요청.

4. **도파민 디톡스 프리셋 UX**. 앱 자동분류 불가 → 사용자가 Picker에서 직접 "Social Networking" 카테고리를 체크. 이 과정을 친숙하게 만들 **설명 카드 문구**가 필요.

5. **"그래도 열기"의 UX 무게**. 10초 후 "그래도 열기"를 누르면 Shield를 몇 분간 해제할지 (5분/15분), 그 다음 다시 Shield를 건지 결정 필요. 심리학적으로는 "짧은 허용 후 재차단"이 효과적이나 사용자 짜증 가능.

6. **권한 거부 시 UX**. `AuthorizationStatus.denied` 상황의 안내/재시도 화면 설계 요청.

7. **엄격 모드의 시각적 단계**. 알림→반투명→흑백→완전 중 "반투명/흑백" 단계는 Apple API로 직접 구현 불가 (Shield는 정적). 우리 앱 내부에서만 가능. UX Designer에게 "엄격 모드 단계를 Shield 외부(우리 앱·노티) 에서 구현" 원칙 공유.

8. **인터셉트 변형(variant) 우선순위**. countdown / breath / sentence / goalRemind 중 MVP 1종을 무엇으로 할지 (Architect 제안: countdown). 확장 순서 의견 요청.

9. **온보딩 분량**. 권한 설명 + 허용 앱 기본 안내 + 첫 스케줄 설정까지를 몇 스텝으로 나눌지. Architect 제안: 4 스텝 (웰컴 / 권한 / 허용 앱 선택 / 첫 스케줄).

10. **대시보드 첫 화면 구성**. 집중 점수(숫자 1개) + 허용 앱 카드 + 다음 스케줄 카드 — 3요소 구성을 UX가 수용하는지, 추가/삭제 의견.

11. **Debugger와 공동 검증 항목**: ShieldAction Extension에서 메인 앱으로의 "직접 open" 가능 여부. 실기기 테스트 결과에 따라 UX 플로우(노티 경유 vs 직접 오픈)가 달라짐. UX 대안 2세트 준비 요청.

총 **11개 조율 항목**.

---

## 부록 A — 핵심 의사결정 요약

| 결정 | 선택 | 이유 |
|---|---|---|
| iOS 최소 지원 | 16.0 | `.individual` 인증 필수, DeviceActivity 안정화 |
| 저장소 (MVP) | App Group `UserDefaults` + Codable | Extension 공유 간편, 의존성 최소 |
| 저장소 (확장) | SwiftData (iOS 17+) 또는 CoreData | 리포트/그래프 쿼리 |
| 차단 전략 (MVP) | Whitelist (`shield.applicationCategories = .all(except:)`) | 사용자 요구사항 충실 |
| 인터셉트 경로 | Shield → ShieldAction → 메인 앱 딥링크 | 유일한 현실 경로 |
| Extension 타깃 수 | 3 (DA Monitor / Shield Config / Shield Action) | MVP의 모든 인터셉트 경로 커버 |
| 권한 모드 | `.individual` 고정 | 자기관리 앱 |
| 배포용 entitlement | 병행 신청 | 승인 소요 시간 흡수 |

## 부록 B — 미검증·위험 항목 (Debugger가 실기기에서 1순위 검증)

1. `ShieldSettings.ActivityCategoryPolicy.all(except:)` 가 Picker에 나타나지 않는 시스템 앱(전화/메시지)도 제외하는지, 아니면 이들은 애초에 카테고리 차단 대상이 아닌지.
2. ShieldActionExtension에서 메인 앱을 포그라운드로 여는 공식 수단 (`NSExtensionContext.open(_:)` 지원 여부).
3. `eventDidReachThreshold` 의 실제 호출 지연 (분 단위?).
4. App Group UserDefaults의 Extension→App 쓰기 가시성 타이밍.
5. FamilyActivitySelection의 Codable round-trip 안정성.
6. 시뮬레이터 vs 실기기 차이 목록화.

이상.
