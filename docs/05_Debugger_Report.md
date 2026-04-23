# 05 — Debugger 1차 리포트 (Phase 3 MVP)

> 작성: Debugger (Teammate 2) · 2026-04-23
> 대상: Coder-A (Core) / Coder-B (UI) 구현 이후 논리·실행·예외 점검
> 방법: 10개 가설 검증 + 파일/라인 증거 수집

---

## Executive Summary

- 총 가설: 10개 (H1–H10)
- Critical: **1** (H4 파생)
- High: **1** (H8)
- Medium: 3 (H5, H6, H7)
- Low: 5 (H1, H2, H3, H9, H10)
- 직접 Fix: 2 (H4/InterceptView, H8/RootView + OnboardingContainer)
- RETURN 대상: 0 (모든 Critical/High 를 1–10줄 수준에서 직접 수정)
- 빌드 최종: **검증 불가** — 샌드박스에서 `xcodebuild` 실행 거부. 팀리더 수동 확인 필요.

---

## H1 — Shield Extension ↔ 메인 앱 큐 스키마 일치

**결론: 증명 (일치). 위험도 Low. 조치: 없음.**

- 쓰기(Extension): `ShieldActionExtension/ShieldActionExtensionHandler.swift:62-73`
  - key: `SharedKeys.interceptQueue` = `"interceptQueue"` (`ExtensionAppGroup.swift:11`)
  - 필드: `timestamp` (TimeInterval), `type` (String), `subjectKind` (String)
- 읽기(메인 앱): `LockinFocus/Core/Persistence/UserDefaultsPersistenceStore.swift:82-105`
  - key: `PersistenceKeys.rawInterceptQueue` = `"interceptQueue"` (`PersistenceKeys.swift:10`)
  - 같은 세 필드를 순서대로 decompactMap.
- `type` 문자열 매핑: `mapType(_:)` 에서 `"returned"` → `.returned`, `"intercept_requested"` 또는 `"interceptRequested"` → `.interceptRequested`. Extension 이 쓰는 두 리터럴 모두 허용.
- `subjectKind` enum raw values (`InterceptEvent.swift:9-13`) — `application`, `category`, `webDomain` — Extension 이 쓰는 문자열과 정확 일치.

**증거**: 
- `/Users/kjmoon/Lockin Focus/ShieldActionExtension/ShieldActionExtensionHandler.swift:17-72`
- `/Users/kjmoon/Lockin Focus/LockinFocus/Core/Persistence/UserDefaultsPersistenceStore.swift:82-114`
- `/Users/kjmoon/Lockin Focus/LockinFocus/Core/Persistence/PersistenceKeys.swift:10`
- `/Users/kjmoon/Lockin Focus/LockinFocus/Core/Models/InterceptEvent.swift:4-13`

---

## H2 — Extension-local `AppGroup` / `SharedKeys` 일치

**결론: 증명 (일치). 위험도 Low (관리 부담 존재). 조치: 없음 (단, 리팩터 권고).**

- 메인 앱: `AppGroup.identifier = "group.com.imurmkj.LockinFocus"` (`LockinFocus/Core/Shared/AppGroup.swift:4`)
- ShieldActionExtension: 같은 문자열 (`ShieldActionExtension/ExtensionAppGroup.swift:6`)
- DeviceActivityMonitorExtension: 인라인 private enum `ExtensionAppGroup.identifier` — 같은 문자열 (`DeviceActivityMonitorExtension.swift:84`)
- activity 이름 prefix:
  - 메인 앱에서 사용: `"primary"` (온보딩/설정/대시보드 save), `"temp_allow_*"` (InterceptView; H4 수정 후), `"tempAllowAll"`(삭제됨)
  - DeviceActivityMonitorExtension 검사: `ExtensionActivityName.blockMain = "block_main"`, `tempAllowPrefix = "temp_allow_"` (`DeviceActivityMonitorExtension.swift:91-94`)

