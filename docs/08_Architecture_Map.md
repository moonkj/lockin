# 08 — Architecture Map (개발자용 기술 지도)

> 작성: Doc Writer · 2026-04-23
> 목적: [`03_Architecture.md`](03_Architecture.md) 의 큰 설계를 코드 수준으로 요약. 지금 합류한 개발자가 30 분 안에 "어디를 고치면 어디가 깨지는지" 감 잡도록.

---

## 1. Core 레이어 책임 테이블

| 타입 | 파일 | 책임 | 의존성 |
|---|---|---|---|
| `AppDependencies` | `Core/DI/AppDependencies.swift` | 3 엔진 + 1 스토어를 묶는 DI 컨테이너. `ObservableObject` 로 RootView 가 구독. | PersistenceStore, BlockingEngine, MonitoringEngine |
| `AppDependencies.live()` | `Core/DI/AppDependencies+Live.swift` | 시뮬 분기로 Noop 주입, 실기기는 ManagedSettings / DeviceActivity 실구현. | `#if targetEnvironment(simulator)` |
| `PersistenceStore` (protocol) | `Core/Protocols/PersistenceStore.swift` | 상태 저장 추상화. `selection`, `schedule`, `hasCompletedOnboarding`, `interceptQueue`, `drainInterceptQueue()`. | `FamilyControls` |
| `UserDefaultsPersistenceStore` | `Core/Persistence/UserDefaultsPersistenceStore.swift` | App Group UserDefaults 기반 실구현. Extension 이 쓴 `[[String: Any]]` 원시 큐를 `InterceptEvent` 로 디코딩. | App Group |
| `InMemoryPersistenceStore` | `Core/Persistence/InMemoryPersistenceStore.swift` | 테스트/Preview 용 in-memory Fake. | — |
| `BlockingEngine` (protocol) | `Core/Protocols/BlockingEngine.swift` | Shield 적용/해제. `applyWhitelist(for:)`, `clearShield()`, `temporarilyAllow(token:for:)`. | `ManagedSettings`, `FamilyControls` |
| `ManagedSettingsBlockingEngine` | `Core/BlockingEngine/ManagedSettingsBlockingEngine.swift` | `.all(except:)` 역-화이트리스트 적용. `MonitoringEngine` 후주입(`bind(monitoring:)`)으로 순환 회피. | ManagedSettingsStore |
| `NoopBlockingEngine` | `Core/BlockingEngine/NoopBlockingEngine.swift` | 시뮬레이터 분기에서 주입. 모든 메서드가 no-op. | — |
| `MonitoringEngine` (protocol) | `Core/Protocols/MonitoringEngine.swift` | `startSchedule(_:name:)`, `stopMonitoring(name:)`, `startTemporaryAllow(name:duration:)`. | `DeviceActivity` |
| `DeviceActivityMonitoringEngine` | `Core/MonitoringEngine/DeviceActivityMonitoringEngine.swift` | `DeviceActivityCenter` 래퍼. | DeviceActivityCenter |
| `NoopMonitoringEngine` | `Core/MonitoringEngine/NoopMonitoringEngine.swift` | 시뮬레이터용 no-op. | — |
| `Schedule` | `Core/Models/Schedule.swift` | `Codable`. 요일 집합 + 시작/종료 시각 + `isEnabled`. 프리셋: `.weekdayWorkHours`, `.allDay`. | — |
| `InterceptEvent` | `Core/Models/InterceptEvent.swift` | `Codable`. Extension 큐의 디코딩 타겟. `EventType = {returned, interceptRequested}`, `SubjectKind = {application, category, webDomain}`. rawValue 문자열이 Extension 측 dict 와 일치해야 함. | — |
| `AppGroup` / `SharedKeys` | `Core/Shared/AppGroup.swift` | App Group identifier + `FamilyActivitySelection` 직렬화 키. | Foundation |
| `PersistenceKeys` | `Core/Persistence/PersistenceKeys.swift` | 인터셉트 큐(원시/Codable) · 스케줄 · 온보딩 플래그 키. | Foundation |

---

## 2. 데이터 플로우 (Shield → 메인 앱 인터셉트)

