# 07 — Reviewer 최종 리뷰 리포트 (초회)

> 작성: Reviewer (Teammate 3) · 2026-04-23
> 대상: Phase 3 MVP 구현 + Phase 4-1 Debugger Fix (H4/H8, 팀리더 H2 승격) + Phase 4-2 Test Engineer (5 파일 / 23 케이스) 이후 최종 품질 리뷰
> 입력: `docs/04_Integration_Resolution.md`, `docs/05_Debugger_Report.md`, `docs/06_Test_Report.md`, `Tasklist.md` 전체, 모든 소스/Extension/테스트, `Project.yml`

---

## 0. 요약 점수 및 결론

| 영역 | 점수 (1–5) |
|---|---|
| A. 가독성 | **4.5** |
| B. 유지보수성 | **4.0** |
| C. 확장성 | **4.0** |
| D. 테스트 가치 | **4.5** |
| E. UX 준수 | **4.5** |
| F. 안전성·정합성 | **4.0** |
| G. 문서·개발자 경험 | **4.5** |

**결론: (a) 최종 완료 — Phase 5 진입 권고.**

Critical/High 잔존 없음. 구조적 결함 없음. 관찰된 개선 항목은 전부 `[Phase 5 이월]` 또는 `[R2 권장]` (배포 방해 아님). 각 항목은 이미 토론 로그/Debugger DEFER 로 명시 등록된 리팩터·실기기 의존 성격이라 이번 라운드의 R2 복귀 사유에 해당하지 않음.

---

## 1. 영역별 상세 리뷰

### A. 가독성 — 4.5 / 5

- 네이밍 의도 명확. `applyWhitelist(for:)`, `drainInterceptQueue()`, `temp_allow_*` prefix 규약이 파일 상단 docstring에 선언되어 grep 친화적.
- `InterceptView`, `OnboardingContainerView`, `DeviceActivityMonitorExtension` 모두 주석이 **"왜"** 를 설명하며 과도하지 않음 (쟁점 번호 역참조 포함 — 문서 연결 탁월).
- `Core/Protocols/*.swift` 3개 파일의 주석이 실구현·Noop 분기를 친절히 안내.
- 한 함수의 책임이 분명 — `ManagedSettingsBlockingEngine.applyWhitelist` 는 4행, `InterceptView.handleOpenAnyway` 는 7행으로 단일 책임.
- 감점: `Core/Shared/AppGroup.swift` 의 `SharedKeys`, `PersistenceKeys`, Extension 로컬 상수 등 **키 상수 선언처가 3곳으로 분산**되어 읽을 때 전체 일람이 한눈에 안 들어옴 (B 영역과도 연결).

### B. 유지보수성 — 4.0 / 5

- DI 교체 가능성 ✅: `AppDependencies.live()` vs `.preview()`, `PersistenceStore`/`BlockingEngine`/`MonitoringEngine` 세 프로토콜이 `AnyObject` 로 명확히 분리, `UserDefaultsPersistenceStore.init(defaults:)` 주입형 이니셜라이저 존재(테스트 전용 suite 사용 가능).
- Preview Mock vs Live 분리 품질 양호: `AppDependencies.swift` 에 Preview, `AppDependencies+Live.swift` 에 시뮬/실기기 분기(Noop + 후주입 `bind(monitoring:)`).
- **Extension ↔ 메인 앱 암묵적 계약**:
  - `AppGroup.identifier = "group.com.imurmkj.LockinFocus"` 가 4곳에 중복 선언:
    1. `LockinFocus/Core/Shared/AppGroup.swift`
    2. `ShieldActionExtension/ExtensionAppGroup.swift`
    3. `DeviceActivityMonitorExtension/DeviceActivityMonitorExtension.swift` (파일 내부 private enum)
    4. `ShieldConfigurationExtension` — 현재 App Group 접근 없음(정적 Shield UI 만)이라 중복 없음.
  - `interceptQueue` 키 문자열이 `PersistenceKeys.rawInterceptQueue` 와 `ShieldActionExtension/ExtensionAppGroup.swift::SharedKeys.interceptQueue` 두 곳.
  - `familySelection` 키 문자열이 `SharedKeys.familySelection` 과 `DeviceActivityMonitorExtension` 의 private `ExtensionSharedKeys.familySelection` 두 곳.
  - activity 이름 `block_main` / `temp_allow_` prefix 가 메인 앱 호출부 3개 파일(`OnboardingContainerView`, `DashboardView`, `SettingsView`) + `InterceptView` + `DeviceActivityMonitorExtension` 로 5곳에 리터럴 하드코딩.
