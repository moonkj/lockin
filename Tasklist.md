# 락인 포커스 (Lockin Focus) — Tasklist

> 이 문서는 팀 전체가 진행 상태를 공유하는 단일 소스입니다. 각 팀원은 본인 작업 상태를 실시간으로 갱신합니다.

## 팀 구성
| 역할 | 담당 영역 |
|---|---|
| 팀리더 (Architect/Team Lead) | UX/UI 총괄, 통합, 최종 판단, process.md·Git 커밋 |
| (1) UX 설계자 | 유저 플로우, 화면 목표/액션, 예외 UX, 핵심 행동 우선순위 |
| (2) Architect | 요구사항 분석, 기술 스택/구현 단계 확정, 설계 요약 |
| Teammate 1 — Coder | Swift/SwiftUI 구현, 컨벤션 준수 |
| Teammate 2 — Debugger | 논리/실행/예외 점검, 수정 제안 |
| Teammate 3 — Test Engineer + Reviewer | 테스트 작성, 최종 품질 리뷰 (R2/R3 루프 주도) |
| Teammate 4 — Performance + Doc Writer | 성능·최적화, 최종 문서화 |

## 협업 규칙
1. 필요 정보는 상시 공유한다.
2. 문제 발생 시 **과학적 토론**: 서로 다른 측면 조사 → 발견 공유/반박 → 결론 도출.
3. **교차 레이어 조정**: 한 팀원 변경이 다른 쪽에 주는 영향을 실시간 공유.
4. **가설 검증**: 버그 원인 불분명 시 팀원 각자 다른 가설 검증.
5. 상태 갱신은 이 파일에, 단계별 결과는 `process.md`에.

---

## 진행 상태

### Phase 0 — 환경 세팅 ✅
- [x] 팀 역할 메모리 저장
- [x] 프로젝트 디렉토리 구조 생성
- [x] Tasklist.md 작성
- [x] process.md 작성
- [x] `tmux` 설치 + 8개 윈도우 시각화 세션 `lockin-focus`
- [x] Xcode 프로젝트 **xcodegen**으로 생성 (`LockinFocus.xcodeproj`) — 3 타깃(메인 + DeviceActivityMonitor + ShieldConfiguration)
- [x] Family Controls + App Group entitlement 파일 (3개 타깃 모두)
- [x] **iOS Simulator BUILD SUCCEEDED** (서명 없이 컴파일 검증 통과)
- [x] Git 초기화 + .gitignore + 첫 커밋
- [x] GitHub 원격 연결 (`origin → https://github.com/moonkj/lockin.git`) + `main` push

### Phase 1 — UX 설계 (UX Designer) ✅
- [x] 유저 시나리오 6개 (첫 실행·평시·차단 트리거·해제·주간 리포트·도파민 디톡스)
- [x] 화면 11개 와이어프레임 (온보딩 4 + 메인 7)
- [x] 핵심 행동 우선순위 TOP 3
- [x] 예외 UX (권한 거부, 빈 상태, 로딩, Nuclear 해제 시도 등)
- [x] Whitelist vs Blocklist 최종 권고 — **하이브리드** (기본 Whitelist, 도파민 디톡스는 Blocklist)
- [x] Architect 확인 요청 10개 항목 기재
- [x] 산출물: `docs/02_UX_Design.md` (824줄)

### Phase 2 — Architect 설계 ✅
- [x] iOS Screen Time API 제약 조사 (WWDC21/22 근거, JS 렌더 문서는 경험적 표기)
- [x] 인터셉트 경로 현실적 결론: Shield → ShieldAction → 메인 앱 딥링크
- [x] 모듈/타깃 구조: **3 Extension 필요 판정** → ShieldActionExtension 누락 식별
- [x] 상태 관리: App Group `UserDefaults` + Codable (MVP), SwiftData 는 확장
- [x] 산출물: `docs/03_Architecture.md` (860줄)
- [x] UX Designer에 11개 조율 요청 기재

