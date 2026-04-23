# 락인 포커스 — Process Log

> 팀리더(Architect)가 각 구현 단계마다 갱신합니다. 단계별 결과/의사결정/Git 커밋 기록.

## 2026-04-23 — Phase 0 개시

### 팀 구성 확정
- 팀리더 + UX / Architect / Coder / Debugger / Test+Reviewer / Performance+Doc 7개 역할.
- 사용자 결정: **tmux 세션 + Agent 도구 병렬** 둘 다 사용. **Xcode GUI**로 프로젝트 생성. **Apple Developer 유료 계정 보유**, Family Controls entitlement 신청 가능.

### 환경 세팅
- 메모리: `user_profile.md`, `agent_team_roles.md`, `project_lockin_focus.md` 저장.
- 워크스페이스: `/Users/kjmoon/Lockin Focus/docs/` 생성.
- Tasklist.md, process.md 초안 작성.
- tmux 설치 진행 중 (`brew install tmux`).

### 병렬 실행 개시
- UX Designer 에이전트: `docs/02_UX_Design.md` 산출.
- Architect(리서치) 에이전트: `docs/03_Architecture.md` 산출 — iOS Screen Time API 제약 & 모듈 구조.
- 사용자: `docs/01_Xcode_Setup_Guide.md` 따라 Xcode 프로젝트 생성.

### 2026-04-23 — Phase 0 완료 + Phase 1 완료

#### Xcode 프로젝트 (GUI 대신 CLI 자동화로 대체)
- 사용자 지시에 따라 `xcodegen`으로 프로젝트 생성.
- `Project.yml`: 3 타깃 (메인 `LockinFocus` + `DeviceActivityMonitorExtension` + `ShieldConfigurationExtension`).
- Deployment Target iOS 16.0, Bundle prefix `com.imurmkj`.
- 3개 entitlements 파일 모두 `com.apple.developer.family-controls` + App Group `group.com.imurmkj.LockinFocus` 포함.
- 스캐폴드 코드: `LockinFocusApp`, `RootView`, `AppColors`(흰색 기반), `AppGroup`, `DeviceActivityMonitorExtension`, `ShieldConfigurationProvider`.
- Assets.xcassets (AppIcon, AccentColor) 기본 구조.

#### 빌드 검증
- `xcodebuild -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build` → **BUILD SUCCEEDED**.
- 3 타깃 모두 컴파일 성공. 시뮬레이터에서 Family Controls 실 동작은 안 되지만, 컴파일·연결 레벨의 구조는 확정.

#### UX Designer 산출물 — `docs/02_UX_Design.md` (824줄)
- 화면 11개 + 시나리오 6개 + 예외 UX + 디자인 토큰.
- **Whitelist vs Blocklist 권고**: 기본 Whitelist + 도파민 디톡스만 Blocklist (하이브리드).
- Architect에게 **10개 기술 확인 요청** 남김 (Shield Action 딥링크, bundle ID 식별, Whitelist API 가능성 등) — Phase 2에서 답변 필수.

#### Git
- `git init`, 브랜치 `main`, `.gitignore` 추가.
- 첫 커밋 생성.

### 2026-04-23 — Phase 2+2.5 완료

#### Architect 산출물
- `docs/03_Architecture.md` (860줄, WWDC21/22 근거).
- 역-화이트리스트 (`.all(except:)`), Shield 를 1차 인터셉트로, ShieldAction 경유 딥링크 경로.
- UX 에 11개 조율 요청.

#### 팀리더 통합 결론
- `docs/04_Integration_Resolution.md`: UX 10개 + Architect 11개 → 16개 쟁점 정리, 중복 제거.
- MVP In Scope 10개, Out Scope(Phase 5) 8개 확정.
- **ShieldActionExtension 타깃 신규 추가** (Project.yml 갱신, 4 타깃 빌드 통과).
- 공유 프로토콜/모델: `Schedule`, `InterceptEvent`, `PersistenceStore`, `BlockingEngine`, `MonitoringEngine`.
- DI 컨테이너: `AppDependencies` + `preview()` Mock (Coder-B가 Coder-A 완료를 기다리지 않고 병렬 빌드 가능하도록).
- 커밋 `f448fb6`.