- **이 리팩터가 MVP 완성도에 필요한가?** — **불필요**. Test Engineer 의 `UserDefaultsPersistenceStoreTests.testDrainInterceptQueue_decodesExtensionRawFormat` 와 `InterceptEventTests.testRawValueStability_*` 가 해당 계약을 **코드로 고정**하여 런타임 회귀 시 CI 에서 즉시 탐지 가능. 팀리더의 H2 승격 fix(`"primary"` → `"block_main"` 통일)도 완료되어 현재 상태에서 모든 이름이 일치. 리팩터는 Phase 5 `Project.yml` 수정(Extension 타깃 sources 에 `Core/Shared/AppGroup.swift` 개별 추가)으로 단독 수행이 정석. **[Phase 5 이월]**.

### C. 확장성 — 4.0 / 5

- `BlockingEngine` 프로토콜이 `applyWhitelist/clearShield/temporarilyAllow` 3메서드로 단순. Phase 5 의 **단계별 차단**(Lv.1~4) 추가 시 새 메서드 `applyProgressive(level:)` 를 추가하거나 파라미터로 level 을 받는 변형 메서드 한 개 추가면 수용 가능 — OCP 상 합격.
- `MonitoringEngine.startSchedule/stopMonitoring/startTemporaryAllow` 3메서드 역시 Phase 5 **주간 리포트**(`eventDidReachThreshold` 임계치 모니터링) 추가에 여지 있음.
- `Schedule` 모델에 `isEnabled` 가 이미 존재 — 엄격 모드(`strictMode: Bool`) 는 **Models/Schedule.swift** 에 필드 추가 + Codable 자동 처리로 1줄 변경.
- `InterceptEvent.EventType` 이 `enum String` + `@unknown default` 처리 경로로 새 케이스(`breath`, `sentence`, `goalRemind` variant) 추가에 열림.
- 감점: **나무 성장 / 주간 리포트 / 도파민 디톡스** 는 별도 Model/Persistence 가 필요(현재 `focusScoreToday: Int` 단일 스칼라만 존재). Phase 5 진입 시 `FocusDay` / `WeeklyReport` 엔트리 추가를 위한 SwiftData 마이그레이션 계획이 `docs/03_Architecture.md` 에 있으나, 현 PersistenceStore 프로토콜이 `Int` 단일 필드에 묶여 있어 도메인 타입 도입 시 프로토콜 확장이 큼. 단, 이는 Phase 5 설계 단계 작업이라 MVP R2 사유 아님.

### D. 테스트 가치 — 4.5 / 5

- 23 케이스가 **계약 테스트**로 설계됨:
  - `testDrainInterceptQueue_decodesExtensionRawFormat` — Extension 이 쓰는 `[[String: Any]]` 원시 포맷(키 `"interceptQueue"`, 필드 `timestamp`/`type`/`subjectKind`, rawValue `"returned"`/`"interceptRequested"`/`"application"` 등) 을 실제 dict 로 주입 후 `drainInterceptQueue()` 가 2건을 정확히 디코딩 + 큐 비움 검증 → **H1 회귀 시 즉시 탐지**.
  - `testDrainInterceptQueue_acceptsLegacySnakeCaseType` — `"intercept_requested"` snake_case 하위호환 계약.
  - `testRawValueStability_EventType` / `testRawValueStability_SubjectKind` — enum rawValue 문자열 고정.
  - `testScheduleRoundTrip_viaJSON` — 같은 suite 재생성 store 로 "앱 재시작" 시뮬레이션.