### Phase 2.5 — 팀리더 통합 결론 ✅
- [x] 16개 쟁점 해결 (UX 10개 + Architect 11개 중복 제거)
- [x] MVP In/Out Scope 확정 (10개 In, 8개 Out → Phase 5)
- [x] ShieldActionExtension 타깃 추가 + 재빌드 BUILD SUCCEEDED
- [x] 공유 프로토콜/모델 스켈레톤: `Schedule`, `InterceptEvent`, `PersistenceStore`, `BlockingEngine`, `MonitoringEngine`
- [x] 산출물: `docs/04_Integration_Resolution.md`

### Phase 3 — MVP 구현 (Coder-A + Coder-B 병렬)

#### Coder-A (Core)
- [x] `Core/Persistence/UserDefaultsPersistenceStore.swift` — App Group + Codable
- [x] `Core/Persistence/InMemoryPersistenceStore.swift` — 시뮬레이터/테스트용 Fake
- [x] `Core/Persistence/PersistenceKeys.swift` — raw / codable 큐 키 분리
- [x] `Core/BlockingEngine/ManagedSettingsBlockingEngine.swift` — 역-화이트리스트 `.all(except:)`
- [x] `Core/BlockingEngine/NoopBlockingEngine.swift` — 시뮬레이터용
- [x] `Core/MonitoringEngine/DeviceActivityMonitoringEngine.swift`
- [x] `Core/MonitoringEngine/NoopMonitoringEngine.swift`
- [x] `Core/DI/AppDependencies+Live.swift` — 시뮬/실기기 분기 팩토리
- [x] DeviceActivityMonitorExtension 보강: `intervalDidStart` 에서 shield 적용, `temp_allow_*` 복원
- [x] ShieldActionExtension 상수 교체 (`AppGroup.identifier`, `SharedKeys.interceptQueue`)
- [x] "그래도 열기" — MVP 에선 Shield 전체 5분 해제로 단순화 (토큰 단위 해제는 Phase 5)
- [x] `xcodegen generate` + `xcodebuild` 빌드 검증 — **BUILD SUCCEEDED** (팀리더)

#### Coder-B (UI)
- [x] `Features/Onboarding/` 5 스텝 (Value / SystemPreset / Picker / Schedule / Authorization)
- [x] `Features/Dashboard/` 3요소 (집중 점수 / 허용 앱 / 다음 스케줄)
- [x] `Features/AppSelection/` FamilyActivityPicker 래퍼
- [x] `Features/Schedule/` 커스텀 편집 (요일 토글 + DatePicker)
- [x] `Features/Intercept/` countdown 10초 + "그래도 열기"(5분 전체 해제)
- [x] `Features/Settings/` 기본 (재선택/스케줄 편집/버전)
- [x] `Features/Shared/` PrimaryButton / SecondaryLinkButton
- [x] `App/RootView` 수정: 온보딩 여부 분기 + interceptQueue 자동 프레젠테이션
- [x] `App/LockinFocusApp` → **`AppDependencies.live()` 전환 완료** (팀리더)
- [x] **xcodegen 재생성 + iphonesimulator 빌드 검증** — BUILD SUCCEEDED

#### 교차 레이어 조정 규약
- 프로토콜 변경은 "토론/이슈 로그"에 즉시 기록.
- 공유 타입은 `Core/Models/`, `Core/Protocols/` 에만 추가.