```
[사용자가 차단 앱 아이콘 탭]
        │
        ▼
[iOS Shield 화면]
  ShieldConfigurationExtension 이 title/subtitle/button 구성
        │
        │ (사용자가 "10초 기다리고 계속" 탭)
        ▼
[ShieldActionExtension.handle(action:for:completionHandler:)]
        │
        │  enqueue(type: "intercept_requested", subjectKind: "application")
        │  — App Group UserDefaults 의 [[String: Any]] 배열에 append
        │
        │  completionHandler(.defer)
        ▼
[App Group UserDefaults: key "interceptQueue"]
   ┌────────────────────────────────────────┐
   │  [{timestamp: ..., type: ..., ...},    │
   │   {...}]                               │
   └────────────────────────────────────────┘
        │
        │  (사용자가 메인 앱 아이콘을 별도로 탭 — MVP 는 수동 전환)
        ▼
[메인 앱 포그라운드 진입]
  RootView.onAppear / .onChange(scenePhase == .active)
        │
        ▼
[deps.persistence.drainInterceptQueue()]
  UserDefaultsPersistenceStore 가 원시 dict 배열 → [InterceptEvent] 디코딩
  + 큐를 비움
        │
        │  (events.count > 0)
        ▼
[showIntercept = true]
        │
        ▼
[.sheet(isPresented:) → InterceptView]
  10 초 카운트다운 → "돌아가기" | "그래도 열기"
        │
        ├── 돌아가기 ──► interceptQueue.append(.returned) + dismiss
        │
        └── 그래도 열기 ──► blocking.clearShield()
                           + monitoring.startTemporaryAllow(
                               name: "temp_allow_all", duration: 5 min)
                           + dismiss
                           │
                           │  (5 분 경과)
                           ▼
              [DeviceActivityMonitorExtension.intervalDidEnd]
                           │
                           │  activity.rawValue.hasPrefix("temp_allow_") → true
                           ▼
              [applyWhitelistFromStore() → 주 shield 복원]
```

---

## 3. activity 이름 규약

`DeviceActivityName` 문자열이 Extension 과 메인 앱 사이의 **암묵적 계약** 이다.
프리픽스 매칭을 Extension 이 수행하므로 이름 변경은 3 – 5 곳 동시 수정이 필요하다.

| 이름 | 용도 | 쓰는 쪽 | 읽는 쪽 |
|---|---|---|---|
| `block_main` | 주 스케줄 interval. 시작 시 shield 적용, 종료 시 전체 해제. | `OnboardingContainerView.finishOnboarding()`, `DashboardView.save()`, `SettingsView.save()` 가 `monitoring.startSchedule(_, name: "block_main")` | `DeviceActivityMonitorExtension.intervalDidStart/End` 가 `activity.rawValue == "block_main"` 비교 |
| `temp_allow_*` | "그래도 열기" 5 분 일시 해제 타이머. 종료 시 주 shield 복원. | `InterceptView.handleOpenAnyway()` 가 `"temp_allow_all"` 로 호출 | `DeviceActivityMonitorExtension` 가 `hasPrefix("temp_allow_")` 매칭 |

**Phase 4 팀리더 Fix**: 원래 메인 앱이 `"primary"` 로 호출했으나 Extension 은 `"block_main"` 만 인식.
세 파일에서 `"primary"` → `"block_main"` 으로 일괄 수정하여 계약 복원.
**Phase 4 Debugger H4 Fix**: `"tempAllowAll"` → `"temp_allow_all"` 1 글자 수정으로 prefix 매칭 복구.

---

## 4. App Group 키 목록

`group.com.imurmkj.LockinFocus` 공유. 쓰는/읽는 주체가 엇갈리면 즉시 버그.