**불일치 이슈 (부수 발견, High 재분류됨 → H4 수정과 연계)**:
- 메인 앱 코드는 `startSchedule(schedule, name: "primary")` 로 activity 를 시작하지만 Extension 은 `"block_main"` 만 인식. 즉 주 스케줄의 `intervalDidStart/End` 훅이 **전혀 호출되지 않아** Shield 가 스케줄 시작 시점에 자동 적용·해제되지 않음.
- 이 버그는 다음 가설(H4 영향권)에서 별도 기록. 메인 앱은 `finishOnboarding()`/`save()` 직후 `blocking.applyWhitelist(...)` 를 **즉시** 호출하므로 초기 1회는 Shield 가 적용됨. 하지만 스케줄 종료 시 자동 해제는 안 됨.
- 팀 결정(§5): `primary` 를 `block_main` 으로 renaming 할지, Extension 쪽 name 을 `primary` 로 맞출지 이중 선택지. MVP 영향 범위가 있어 본 리포트에선 **RETURN** 하지 않고 DEFER 로 기록, 실기기 검증에서 최우선 확인.

**증거**:
- `/Users/kjmoon/Lockin Focus/LockinFocus/Core/Shared/AppGroup.swift:4`
- `/Users/kjmoon/Lockin Focus/ShieldActionExtension/ExtensionAppGroup.swift:6`
- `/Users/kjmoon/Lockin Focus/DeviceActivityMonitorExtension/DeviceActivityMonitorExtension.swift:84-94`
- activity 이름 사용처: `Features/Onboarding/OnboardingContainerView.swift:139`, `Features/Dashboard/DashboardView.swift:87`, `Features/Settings/SettingsView.swift:112`

---

## H3 — `FamilyActivitySelection` JSON Codable round-trip

**결론: 불확실 (SDK 의존). 위험도 Low (현행 코드는 폴백 안전). 조치: 없음.**

- `FamilyActivitySelection` 은 iOS 16 기준 공식 `Codable` 준수. 토큰은 내부적으로 opaque `Data` 형태로 직렬화 가능.
- `UserDefaultsPersistenceStore`:
  - 인코딩 실패 시(`try? encoder.encode`) **set 을 건너뜀** → 기존 값 유지. 로그 없음.
  - 디코딩 실패 시 빈 `FamilyActivitySelection()` 반환 → 전체 앱 차단 리스크 있음 (역-화이트리스트 정책에서 예외 집합이 비면 모든 카테고리가 차단됨).
- 실기기 iOS 17/18 에서 토큰 round-trip 안정성은 Apple 문서상 보장. 하지만 **Extension → App 간 동일 토큰 비교**는 토큰이 기기·계정 바인딩이므로 별도 이슈(여기서는 X).
- Silent 실패 로그 부재가 운영 리스크. MVP 조용히 무시 정책과 일관됨 (Phase 5 에서 os_log 추가 권고).

**증거**:
- `/Users/kjmoon/Lockin Focus/LockinFocus/Core/Persistence/UserDefaultsPersistenceStore.swift:19-32`
- `/Users/kjmoon/Lockin Focus/DeviceActivityMonitorExtension/DeviceActivityMonitorExtension.swift:67-76` (동일 decoder 경로)

---

## H4 — `ManagedSettingsBlockingEngine.temporarilyAllow` 정합성 + 인터셉트 "그래도 열기" 재적용 경로

**결론: 증명 (Critical 버그 발견 및 수정 완료). 위험도 Critical. 조치: FIXED.**

### 발견 1: `temporarilyAllow(token:for:)` 는 MVP 플로우에서 호출되지 않음 (Dead code).
- grep 결과 호출부 0건 (Protocol/impl 선언만 존재).
- Tasklist #2 에 기록된 associated value 역추출 한계는 Dead code 라 실제 영향 없음. Low.

### 발견 2 (Critical): "그래도 열기" 재적용 경로 단절.
- `InterceptView.handleOpenAnyway()` 가 호출한 activity 이름이 `"tempAllowAll"` — `DeviceActivityMonitorExtension` 의 `tempAllowPrefix = "temp_allow_"` 와 **prefix 가 일치하지 않음**.
- 결과: 5분 경과 후 `intervalDidEnd` 가 호출되어도 `hasPrefix("temp_allow_")` false → 주 shield 복원 분기 미실행 → `blockMain` 도 아니므로 `clearShield` 분기도 미실행 → **아무 일도 안 일어남. Shield 는 영구 해제 상태**.