### Phase 4 — Debugger → Test → Reviewer 사이클
- [x] **Debugger 1차 점검 완료** — `docs/05_Debugger_Report.md`. H4 Critical(activity 이름 1글자) + H8 High(온보딩 전환) 직접 Fix. BUILD SUCCEEDED.
- [x] **팀리더 H2 DEFER 승격 Fix** — Features 3곳 `"primary"` → `"block_main"` 통일. BUILD SUCCEEDED.
- [x] Test Engineer 단위/통합 테스트 작성 — `docs/06_Test_Report.md`. 5 파일 / 21 케이스. H1 회귀 방지 Extension 큐 스키마 계약 테스트 포함. Project.yml 에 `LockinFocusTests` 타깃 + test 스킴 추가. 샌드박스로 `xcodegen` / `xcodebuild test` 실행 차단 — 팀리더 수동 실행 대기.
- [x] **Reviewer 최종 리뷰 완료** — `docs/07_Review_Report.md`. A~G 영역 7점수 평균 4.3/5. Critical/High 잔존 없음. 개선 항목 7개 중 `[R2 필수]` 0개 / `[R2 권장]` 1개(Auth denied 카피 "켜주세요") / `[Phase 5 이월]` 6개(Extension 소스 공유 리팩터, Timer Date 기반 리팩터, os_log, fatalError 완화, PersistenceStore 확장, 실기기 QA 문서 승격). **결론: 최종 완료 — Phase 5 진입 권고**. R2 복귀 불요.

### Phase 5 — 확장 기능
- [ ] 4.3 게이미피케이션 (나무 성장, 에너지)
- [ ] 4.4 단계별 차단 (알림→반투명→흑백→완전)
- [ ] 4.5 엄격 모드 (30초 대기 + 문장 입력 + Face ID)
- [ ] 4.6 지연 해제 (10→30→60 점증)
- [ ] 4.8 데이터/인사이트 (일일 그래프, 주간 리포트)
- [ ] 7.3 도파민 디톡스 모드 (SNS/쇼핑 카테고리 자동분류 조사 결과 반영)
- [ ] 7.4 친구 경쟁 (후순위)

### Phase 6 — 성능 최적화 + 최종 문서화
- [ ] Performance Engineer 점검 (배터리, DeviceActivity 이벤트 효율, 리스트 렌더링)
- [ ] Doc Writer 최종 README + 기술 문서

---

## 토론/이슈 로그
형식: `[YYYY-MM-DD] [담당] [주제]` — 본문