| 키 | 타입 | 쓰는 쪽 | 읽는 쪽 | 비고 |
|---|---|---|---|---|
| `familySelection` | `Data` (JSON of `FamilyActivitySelection`) | 메인 앱 `UserDefaultsPersistenceStore.selection.set` | 메인 앱 `selection.get`, `DeviceActivityMonitorExtension.readFamilySelection()` | `.all(except:)` 의 예외 집합 소스 오브 트루스 |
| `interceptQueue` | `[[String: Any]]` | `ShieldActionExtensionHandler.enqueue` | `UserDefaultsPersistenceStore.drainInterceptQueue` | 원시 dict 배열. Codable 아님 |
| `interceptQueueCodable` | `Data` (JSON of `[InterceptEvent]`) | 메인 앱 (RootView drain 후 `.returned` append) | 메인 앱 자체 | Codable 누적 로그. Phase 5 리포트용 |
| `schedule` | `Data` (JSON of `Schedule`) | 메인 앱 `persistence.schedule.set` | 메인 앱 | 단일 스케줄. 배열 아님 |
| `hasCompletedOnboarding` | `Bool` | 메인 앱 `OnboardingContainerView.finishOnboarding()` | `RootView.body` (deps 구독) | 온보딩 분기 트리거 |
| `scheduleStart` / `scheduleEnd` / `strictModeActive` / `focusScoreToday` | `Int`/`Bool`/`Int` | 메인 앱 | 메인 앱 | `SharedKeys` 에 선언된 스칼라. `focusScoreToday` 외 현재 사용처 거의 없음(Phase 5 용) |

**Debugger H1 회귀 방지 테스트**:
`UserDefaultsPersistenceStoreTests.testDrainInterceptQueue_decodesExtensionRawFormat` 이
실제 `[[String: Any]]` dict 를 주입해 drain 경로를 계약 고정한다. 필드명(`timestamp`/`type`/`subjectKind`)
혹은 enum rawValue (`"returned"`/`"interceptRequested"`/`"application"`/`"category"`/`"webDomain"`)
가 바뀌면 이 테스트가 즉시 실패한다.

---

## 5. 교차 레이어 경고 박스

> ⚠ **여기를 건드리면 저기가 깨진다**
>
> 1. **`InterceptEvent.EventType` / `SubjectKind` rawValue 변경**
>    → `ShieldActionExtensionHandler.enqueue` 호출부의 문자열 리터럴도 동시 수정 필수.
>    → 테스트 `InterceptEventTests.testRawValueStability_*` 가 실패해서 알려준다.
>
> 2. **`AppGroup.identifier` 변경**
>    → `ShieldActionExtension/ExtensionAppGroup.swift` +
>    `DeviceActivityMonitorExtension.swift` private enum 2 곳 동시 수정.
>    → entitlement 파일 4 개 (`LockinFocus.entitlements` + 3 Extension entitlements) 의
>    App Group id 도 동시 수정. Apple Developer Portal 의 App Group 등록도 재설정 필요.
>
> 3. **`PersistenceKeys.rawInterceptQueue = "interceptQueue"` 문자열 변경**
>    → `ShieldActionExtension/ExtensionAppGroup.swift::SharedKeys.interceptQueue` 도 동시 수정.
>    → 테스트 `testDrainInterceptQueue_decodesExtensionRawFormat` 이 실패.
>
> 4. **activity 이름 규약 변경** (`block_main` / `temp_allow_` prefix)
>    → 메인 앱 호출부 3 곳 + Extension `ExtensionActivityName` private enum 동시 수정.
>    → 실기기에서만 재현 가능, 단위 테스트 불가.
>
> 5. **`ManagedSettingsStore.Name.lockinPrimary` 이름 변경**
>    → 메인 앱 `ManagedSettingsBlockingEngine` + Extension `DeviceActivityMonitorExtension` 두 곳의
>    `ManagedSettingsStore(named:)` 모두 동일해야 App Group 공유 shield 가 유지됨.
>
> 6. **`UserDefaultsPersistenceStore` 의 `try?` silent 실패 경로**
>    → 로그 없음. 디코딩 실패 시 빈 `FamilyActivitySelection()` 폴백으로
>    역-화이트리스트의 예외 집합이 비면 **모든 카테고리 차단** 리스크. Phase 5 `os_log` 권고.
>
> 7. **`AppGroup.sharedDefaults` 의 `fatalError`**
>    → Xcode 캐시 오염 시 첫 launch 에서 crash 가능. Phase 5 degrade 경로 권고.

---

## 6. DI 계층 흐름