- 단순 getter/setter 수준이 아니라 **"Extension 측 Handler 수정 시 동시 수정 필요"** 라는 docstring 경고로 팀 계약을 명시.
- 미커버 영역이 `docs/06_Test_Report.md §5` 에 7개 리스트로 명시되고 각 항목이 "왜 단위 테스트 불가능한지" 이유 첨부 — Reviewer 관점에서 깔끔.
- 감점: **H4 회귀 방지**(`temp_allow_` prefix 문자열 일치)가 문자열 상수라 컴파일 타임 캐치 불가 — 현재 테스트 범위 밖. 단 `docs/06 §6` 에 "Phase 4 후반부/실기기 의존" 으로 명시 이월되었고, DeviceActivityCenter 는 실기기 전용이라 단위 테스트로 원칙적 재현 불가.
- 감점: `UserDefaultsPersistenceStoreTests` 가 시뮬레이터에서 `UserDefaults(suiteName:)` 이 nil 반환 가능성을 `!` 로 언래핑(test setUp 21행) — 테스트 코드 범위이니 관용 가능.

### E. UX 준수 — 4.5 / 5

- 흰색 바탕 일관: `AppColors.background = Color.white`, 모든 View 에서 `AppColors.background.ignoresSafeArea()` 로 명시.
- **명령형/느낌표 금지 규칙 준수 확인**:
  - ValueStep: "조금 쉬었다 갈까요", "10초의 쉼을 드려요." ✅
  - SystemPreset: "기본 앱은 항상 쓸 수 있어요" ✅
  - AppPicker: "꼭 필요한 앱만 남겨둬요" ✅
  - Schedule: "언제 쉬게 할까요", "나중에 언제든 바꿀 수 있어요." ✅
  - Authorization: "마지막 한 단계예요", "이 권한은 이 기기 안에서만 쓰입니다." ✅
  - Intercept: "잠깐 기다려봐요", "이 앱이 지금 꼭 필요한가요?" ✅
  - Shield: "잠시 멈춰요", "왜 이 앱을 열려고 했나요?" ✅ — 쟁점 1 따뜻한 톤.
  - InterceptView 비활성 부카피: "10초 뒤에 선택할 수 있어요" ✅ (느낌표 없음)
- 전체 소스 grep 결과 **느낌표(!) 카피 0건**. 명령형 "하세요"/"해주세요" 류 0건.
- **핵심 액션 유도 설계 준수**:
  - "돌아가기" → `PrimaryButton` (검은 배경 + 52pt 높이 + 흰 글자, 강조).
  - "그래도 열기" → `SecondaryLinkButton` (연회색 텍스트, 밑줄 없음, 15pt regular — 상대적 약함).
  - `canExit` false 일 때 버튼 disable + 투명도 40% 로 추가 억제.
- 쟁점 2 (앱 이름 노출 금지) 준수: `AllowedAppsCard` 는 "N개" 카운트만 표시, InterceptView 카피는 "이 앱이 지금 꼭 필요한가요?" 로 일반화.
- 감점: Authorization Denied 분기의 카피 "권한이 꺼져 있어요. 설정에서 허용을 켜주세요." 중 **"켜주세요"** 가 경계선 — 완곡 요청형으로 금지 규칙(명령형)에 아슬하게 걸림. 토론 여지 있으나 본 규칙의 엄격 해석이 아닐 경우 통과. **[R2 권장]** (카피 폴리싱, Phase 5 이월 가능).

### F. 안전성·정합성 — 4.0 / 5