- [2026-04-23] [Coder-A] [Extension 소스 공유 한계] — `ShieldActionExtension`, `DeviceActivityMonitorExtension` 타겟은 `LockinFocus/Core/Shared/AppGroup.swift` 를 공유하지 않는다. 지시대로 인라인 상수를 `AppGroup.identifier` 로 교체하기 위해 Extension 폴더 내부에 동명 enum (`AppGroup`, `SharedKeys`) 을 별도 파일로 추가하였음. 메인 앱 쪽 상수와 **값이 반드시 일치** 해야 하므로 리팩터 시 주의. 장기적으로는 `Core/Shared/AppGroup.swift` 파일을 3개 Extension 타겟 멤버십에도 추가하는 xcodegen 스펙 수정이 정답 (Tasklist의 ShieldActionExtension Info/entitlements 수정 없이 Project.yml 의 ShieldActionExtension.sources 에 `Core/Shared/AppGroup.swift` 를 개별 추가하면 됨).
- [2026-04-23] [Coder-A] [BlockingEngine.temporarilyAllow 한계] — `ShieldSettings.ActivityCategoryPolicy.all(except:)` 의 associated value 를 런타임에 역추출하는 공식 API 가 없어, 예외 토큰 머지 전략을 currentAllowedApplicationTokens() 에서 빈 셋 폴백으로 구현. 실제 구현에서는 호출부(ViewModel) 가 현재 `selection` 을 주입하거나 BlockingEngine 이 PersistenceStore 를 참조하도록 바꾸는 게 정석. 프로토콜 변경 없이 호환 유지하려면 `temporarilyAllow(token:for:)` 호출 전 `applyWhitelist(for:)` 로 갱신된 selection + 해당 토큰 union 을 먼저 재적용하는 래퍼 패턴을 Coder-B 가 ViewModel 레이어에서 사용할 것을 권장.
- [2026-04-23] [Coder-B] ["그래도 열기" MVP 단순화] — UX 문서는 "해당 앱만 5분 허용"을 요구하지만, Extension→App 큐에 `ApplicationToken` 을 Codable 로 안정 직렬화할 수 없는 한계 때문에 MVP InterceptView 에서는 `blocking.clearShield()` + `monitoring.startTemporaryAllow("tempAllowAll", 5분)` 으로 전체 Shield 를 5분간 해제 후 재적용한다. 특정 앱 한정 해제는 Phase 5 로 이월. 사용자 영향: "그래도 열기" 1회 누르면 허용 앱 외 모든 차단 앱이 5분간 열린다. UX 재검토 필요 시 "그래도 열기" 버튼 옆에 "5분간 모든 앱 열림" 서브카피 추가를 제안.
- [2026-04-23] [Coder-B] [live() 미반영] — 현재 `AppDependencies.live()` 가 Coder-A 리포에 아직 추가되지 않아 `LockinFocusApp.swift` 에서 `AppDependencies.preview()` 로 시작하도록 작성. Coder-A 의 `AppDependenciesLive.swift` 병합 후 `preview()` → `live()` 로 한 줄 교체 필요. (교체 포인트 `LockinFocus/App/LockinFocusApp.swift` 의 `@StateObject private var deps = AppDependencies.preview()`)
- [2026-04-23] [Coder-B] [xcodegen 재생성 필요 + 빌드 검증 불가] — Features/ 디렉토리와 Core/(Protocols|Models|DI|Persistence) 를 포함해 **현재 `project.pbxproj` 에 누락된 신규 Swift 파일 다수**. 본 에이전트는 샌드박스로 `xcodegen` / `xcodebuild` 실행 권한이 없어 재생성·빌드 검증을 수행하지 못했다. 팀리더/Debugger 가 프로젝트 루트에서 `xcodegen` 실행 후 `xcodebuild -project LockinFocus.xcodeproj -scheme LockinFocus -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build` 로 검증 필요. Project.yml 의 `sources: - path: LockinFocus` 재귀 매칭은 이미 올바르므로 추가 편집은 불요.
- [2026-04-23] [Coder-A] [빌드 검증 미완료] — 샌드박스에서 `xcodegen` / `xcodebuild` 실행이 거부됨. 새 파일이 `LockinFocus.xcodeproj/project.pbxproj` 에 반영되려면 `xcodegen generate` 재실행이 필요. 사용자/팀리더가 수동 실행 후 BUILD SUCCEEDED 확인 필요.
- [2026-04-23] [Debugger] [H1] Shield Extension ↔ 메인 앱 큐 스키마 일치 — 증명 (키 `interceptQueue`, 필드 timestamp/type/subjectKind, enum raw values 모두 일치). 위험 Low. 조치 없음.
- [2026-04-23] [Debugger] [H2] Extension 인라인 `AppGroup` / `SharedKeys` 값 일치 확인 — 증명. 단 부수 발견: 메인 앱이 `startSchedule(name: "primary")` 를 사용하지만 DeviceActivityMonitorExtension 은 `"block_main"` 만 인식 → 주 스케줄 종료 시 자동 shield 해제 경로 단절. DEFER, 실기기 검증 1순위.
- [2026-04-23] [Debugger] [H3] `FamilyActivitySelection` Codable round-trip — 불확실 (SDK 의존). 인/디코딩 실패 시 silent 폴백(set 스킵 / 빈 selection 반환) — 로그 부재. Low, Phase 5 os_log 권고.
- [2026-04-23] [Debugger] [H4] `temporarilyAllow(token:for:)` 는 MVP 플로우에서 호출되지 않아 영향 없음. 단 Critical 발견: `InterceptView.handleOpenAnyway()` 의 activity 이름 `"tempAllowAll"` 이 Extension prefix `"temp_allow_"` 와 불일치 → 5분 후 shield 재적용 미발생. FIXED (`"temp_allow_all"` 로 1글자 수정).
- [2026-04-23] [Debugger] [H5] InterceptView 10초 타이머 — Timer + onDisappear invalidate 로 메모리 누수 없음. 배경 복귀 시 리셋(팀 결정 일치). Medium, Phase 5 Date 기반 리팩터 권고.
- [2026-04-23] [Debugger] [H6] RootView drain 이중 트리거 — onAppear + scenePhase.active 가 2회 호출되지만 drain 이 UserDefaults 에서 즉시 비우므로 중복 프레젠테이션 없음. Medium→실질 Low.
- [2026-04-23] [Debugger] [H7] `AppDependencies.live()` 시뮬레이터 분기 — entitlement 등록 완료로 `UserDefaults(suiteName:)` nil 리스크 낮음. Medium.
- [2026-04-23] [Debugger] [H8] 온보딩 완료 후 RootView 전환 — High 버그 발견 (`hasOnboarded` @State 가 persistence 변경을 관측 못함). FIXED: RootView 가 `deps.persistence.hasCompletedOnboarding` 직접 참조 + `finishOnboarding()` 에서 `deps.objectWillChange.send()` 호출.
- [2026-04-23] [Debugger] [H9] ScheduleEditor 저장 경로 — Settings/Dashboard 모두 `save()` 에서 persistence + applyWhitelist + startSchedule 재호출. 정상. H2 의 activity 이름 불일치만 잔여 이슈. Low.
- [2026-04-23] [Debugger] [H10] 권한 거부 재시도 — `authorizationDenied` 플래그 + 설정 딥링크 + 재요청 버튼. 정상. Low.
- [2026-04-23] [팀리더] [H2 DEFER → Fix 승격] Debugger 가 DEFER 로 기록한 주 스케줄 activity 이름 불일치를 팀리더가 즉시 처리. 메인 앱 `Features/Dashboard/DashboardView.swift:87`, `Features/Settings/SettingsView.swift:112`, `Features/Onboarding/OnboardingContainerView.swift:139` 세 곳의 `name: "primary"` 를 `name: "block_main"` 으로 통일. Extension 의 prefix 규약과 일치하여 평일 17:00 종료 시 shield 자동 해제 경로가 복원됨. BUILD SUCCEEDED.
- [2026-04-23] [Test Engineer] [Phase 4 단위 테스트] `LockinFocusTests` 타깃 추가 + 5 파일 / 21 케이스 작성. **H1 회귀 방지 핵심**: `UserDefaultsPersistenceStoreTests.testDrainInterceptQueue_decodesExtensionRawFormat` 가 ShieldActionExtension 이 쓰는 `[[String: Any]]` raw 포맷(키 `interceptQueue`, 필드 timestamp/type/subjectKind, enum rawValue) 을 코드로 고정. `InterceptEventTests` 가 enum rawValue 문자열(`"returned"`, `"interceptRequested"`, `"application"`, `"category"`, `"webDomain"`) 변경을 즉시 감지. `UserDefaultsPersistenceStore.init(defaults:)` 주입 이니셜라이저 기존 존재 확인, Coder-A 복귀 불필요. 샌드박스로 `xcodegen` / `xcodebuild test` 실행 차단 — 팀리더 수동 실행 필요.
- [2026-04-23] [Reviewer] [Phase 4 후반부 최종 리뷰 — 초회] `docs/07_Review_Report.md`. A 가독성 4.5 / B 유지보수성 4.0 / C 확장성 4.0 / D 테스트 가치 4.5 / E UX 준수 4.5 / F 안전성 4.0 / G 문서 4.5. Critical/High 잔존 없음. 개선 7개 중 `[R2 필수]` 0건. 결론: **최종 완료 — Phase 5 진입 권고**. 배포 전 선결 잔여 위험 = 실기기 수동 QA 7 항목(docs/05 §실기기 추가 검증). R2 복귀 불요.