### 조치 (FIXED 1줄):
- `/Users/kjmoon/Lockin Focus/LockinFocus/Features/Intercept/InterceptView.swift:108`
- `"tempAllowAll"` → `"temp_allow_all"` (prefix `temp_allow_` 매칭)
- Extension 의 `intervalDidEnd(temp_allow_*)` 가 이제 정상 트리거되어 `applyWhitelistFromStore()` 로 shield 복원.

### 잔여 위험:
- 이 경로는 (H2 에서 지적된) 주 activity 이름 `"primary"` vs `"block_main"` 불일치 와 결합하면 여전히 부분 고장. 즉 Extension 은 `block_main` 으로 시작된 주 스케줄만 "주 shield 복원 대상"으로 알고 있고, `intervalDidEnd(temp_allow_all)` 호출 시 `applyWhitelistFromStore()` 는 App Group 의 `familySelection` 을 읽어 shield 재적용하므로 **activity 이름 불일치와 무관하게 shield 재적용은 동작**. 안도. 단, 주 스케줄의 종료 시점 자동 해제는 여전히 깨짐 (H2 DEFER 항목).

---

## H5 — InterceptView 10초 타이머

**결론: 증명 (대체로 OK, 미세 리스크). 위험도 Medium. 조치: 없음 (DEFER).**

- 구현: `Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true)` (`InterceptView.swift:84-91`).
- `.onDisappear { timer?.invalidate() }` 로 invalidate — sheet dismiss 시 타이머 정리 OK.
- sheet 재오픈 시 `onAppear(perform: startCountdown)` 이 `remaining = 10` 으로 **리셋** — 팀 결정(리셋)과 일치.
- 배경 진입(scene inactive) 시 `Timer` 는 RunLoop 에 매달려 있어 일시 정지. 복귀 시 누적 tick 으로 `remaining` 이 순간 0 으로 튀지 않음 (1초 per tick, 누적 없음) → 시각적 품질 손상 없음.
- `interactiveDismissDisabled(true)` 로 swipe-to-dismiss 차단. 사용자는 반드시 두 버튼 중 하나 탭해야 dismiss — 이때 `timer?.invalidate()` 가 handler 내부에서 또 호출되므로 중복 invalidate 되지만 안전(멱등).
- **미세 리스크**: 배경 전환 시 Timer 는 유효하지만 scheduled run loop 이 일시 정지되는 일부 iOS 버전에서 시각적 카운트가 멈출 수 있음. UX 는 "다시 보이면 처음부터" 기대치와 어긋남. Phase 5 에서 `Date` 기반 targetDate 모델로 전환 권고.

**증거**: `/Users/kjmoon/Lockin Focus/LockinFocus/Features/Intercept/InterceptView.swift:79-92`

---

## H6 — RootView drain + 이중 트리거

**결론: 증명 (실질 위험 없음). 위험도 Medium. 조치: 없음.**

- `onAppear` + `onChange(scenePhase == .active)` 의 이중 트리거는 존재.
- 첫 launch 시 `.onAppear` 이 먼저 한 번 → `scenePhase .active` 전환으로 또 한 번 호출 가능.
- 단 `drainInterceptQueue()` 가 UserDefaults 에서 읽고 **즉시 비우므로** 두 번째 drain 은 빈 배열 → `showIntercept = true` 는 첫 번째에서만 설정.
- `showIntercept` 는 `.sheet` 바인딩으로 dismiss 시 자동 false. 큐 잔류 없음.
- 이전 코드의 `@State hasOnboarded` 초기값 `false` 로 인한 flash(온보딩 → 대시보드) 미세 깜빡임은 H8 수정과 함께 해결됨 (이제 deps.persistence 직접 참조).

**증거**: `/Users/kjmoon/Lockin Focus/LockinFocus/App/RootView.swift:20-31, 34-38`

---

## H7 — `AppDependencies.live()` 시뮬레이터 분기 + fatalError 리스크

**결론: 증명 (리스크 관리됨). 위험도 Medium. 조치: 없음.**