- `fatalError` 사용: **1곳**, `Core/Shared/AppGroup.swift:8` — App Group entitlement 누락 시 즉시 crash. Debugger H7 에서 entitlement 등록 상태 검증됨, 리스크 관리됨. `os_log` 전환 권고는 Phase 5.
- `try!` / force unwrap 사용: 프로덕션 소스 **0건** (테스트 `setUp` 의 `!` 만). ✅
- 메모리 누수 점검:
  - `InterceptView` 의 `Timer` 는 `onDisappear { timer?.invalidate() }` + handler 에서 중복 invalidate(멱등). 리크 없음 (Debugger H5 증명).
  - `RootView` 의 `@State showIntercept` 는 `.sheet(isPresented:)` 바인딩으로 dismiss 시 자동 false. 큐 잔류 없음 (H6 증명).
  - `AppDependencies` 는 `@StateObject` 로 App 라이프사이클에 귀속, 단일 인스턴스. `ObservableObject` subscribers 누수 가능성 없음.
  - `ManagedSettingsBlockingEngine.monitoring` 이 `weak var` — 순환 참조 방지 확인.
- 권한 실패 복구 경로: `AuthorizationStepView` 에서 `denied` 상태 분기 + "설정으로 이동" + "다시 요청" 두 버튼 제공. `openSystemSettings()` 이 iOS 15+ 정상 동작 (Debugger H10).
- 감점: `UserDefaultsPersistenceStore` 의 인코딩 실패 silent 무시(`try?`) — Debugger H3 에서 이미 Phase 5 `os_log` 추가 권고로 이월. MVP 허용.

### G. 문서·개발자 경험 — 4.5 / 5

- `docs/` 01~06 흐름이 체계적: Xcode 셋업 → UX → Architecture → Integration → Debugger → Test. 07(이 문서) 가 마침표.
- `Tasklist.md` 의 "토론/이슈 로그" 14개 항목이 결정 근거/담당자/날짜 포함 — 신규 팀원이 README 없이도 문맥 복원 가능.
- `Project.yml` 실제 소스와 일치: 5개 타깃(메인 + 3 Extension + LockinFocusTests), 의존성 그래프, 스킴 설정 정확. `bundle.unit-test` 타깃의 `BUNDLE_LOADER`/`TEST_HOST` 환경변수 올바름. `LockinFocus` 타깃의 dependencies 에 3 Extension 모두 포함.
- 팀 명시 역할/Phase 상태가 Tasklist.md 상단에 단일 소스로 존재. ✅
- 감점: README 미작성(사용자 요청 시에만 생성 원칙이라 무관). 실기기 QA 체크리스트(`docs/05 §실기기 추가 검증`) 가 **Debugger 리포트 내부에만 존재** — Phase 5 진입 전 팀리더가 별도 `docs/08_Device_QA_Checklist.md` 로 승격하면 실기기 테스터에게 단독 전달 가능. 본 MVP R2 사유 아님.

---

## 2. 좋은 점 (TOP 5)

1. **H1 큐 스키마 계약을 실제 raw dict 주입 테스트로 고정** — `UserDefaultsPersistenceStoreTests.testDrainInterceptQueue_decodesExtensionRawFormat` 가 ShieldActionExtension enqueue 포맷을 하드코딩된 `[[String: Any]]` 로 재현하여 Extension 측 필드명/enum rawValue 변경 시 즉시 실패. Reviewer 가 본 가장 가치 있는 테스트.
2. **H4 Critical 의 1글자 Fix + H8 High 의 15줄 Fix** 가 Debugger 세션 내부에서 RETURN 없이 해결 — 설계자 복귀 사이클 미발생, 시간 경제성 우수.
3. **팀리더 H2 DEFER → 즉시 승격** — Debugger 가 실기기 1순위로 넘긴 activity 이름 불일치를 문서 커밋과 함께 3파일 동시 수정(`"primary"` → `"block_main"`) 으로 정합성 복원. 토론 로그 한 줄 기록.
4. **UX 카피 전량이 명령형/느낌표 규칙 준수** — 11개 뷰 전체 카피를 grep 해도 금지 카피 0건 (Authorization Denied 의 "켜주세요" 1건이 경계선이나 관용 가능).
5. **DI 품질** — `AppDependencies+Live.swift` 가 `#if targetEnvironment(simulator)` 분기로 Noop 주입, 실기기는 `bind(monitoring:)` 후주입으로 순환 회피. Preview/Noop/InMemory 세 종류의 Fake 가 모두 존재해 단위 테스트와 SwiftUI Preview 가 동일 프로토콜 경계를 공유.