#### GitHub 연동
- 원격 `origin → https://github.com/moonkj/lockin.git` 연결.
- `main` 브랜치 push 완료 (커밋 7a6b738, f448fb6).

### Phase 3 개시 (현재)
- Coder-A 에이전트: Core 실구현 (Persistence/Blocking/Monitoring + Extension 보강 + live() 팩토리) 백그라운드 진행.
- Coder-B 에이전트: UI 전체 (온보딩 5스텝 / 대시보드 3요소 / 앱선택 / 스케줄 / Intercept 10초 / 설정) 백그라운드 진행.
- 파일 영역 완전 분리 (Core ↔ Features) + 프로토콜 고정 → 병렬 충돌 없음.

### 2026-04-23 — Phase 3 완료

#### Coder-A 산출 (Core)
- Persistence: `UserDefaultsPersistenceStore` (App Group + Codable), `InMemoryPersistenceStore`, `PersistenceKeys` (raw / codable 큐 키 분리).
- Blocking: `ManagedSettingsBlockingEngine` (`.all(except:)`), `NoopBlockingEngine`.
- Monitoring: `DeviceActivityMonitoringEngine` (`DeviceActivityCenter` 래핑), `NoopMonitoringEngine`.
- DI: `AppDependencies+Live.swift` 팩토리 (시뮬레이터는 Persistence 실, Shield/Monitor Noop).
- DeviceActivityMonitorExtension: `block_main` 시작 시 selection 디코딩 → `.all(except:)` 적용, `temp_allow_*` 종료 시 주 shield 복원.
- ShieldActionExtension: raw 상수 → `AppGroup.identifier`/`SharedKeys.interceptQueue`.
- 토론 로그 3건 등록 (Extension 소스 공유 리팩터, temporarilyAllow 래핑, 빌드 검증 권한).

#### Coder-B 산출 (UI)
- 18 파일 — Onboarding 5 step, Dashboard 3 card, AppSelection, Schedule, Intercept(10초 countdown), Settings, Shared 버튼 2종.
- RootView: 온보딩 분기 + `scenePhase`/`onAppear` 에서 `drainInterceptQueue()` → `InterceptView` sheet 자동 프레젠테이션.
- 모든 뷰 `#Preview` 포함, AppColors 팔레트만 사용(흰색 기반).
- "그래도 열기" MVP 단순화: ApplicationToken 직렬화 한계로 **Shield 전체 5분 해제 + 자동 재적용**. 토큰 단위 단일 해제는 Phase 5.

#### 팀리더 통합 검증
- `xcodegen generate` → 36 Swift 파일 전부 xcodeproj 등록.
- `xcodebuild ... -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build` → **BUILD SUCCEEDED** (preview/live 양쪽).
- `LockinFocusApp.swift` `AppDependencies.preview()` → `.live()` 스위치, 재빌드 SUCCEEDED.

#### 보류/후속 이슈 (Tasklist 토론 로그에 모두 등록됨)
1. Extension 3개가 `Core/Shared/AppGroup.swift` 를 공유하도록 Project.yml sources 확장 (현재는 Extension 별 중복 정의, 값 불일치 리스크) — Phase 5 리팩터.
2. `BlockingEngine.temporarilyAllow(token:for:)` 의 policy associated value 역추출 한계 → ViewModel 에서 `applyWhitelist + temp allow` 래퍼 패턴 권장.
3. "그래도 열기" 토큰 단위 단일 해제 → Phase 5.
4. UX 재확인: "그래도 열기" 서브카피 ("5분간 모든 차단 앱 열림" 고지 필요?), ValueStep 카피 톤 대조.

### 다음 (Phase 4)
Debugger 에이전트 투입 → Core 로직 점검 (특히 Extension 이벤트 시퀀스·Codable round-trip·ViewModel 래퍼 필요성). 이후 Test Engineer 단위 테스트 작성.