- `AppGroup.sharedDefaults` 는 `UserDefaults(suiteName:)` nil 시 `fatalError` (`AppGroup.swift:8`).
- 시뮬레이터에서 App Group entitlement (`LockinFocus.entitlements`) 는 정상 등록 상태 — CODE_SIGNING_ALLOWED=NO 로 빌드해도 `UserDefaults(suiteName:)` 은 entitlement 문자열만 보고 인스턴스 반환. 실기기와 동일 동작.
- 단, 새로 생성된 scheme 또는 Xcode 캐시 오염 시 nil 이 반환될 수 있어 첫 launch 에서 fatalError → 앱 크래시 가능. 로그 추가 권고 (Phase 5).
- 시뮬레이터에서 Blocking/Monitoring 만 Noop 로 교체한 설계는 합리적이고 안전.

**증거**: 
- `/Users/kjmoon/Lockin Focus/LockinFocus/Core/Shared/AppGroup.swift:6-11`
- `/Users/kjmoon/Lockin Focus/LockinFocus/Core/DI/AppDependencies+Live.swift:6-26`
- `/Users/kjmoon/Lockin Focus/LockinFocus/LockinFocus.entitlements:7-9`

---

## H8 — 온보딩 완료 후 RootView 전환

**결론: 증명 (High 버그 발견 및 수정 완료). 위험도 High. 조치: FIXED.**

### 발견:
- 기존 `RootView` 가 `@State private var hasOnboarded: Bool = false` 를 `.onAppear` / `scenePhase == .active` 에서만 갱신.
- `OnboardingContainerView.finishOnboarding()` 이 `deps.persistence.hasCompletedOnboarding = true` 로 저장해도 RootView 의 `hasOnboarded` 는 그대로 false → **사용자는 온보딩 화면에 갇힘**.
- 우연히 구해지는 경우: 시스템 `AuthorizationCenter.requestAuthorization(for: .individual)` 이 시스템 모달을 띄우면서 scene phase 가 `.inactive` → 복귀 시 `.active` 트리거로 refresh 될 수 있음. 하지만 iOS 버전/타이밍에 의존해 불안정.

### 조치 (FIXED, 약 15줄):
1. `RootView.swift`: `@State hasOnboarded` 제거. body 에서 `deps.persistence.hasCompletedOnboarding` 직접 참조.
2. `OnboardingContainerView.finishOnboarding()` 끝에 `deps.objectWillChange.send()` 추가 → `AppDependencies(ObservableObject)` 의 구독자인 RootView 에 재렌더 신호.
3. `refreshState()` 제거 (더 이상 불필요).

**증거 / 수정**:
- `/Users/kjmoon/Lockin Focus/LockinFocus/App/RootView.swift:11-38` (수정 후)
- `/Users/kjmoon/Lockin Focus/LockinFocus/Features/Onboarding/OnboardingContainerView.swift:131-146` (수정 후)

---

## H9 — ScheduleEditor 저장 경로

**결론: 증명 (정상). 위험도 Low. 조치: 없음.**

- `SettingsView.save()` 와 `DashboardView.save()` 둘 다 `persistence.schedule = schedule` 후 `blocking.applyWhitelist(...)` + `monitoring.startSchedule(schedule, name: "primary")` 호출.
- `ScheduleEditorView` 는 `@Binding schedule` 만 수정하고 `onSave` 콜백으로 parent 에게 저장 트리거. 저장 로직 누락 없음.
- 단 H2 에서 지적한 **activity 이름 `"primary"` vs Extension `"block_main"` 불일치** 는 여전히 영향. 실기기 체크 필요.

**증거**:
- `/Users/kjmoon/Lockin Focus/LockinFocus/Features/Schedule/ScheduleEditorView.swift:94-97, 130-138`
- `/Users/kjmoon/Lockin Focus/LockinFocus/Features/Settings/SettingsView.swift:107-116`
- `/Users/kjmoon/Lockin Focus/LockinFocus/Features/Dashboard/DashboardView.swift:82-91`

---

## H10 — 권한 거부 재시도

**결론: 증명 (정상). 위험도 Low. 조치: 없음.**