---

## 3. 개선할 부분

- **App Group 상수·키·activity 이름의 소스 단일화** — 현재 메인 앱 `Core/Shared/AppGroup.swift` + ShieldActionExtension 의 `ExtensionAppGroup.swift` + DeviceActivityMonitorExtension 파일 내 private enum 3곳에 중복. 해법: `Project.yml` 에서 각 Extension 타깃의 `sources` 에 `LockinFocus/Core/Shared/AppGroup.swift` 를 개별 파일 참조로 추가. 현재 테스트 계약 + Debugger 검증으로 런타임 회귀 방어 중이라 MVP 배포 차단 아님. **[Phase 5 이월]**

- **AuthorizationStepView denied 카피 "켜주세요"** — 완곡 요청형이나 규칙 엄격 해석 시 명령형으로 해석 가능. 대안: "설정에서 허용이 꺼져 있어요." 로 선언형 변환. **[R2 권장]** — 본 라운드 R2 복귀 사유 아님, UX 폴리싱 성질이라 Phase 5 배치.

- **InterceptView Timer 의 백그라운드 복귀 품질(H5)** — 일부 iOS 버전에서 scheduled run loop 일시 정지 시 시각적 카운트 멈춤 가능. `Date` 기반 targetDate 모델로 전환 권고. **[Phase 5 이월]**

- **UserDefaults 인코딩/디코딩 silent 실패 로깅 부재(H3)** — 토큰 직렬화 실패 시 `os_log` 또는 OSLog 신호 추가. **[Phase 5 이월]**

- **`fatalError` 를 `os_log(.fault)` + 빈 `UserDefaults.standard` 폴백으로 완화** — 첫 launch 에서 Xcode 캐시 오염 시 crash 대신 degrade 경로 제공. **[Phase 5 이월]**

- **Phase 5 도입 시 PersistenceStore 프로토콜 확장 부담** — `focusScoreToday: Int` 단일 스칼라가 `FocusDay`/`WeeklyReport` 로 확장될 때 프로토콜 surface 증가. SwiftData 도입 시 별도 `AnalyticsStore` 분리를 제안. **[Phase 5 이월]**

- **실기기 QA 체크리스트 문서화** — `docs/05 §실기기 추가 검증` 7 항목을 `docs/08_Device_QA_Checklist.md` 로 승격. **[Phase 5 이월]**

개선 항목 총 7개 · `[R2 필수]` 0개 · `[R2 권장]` 1개 · `[Phase 5 이월]` 6개.

---

## 4. 결론

**최종 완료 — Phase 5 진입 권고.**

- Critical/High 잔존 없음 (H4 Critical / H8 High 모두 Debugger 세션에서 FIXED, 팀리더 H2 승격 Fix 반영).
- 23 테스트 케이스가 큐 스키마/Schedule/Onboarding 플래그/enum rawValue 회귀를 방어.
- UX 카피 규칙 준수. 흰색 배경·`PrimaryButton`/`SecondaryLinkButton` 계약 일관.
- 남은 개선 항목은 리팩터(Extension 소스 공유)·UX 카피 폴리싱·실기기 의존 검증·Phase 5 기능 확장 준비로, **지금 배포해도 MVP 목표(온보딩 → 차단/해제 경계 동작 → 5분 일시 해제 → 인터셉트 복귀)를 만족**.

R2 복귀 지시 없음. Architect/Coder-A/Coder-B 모두 Phase 5 설계 착수 가능. 단, 팀리더는 **실기기 수동 QA 7개 항목**(docs/05 §실기기 추가 검증) 을 배포 전 선결 실행 권고 — 이는 샌드박스 제약으로 자동화 불가한 단일 잔여 위험.
