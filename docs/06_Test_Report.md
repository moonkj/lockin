# 06 — Test Engineer 1차 리포트 (Phase 4 전반부)

> 작성: Test Engineer (Teammate 3) · 2026-04-23
> 대상: Phase 3 MVP 구현 + Phase 4-1 Debugger Fix 이후 BUILD SUCCEEDED 상태
> 범위: 단위 테스트 + **Extension ↔ App 큐 스키마 회귀 방지 계약 테스트**

---

## 1. 테스트 타깃 스캐폴드

- 신규 타깃: `LockinFocusTests` (`bundle.unit-test`).
- `Project.yml` 편집 요지:
  - `targets.LockinFocusTests` 추가 (BUNDLE_LOADER / TEST_HOST / INFOPLIST_FILE 설정).
  - `schemes.LockinFocus.test.targets = [LockinFocusTests]` 추가.
- `LockinFocusTests/Info.plist` 최소 bundle plist 작성.
- 의존성: `target: LockinFocus` — `@testable import LockinFocus` 로 internal 접근.

---

## 2. 작성한 테스트 파일 (5개, 총 21 케이스)

### `ScheduleTests.swift` (4 케이스)
| 테스트 | 목적 |
|---|---|
| `testWeekdayWorkHours_hasCorrectWeekdays` | 평일 프리셋 weekdays = [2..6] (Cal 1=Sun 규약) 고정. |
| `testSchedule_codableRoundTrip` | JSON 인코딩/디코딩 안정성 — `UserDefaultsPersistenceStore.schedule` 이 사용. |
| `testStartComponents_returnsCorrectHourMinute` | DateComponents 변환 검증. |
| `testAllDay_hasAllWeekdaysAndDisabled` | `.allDay` 프리셋 상수 고정. |

### `InterceptEventTests.swift` (4 케이스)
| 테스트 | 목적 |
|---|---|
| `testCodableRoundTrip` | `InterceptEvent` JSON 직렬화 안정성. |
| `testRawValueStability_EventType` | **H1 회귀 방지**. Extension 이 쓰는 `"returned"`, `"interceptRequested"` 문자열이 enum rawValue 와 정확 일치. |
| `testRawValueStability_SubjectKind` | **H1 회귀 방지**. `"application"`, `"category"`, `"webDomain"` 문자열 고정. |
| `testEventType_interceptRequested_exists` | `interceptRequested` rawValue 로 enum 복원 가능. |

### `InMemoryPersistenceStoreTests.swift` (5 케이스)
| 테스트 | 목적 |
|---|---|
| `testSetAndGetSelection` | FamilyActivitySelection set/get crash 없음. |
| `testSetAndGetSchedule` | Schedule 왕복. |
| `testHasCompletedOnboarding_defaultsFalse` | 온보딩 플래그 기본값 + 토글. |
| `testDrainInterceptQueue_returnsAndClears` | drain 2건 후 재 drain 은 빈 배열 (멱등성 아닌, 소비성 큐 계약). |
| `testFocusScoreToday_defaultsZero` | 정수 스칼라 기본값. |

### `UserDefaultsPersistenceStoreTests.swift` (6 케이스) — **핵심**
`UserDefaultsPersistenceStore.init(defaults:)` 주입 이니셜라이저가 이미 있어 테스트 전용 suite (`com.imurmkj.LockinFocus.tests`) 를 생성해 사용. `setUp/tearDown` 에서 `removePersistentDomain` 으로 격리.

| 테스트 | 목적 |
|---|---|
| `testScheduleRoundTrip_viaJSON` | 같은 suite 로 재생성한 store2 가 동일 Schedule 복원 — 앱 재시작 시나리오 근사. |
| `testFocusScoreToday_persists` | 정수 스칼라 defaults 왕복. |
| `testHasCompletedOnboarding_persists` | RootView 온보딩 분기 계약. |
| **`testDrainInterceptQueue_decodesExtensionRawFormat`** | **최중요 회귀 방지**. defaults 에 `[[String: Any]]` raw dict 2건 직접 write → drain 후 `InterceptEvent` 2건 디코딩 + 큐 비워짐. Debugger H1 계약(필드 이름 timestamp/type/subjectKind, 키 "interceptQueue", enum rawValue) 을 코드로 고정. |
| `testDrainInterceptQueue_acceptsLegacySnakeCaseType` | `"intercept_requested"` (snake_case) 레거시 문자열도 `.interceptRequested` 로 매핑 — `mapType` 의 이중 허용 분기 보호. |
| `testDrainInterceptQueue_dropsMalformedEntries` | 알 수 없는 rawValue 는 silently drop, 정상 건만 통과. |

### `PreviewEngineTests.swift` (4 케이스)
| 테스트 | 목적 |
|---|---|
| `testPreviewBlockingEngine_doesNotThrow` | Preview Mock smoke. |
| `testPreviewMonitoringEngine_doesNotThrow` | `XCTAssertNoThrow` 로 `throws` 메서드 crash-free 확인. |
| `testNoopEngines_doNotThrow` | 시뮬레이터 라이브 빌드 분기 Noop 엔진 smoke. |
| `testAppDependencies_previewFactory_returnsAllFields` | `.preview()` 팩토리가 모든 필드 + PreviewPersistenceStore 기본값(42, false) 구성. |

---

## 3. 실행 결과