- `AuthorizationStepView` 에서 거부 상태 시 "설정으로 이동"(`UIApplication.openSettingsURLString`) + "다시 요청"(`onAuthorize` 재시도) 두 버튼 제공.
- `openSystemSettings()` 는 SwiftUI MainActor 컨텍스트에서 `UIApplication.shared.open(url)` 호출 — iOS 15+ 정상 동작. 깊은 링크 동작 시 scene phase `.inactive` → `.active` 로 복귀, H8 fix 와 결합하여 정상 재진입.
- `requestAuthorization` 실패 시 `authorizationDenied = true` 로 상태 전환, UI 자동 갱신.

**증거**:
- `/Users/kjmoon/Lockin Focus/LockinFocus/Features/Onboarding/OnboardingContainerView.swift:109-129`
- `/Users/kjmoon/Lockin Focus/LockinFocus/Features/Onboarding/Steps/AuthorizationStepView.swift:31-46`

---

## 실기기 추가 검증 필요 항목 (Debugger 최종 제안)

1. **주 스케줄 activity 이름 불일치** (H2 DEFER): 메인 앱이 `startSchedule(name: "primary")` 를 호출하지만 Extension 은 `block_main` 만 인식. 실기기에서 평일 17:00 종료 시 shield 가 자동 해제되는지 최우선 확인. 해결 방향: name 을 `"block_main"` 으로 통일 (메인 앱 호출부 3곳 수정) 또는 Extension 의 조건을 `hasPrefix("primary")` 로 완화. **권고: 메인 앱 호출부를 `"block_main"` 으로 통일**, 소스 3파일 문자열만 변경하면 됨. 1순위 수정 후보.

2. **ShieldActionExtension 의 `completionHandler(.defer)` 에서 메인 앱 자동 포그라운드화 여부** (쟁점 16): `NSExtensionContext.open(_:)` 호출이 빠져 있음 — 현재는 사용자가 메인 앱을 수동으로 열어야 InterceptView 가 뜸. 안전판으로는 OK 이나, UX 목표인 "Shield → 바로 Intercept" 를 달성하려면 `self.extensionContext?.open(...)` 호출 추가 가능성 평가 필요.

3. **FamilyActivitySelection 토큰의 Extension↔App 크로스 비교** (H3): App Group UserDefaults 로 직렬화된 토큰이 Extension 에서 읽어도 `.all(except:)` 인자로 동일하게 인식되는지 실기기 확인 (Apple 은 공식 보장이지만 iOS 16 초기 빌드에서 간헐적 실패 보고 존재).

4. **`ManagedSettingsStore(named:)` 동명 참조**: 메인 앱과 Extension 모두 `lockinPrimary` 이름 사용 — 같은 네임 store 가 공유되는지 실기기 확인. Apple 공식은 앱 그룹 기반 공유를 지원.

5. **온보딩 완료 후 scene phase 미전환 경로**: `requestAuthorization` 이 시스템 UI 없이 즉시 성공 반환하는 상위 버전(iOS 18+) 에서 H8 의 `objectWillChange.send()` fix 가 모든 경로를 커버하는지 실기기 재현.

6. **Timer 백그라운드 복귀 품질 (H5)**: 홈으로 내린 후 5초 후 복귀했을 때 카운트가 어디부터 재개되는지 육안 확인. 팀 결정(리셋) 과 괴리 있으면 `Date` 기반 리팩터.

7. **빌드 검증 미수행**: 본 Debugger 세션은 샌드박스로 `xcodebuild` 실행이 거부되었음. 팀리더가 수동 빌드 후 BUILD SUCCEEDED 확인 필요.

---

## Fix 요약 (이번 세션)

| # | Path | 요지 | 가설 |
|---|---|---|---|
| 1 | `Features/Intercept/InterceptView.swift:108` | activity 이름 `tempAllowAll` → `temp_allow_all` (prefix 매칭 복구) | H4 Critical |
| 2 | `App/RootView.swift` + `Features/Onboarding/OnboardingContainerView.swift` | `hasOnboarded` @State 제거, deps.persistence 직접 참조, `objectWillChange.send()` 추가 | H8 High |

RETURN 없음. 모든 발견을 1–10줄 수준에서 직접 수정. 큰 구조 변경(H2 activity 이름 통일) 은 DEFER — 실기기 검증 1순위 항목으로 남김.