```
LockinFocusApp (@main)
   │
   │ @StateObject deps = AppDependencies.live()
   │
   ▼
RootView .environmentObject(deps)
   │
   ├── OnboardingContainerView
   │      │
   │      └── Steps/ (Value / SystemPreset / AppPicker / Schedule / Authorization)
   │             │
   │             └── deps.persistence / deps.blocking / deps.monitoring 참조
   │
   ├── DashboardView
   │      └── deps.* 참조, save() 시 blocking.applyWhitelist + monitoring.startSchedule
   │
   └── .sheet InterceptView
          └── deps.blocking.clearShield() + deps.monitoring.startTemporaryAllow(...)
```

`AppDependencies.live()` 는 시뮬/실기기 분기:

- **시뮬레이터**: `UserDefaultsPersistenceStore` + `NoopBlockingEngine` + `NoopMonitoringEngine`
- **실기기**: `UserDefaultsPersistenceStore` + `ManagedSettingsBlockingEngine` + `DeviceActivityMonitoringEngine`
  (blocking 이 monitoring 을 `weak` 참조, `bind(monitoring:)` 후주입으로 순환 회피)

`AppDependencies.preview()` 는 `InMemoryPersistenceStore` + Preview 전용 Mock 엔진 주입 (SwiftUI `#Preview` 및 일부 테스트).

---

## 7. 테스트 커버리지 (23 케이스 / 5 파일)

| 파일 | 케이스 | 영역 | 우선 방어 이슈 |
|---|---|---|---|
| `ScheduleTests.swift` | 4 | `Schedule` 프리셋 + Codable + DateComponents 변환 | JSON 라운드트립 깨짐 |
| `InterceptEventTests.swift` | 4 | `EventType`/`SubjectKind` rawValue 고정 | H1 큐 스키마 회귀 |
| `InMemoryPersistenceStoreTests.swift` | 5 | 테스트용 Fake 의 set/get/drain 계약 | 프로토콜 semantic drift |
| `UserDefaultsPersistenceStoreTests.swift` | 6 | 실 suite 주입으로 앱 재시작 근사 + **Extension raw dict 디코딩** | H1 최중요 회귀 방지 |
| `PreviewEngineTests.swift` | 4 | Preview/Noop 엔진 smoke | 시뮬 live 분기 무결성 |

실기기 전용 영역(`ManagedSettingsBlockingEngine.applyWhitelist`, `DeviceActivityMonitoringEngine` 실호출, InterceptView Timer UI) 는
단위 테스트 대상 밖. `docs/09_Release_Checklist.md` 의 수동 QA 항목으로 이월.

---

## 8. 파일 탐색 팁 (grep 레시피)

```bash
# activity 이름 모든 참조처
grep -rn "block_main\|temp_allow_" LockinFocus DeviceActivityMonitorExtension ShieldActionExtension

# App Group identifier 중복처
grep -rn "group.com.imurmkj.LockinFocus" LockinFocus DeviceActivityMonitorExtension ShieldActionExtension ShieldConfigurationExtension

# 인터셉트 큐 키
grep -rn "interceptQueue" LockinFocus ShieldActionExtension LockinFocusTests

# .all(except:) 역-화이트리스트 적용 지점
grep -rn "applicationCategories" LockinFocus DeviceActivityMonitorExtension
```

---

## 9. 관련 문서

- [`02_UX_Design.md`](02_UX_Design.md) — 화면 11 개, 카피 가이드, 예외 UX.
- [`03_Architecture.md`](03_Architecture.md) — iOS Screen Time API 제약 원문 조사 (정식 근거).
- [`04_Integration_Resolution.md`](04_Integration_Resolution.md) — 16 개 쟁점 해결.
- [`05_Debugger_Report.md`](05_Debugger_Report.md) — H1–H10 가설 검증 + 실기기 QA 7 항목.
- [`06_Test_Report.md`](06_Test_Report.md) — 23 케이스 커버리지 + 미커버 고위험 영역.
- [`07_Review_Report.md`](07_Review_Report.md) — A~G 7 영역 최종 리뷰.
- [`09_Release_Checklist.md`](09_Release_Checklist.md) — 배포 전 선결 항목.