- **샌드박스 차단**: `xcodegen generate` 및 `xcodebuild test` 모두 현 세션 샌드박스에서 실행 거부됨 (Debugger/Coder 세션과 동일 제약).
- **결과**: 팀리더 수동 실행 대기.
- **팀리더 수동 실행 절차**:
  ```bash
  cd "/Users/kjmoon/Lockin Focus"
  xcodegen generate
  xcrun simctl list devices available | grep iPhone | head -5   # 사용 가능 시뮬 확인
  xcodebuild -project LockinFocus.xcodeproj \
             -scheme LockinFocus \
             -sdk iphonesimulator \
             -destination 'platform=iOS Simulator,name=iPhone 15' \
             CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
             test 2>&1 | tail -40
  ```
  시뮬 이름이 없으면 `iPhone 16` 또는 `iPhone 15 Pro` 로 치환.

---

## 4. 커버리지 요약 (정성 추정)

| 영역 | 커버리지 | 근거 |
|---|---|---|
| `Core/Models/Schedule` | ~95% | 프리셋 + Codable + computed 속성 전부 터치. |
| `Core/Models/InterceptEvent` | ~90% | Codable + 전체 enum rawValue 고정. |
| `Core/Persistence/InMemoryPersistenceStore` | ~95% | 모든 프로퍼티 + drain 경로 커버. |
| `Core/Persistence/UserDefaultsPersistenceStore` | ~85% | raw drain / JSON 라운드트립 / 스칼라 커버. `selection` 의 FamilyActivitySelection 인코딩 실패 silent 폴백만 미터치. |
| `Core/BlockingEngine/NoopBlockingEngine` | 100% | smoke. |
| `Core/MonitoringEngine/NoopMonitoringEngine` | 100% | smoke. |
| `Core/BlockingEngine/ManagedSettingsBlockingEngine` | 0% | 실기기 ManagedSettings 필요 — 단위 테스트 범위 밖. |
| `Core/MonitoringEngine/DeviceActivityMonitoringEngine` | 0% | 실기기 DeviceActivity 필요 — 단위 테스트 범위 밖. |
| `Core/DI/AppDependencies.preview()` | ~80% | 팩토리 구성 검증. `live()` 는 `#if targetEnvironment(simulator)` 분기로 일부만. |

---

## 5. 미 커버 고위험 영역

1. **ShieldActionExtension 실제 enqueue 경로** — `UserDefaults(suiteName: ... .LockinFocus)` 에 실기기가 쓰는 데이터의 **실시간 가시성 타이밍**. 단위 테스트는 *스키마 계약만* 고정하며, 크로스-프로세스 flush 지연은 실기기 QA 필요.
2. **`DeviceActivityMonitorExtension.intervalDidStart/End` 실호출** — iOS 16+ 실기기에서 스케줄 경계 시점 호출 여부 (Debugger DEFER 검증 1순위 잔여). 단위 테스트 불가능, 팀리더가 실기기 검증.
3. **`ManagedSettingsBlockingEngine.applyWhitelist`** — `.all(except:)` policy 적용 시 실제로 차단 앱 2개가 각각 차단되는지 실동작. 실기기 전용.
4. **`InterceptView` 10초 타이머 UI 흐름** — UI 테스트 범위 (Test Engineer Phase 4 범위 밖, 추후).
5. **`FamilyActivitySelection` Codable round-trip 실기기 안정성** (Debugger H3) — SDK 의존. 단위 테스트로는 재현 불가.
6. **RootView drain + scenePhase 이중 트리거** (H6) — UI 계층 통합 테스트 영역.
7. **`AuthorizationCenter.requestAuthorization(for: .individual)`** — 시스템 모달, 시뮬레이터에서 즉시 성공 반환. 실기기 플로우와 차이.

---

## 6. 회귀 방지용 테스트 의도 요약

- **H1 (큐 스키마)** 재발 시 가장 먼저 탐지할 테스트:
  - `InterceptEventTests.testRawValueStability_*` — enum rawValue 문자열 변경 감지.
  - `UserDefaultsPersistenceStoreTests.testDrainInterceptQueue_decodesExtensionRawFormat` — 필드 이름 / 타입 / 키 이름 변경 감지. ShieldActionExtension 의 enqueue dict 와 정확히 동일한 raw 값 으로 테스트 데이터 작성.
  - `testDrainInterceptQueue_acceptsLegacySnakeCaseType` — `mapType` 의 snake_case 허용이 제거되면 실패.
- **H4 재발 방지** 는 activity 이름이 문자열이라 컴파일 타임 캐치 어려움 → 통합 테스트 영역 (Phase 4 후반부 Reviewer/실기기 검증 의존).
- **H8 재발 방지**: 온보딩 플래그 persistence 왕복은 `testHasCompletedOnboarding_persists` 로 기저 보장. RootView refresh 로직 자체는 UI 테스트 대상.

---

## 7. Coder-A 복귀 필요 항목

**없음**. `UserDefaultsPersistenceStore` 는 이미 `init(defaults: UserDefaults = AppGroup.sharedDefaults)` 주입 가능 이니셜라이저를 갖고 있어 테스트 전용 suite 주입에 문제 없었다.

---

## 8. Reviewer 에게 집중 요청 TOP 3

1. **큐 스키마 계약 고정성** — `InterceptEvent` enum 의 rawValue 를 향후 리팩터링에서 절대 바꾸지 않도록 코드 리뷰 규칙에 명시. (이 테스트들이 실패하면 Extension 측 Handler 도 동시에 수정해야 한다는 경고가 docstring 에 포함됨.)
2. **시뮬레이터 Live 분기 무결성** — `AppDependencies.live()` 의 `#if targetEnvironment(simulator)` 분기가 Noop 엔진을 주입하는지 Reviewer 가 직접 확인. `PreviewEngineTests` 는 타입 레벨 smoke 만 보장.
3. **실기기 전용 위험 (Debugger DEFER #1~#7)** — 단위 테스트 한계 밖 항목. Reviewer 는 실기기 QA 계획에서 이 리스트를 체크리스트로 사용 권장.
