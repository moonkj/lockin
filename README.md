# 락인 포커스 (Lockin Focus)

> 손이 움직이기 전에 생각하게 만드는 iOS 집중 강화 앱.

![iOS](https://img.shields.io/badge/iOS-16%2B-black)
![Swift](https://img.shields.io/badge/Swift-5.9-F05138)
![UI](https://img.shields.io/badge/UI-SwiftUI-0091FF)
![FamilyControls](https://img.shields.io/badge/FamilyControls-individual-4B7BEC)
![Status](https://img.shields.io/badge/status-MVP%20complete-2E7D57)

---

## 이 앱이 하는 일

락인 포커스는 사용자가 SNS/쇼핑 앱을 **무의식적으로 열기 전에** 10초의 자각 공간을 만든다.
설계 철학은 세 겹이다.

1. **충동(Impulse)** — 손가락이 아이콘으로 향한다.
2. **인지(Awareness)** — iOS Shield 가 먼저 끼어들어 "왜 열려 해요?" 라고 묻는다.
3. **선택(Choice)** — 10초 카운트다운 뒤에 사용자가 돌아갈지 계속할지 **직접** 선택한다.

이 앱은 "차단"을 목표로 하지 않는다. 사용자가 **자기 행동을 한 번 보게 만드는 것**이 목표다.
그래서 허용할 앱 3–10개만 사용자가 고르게 하고 (역-화이트리스트 전략),
나머지는 iOS Shield 로 일괄 막은 뒤, Shield 버튼 탭 → 메인 앱 중간 인터셉트 UI 로 유도한다.
사용자는 언제든 "그래도 열기" 로 5분간 전체 해제할 수 있다. **금지가 아니라 재질문.**

---

## 현재 상태

MVP 완성 (Phase 3 구현 + Phase 4 디버그/테스트/리뷰 완료).
리뷰어 결론: **최종 완료 — Phase 5 진입 권고**. 잔여 위험은 실기기 수동 QA 7 항목뿐이며
이는 DeviceActivity·Shield 프레임워크가 시뮬레이터에서 동작하지 않는 구조적 제약에서 기인한다.

---

## 주요 기능 (MVP In Scope)

1. 5 스텝 온보딩 (가치 제안 / 기본 프리셋 / 허용 앱 선택 / 스케줄 / 권한 요청)
2. 홈 대시보드 3요소 (오늘 집중 점수 / 허용 앱 / 다음 스케줄)
3. 허용 앱 재선택 (`FamilyActivityPicker` 래퍼)
4. 스케줄 편집 (3 프리셋 + 요일·시간 커스텀)
5. 10 초 카운트다운 인터셉트 뷰 (`InterceptView`)
6. 따뜻한 톤의 Shield 카피 (`ShieldConfigurationExtension`)
7. Shield 버튼 → 인터셉트 큐 적재 (`ShieldActionExtension`)
8. DeviceActivityMonitor 로 스케줄 경계에서 자동 shield 적용/해제
9. "그래도 열기" → 5 분 전체 해제 후 자동 재차단
10. 권한 거부 복귀 플로우 (설정 앱 딥링크 + 재요청)

---

## Phase 5 이월 (확장 기능)

다음 항목은 의도적으로 MVP 에서 제외되었으며 Phase 5 에서 사용자의 판단에 따라 착수 여부를 결정한다.

1. 인터셉트 variant 3종 (breath / sentence / goalRemind)
2. 단계별 차단 레벨 (Lv.1 알림 → Lv.4 완전)
3. 엄격(Nuclear) 모드 (30초 대기 + 문장 입력 + Face ID)
4. 지연 해제 점증 (10 → 30 → 60초)
5. 나무 성장 / 게이미피케이션
6. 주간 리포트
7. 도파민 디톡스 모드 (SNS/쇼핑 카테고리 일괄)
8. 친구 경쟁

---

## 기술 스택

- **언어/UI**: Swift 5.9 · SwiftUI
- **최소 버전**: iOS 16.0 (`AuthorizationCenter.requestAuthorization(for: .individual)` 가 iOS 16+ 요구)
- **핵심 프레임워크**:
  - `FamilyControls` — 권한 승인, `FamilyActivityPicker`, `FamilyActivitySelection`
  - `ManagedSettings` — Shield 정책 적용 (`.all(except:)` 역-화이트리스트)
  - `DeviceActivity` — 스케줄 모니터링, 일시 해제 타이머
- **상태 저장**: App Group `UserDefaults` + `Codable` (MVP 단일 전략)
- **DI**: `AppDependencies` (ObservableObject) — live / preview / simulator 분기
- **빌드 도구**: XcodeGen (`Project.yml` → `LockinFocus.xcodeproj`)
- **테스트**: XCTest 23 케이스 (`LockinFocusTests` 타깃)

---

## 프로젝트 구조

```
Lockin Focus/
├── LockinFocus/                     # 메인 앱 타깃 (iOS 16+)
│   ├── App/                         # LockinFocusApp (@main), RootView
│   ├── Core/
│   │   ├── BlockingEngine/          # ManagedSettings 래퍼 + Noop
│   │   ├── DI/                      # AppDependencies (live/preview)
│   │   ├── Models/                  # Schedule, InterceptEvent
│   │   ├── MonitoringEngine/        # DeviceActivityCenter 래퍼 + Noop
│   │   ├── Persistence/             # PersistenceStore (UserDefaults/InMemory)
│   │   ├── Protocols/               # 3 engines 의 프로토콜 경계
│   │   ├── Shared/                  # AppGroup, SharedKeys
│   │   └── Theme/                   # AppColors, AppTypography, AppSpacing
│   ├── Features/
│   │   ├── AppSelection/            # FamilyActivityPicker 래퍼
│   │   ├── Dashboard/               # 집중 점수 · 허용 앱 · 다음 스케줄
│   │   ├── Intercept/               # 10초 카운트다운
│   │   ├── Onboarding/              # 5 스텝 + Steps/
│   │   ├── Schedule/                # 요일·시간 편집
│   │   ├── Settings/                # 재선택 / 편집 / 버전
│   │   └── Shared/                  # PrimaryButton, SecondaryLinkButton
│   └── Resources/                   # Assets.xcassets
├── DeviceActivityMonitorExtension/  # interval start/end 훅
├── ShieldConfigurationExtension/    # Shield UI 카피/아이콘
├── ShieldActionExtension/           # Shield 버튼 탭 처리 + 큐 적재
├── LockinFocusTests/                # XCTest 23 cases (5 files)
├── docs/                            # 설계·토론 문서 01–09
├── scripts/                         # 헬퍼 스크립트
├── Project.yml                      # XcodeGen 스펙
└── Tasklist.md                      # 팀 진행/토론 로그
```

### 타깃 구조

| 타깃 | 종류 | 목적 |
|---|---|---|
| `LockinFocus` | application | 메인 앱 (UI + Core) |
| `DeviceActivityMonitorExtension` | app-extension | 스케줄 경계 훅 |
| `ShieldConfigurationExtension` | app-extension | Shield 화면 UI 구성 |
| `ShieldActionExtension` | app-extension | Shield 버튼 탭 처리 |
| `LockinFocusTests` | bundle.unit-test | 단위/계약 테스트 |

네 타깃 전체가 App Group `group.com.imurmkj.LockinFocus` 를 공유한다.

---

## 빠른 시작 (개발자)

필수:
- Xcode 16+ / macOS Sonoma 이상
- Apple Developer 계정 (실기기 배포를 위해서는 Family Controls capability 필요, 무료 계정으로는 불가)

```bash
# 1. XcodeGen 설치 (Homebrew)
brew install xcodegen

# 2. 프로젝트 생성
cd "/path/to/Lockin Focus"
xcodegen generate

# 3. 시뮬레이터 빌드 (서명 생략)
xcodebuild -project LockinFocus.xcodeproj \
           -scheme LockinFocus \
           -sdk iphonesimulator \
           -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
           CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
           build
```

시뮬레이터에서는 `AppDependencies.live()` 가 `#if targetEnvironment(simulator)` 분기로
`NoopBlockingEngine` / `NoopMonitoringEngine` 을 주입하므로
UI 흐름은 동작하지만 실제 Shield 는 뜨지 않는다. Shield·DeviceActivity 검증은 **실기기 전용**이다.

### Xcode 로 열기

```bash
open LockinFocus.xcodeproj
```

`DEVELOPMENT_TEAM` 은 `Project.yml` 기본값이 비어 있어 Xcode 에서 본인 팀을 지정해야 한다.

---

## 테스트 실행

```bash
xcodebuild -project LockinFocus.xcodeproj \
           -scheme LockinFocus \
           -sdk iphonesimulator \
           -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
           CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
           test
```

- 총 23 케이스 / 5 파일.
- 핵심 회귀 방지 테스트:
  `UserDefaultsPersistenceStoreTests.testDrainInterceptQueue_decodesExtensionRawFormat`
  — ShieldActionExtension 이 쓰는 `[[String: Any]]` 원시 큐 포맷을 실제 dict 로 주입하여
  메인 앱 디코딩 경로를 계약 테스트로 고정.

---

## Family Controls Entitlement 신청

- **개발용**: Xcode 에서 Target → Signing & Capabilities → `+ Capability` → Family Controls 추가.
  본인 팀의 개발 provisioning 으로 즉시 실기기 설치 가능.
- **배포용**: App Store 배포 시 Apple 에 별도 신청 필요.
  → [developer.apple.com/contact/request/family-controls-distribution](https://developer.apple.com/contact/request/family-controls-distribution)
  승인 소요 수 일 ~ 수 주. 신청서에는 앱 목적, 스크린샷, 허위 사용 방지 정책을 기재한다.

---

## 실기기 QA 체크리스트 (배포 전 필수)

시뮬레이터에서 자동화 불가능한 항목이다. 실기기 3 – 5 대에서 순차 확인한다.
상세는 `docs/05_Debugger_Report.md` §실기기 추가 검증 및 `docs/09_Release_Checklist.md`.

- [ ] **주 스케줄 경계 자동 해제** — 평일 17:00 종료 시 Shield 가 자동 해제되는가 (`block_main` 경로)
- [ ] **ShieldAction → 메인 앱 자동 포그라운드화** — `NSExtensionContext.open(_:)` 동작 여부
- [ ] **FamilyActivitySelection Codable round-trip** — Extension 과 메인 앱 간 토큰 동일성
- [ ] **`.all(except:)` 시스템 앱 영향** — 전화·메시지·설정이 실수로 차단되지 않는지
- [ ] **"그래도 열기" 5분 해제 후 자동 재차단 정확도** — `temp_allow_*` 종료 시 shield 복원
- [ ] **권한 재요청 플로우** — `.denied` 상태에서 설정 앱 딥링크 → 재승인 → 앱 복귀 시 상태 갱신
- [ ] **Timer 백그라운드 복귀** — 인터셉트 뷰에서 홈 내렸다가 복귀 시 카운트다운 품질

---

## 팀 에이전트 파이프라인

본 프로젝트는 6 인의 역할 분담 기반 에이전트 협업으로 구축되었다.

| 역할 | 담당 | 산출물 |
|---|---|---|
| 팀리더 (Architect/Lead) | 통합, 최종 판단, 커밋 | `docs/04_Integration_Resolution.md` |
| UX Designer | 유저 플로우, 화면, 예외 UX | `docs/02_UX_Design.md` |
| Architect | 기술 스택, 제약 조사, 모듈 구조 | `docs/03_Architecture.md` |
| Coder-A (Core) | Persistence / BlockingEngine / MonitoringEngine / Extension | — |
| Coder-B (UI) | Onboarding / Dashboard / Intercept / Schedule / Settings | — |
| Debugger | 10 가설 점검, 논리·실행·예외 수정 | `docs/05_Debugger_Report.md` |
| Test Engineer | 23 케이스 단위/계약 테스트 | `docs/06_Test_Report.md` |
| Reviewer | A~G 7 영역 최종 리뷰 | `docs/07_Review_Report.md` |
| Doc Writer | 최종 문서 정리 (본 README 포함) | `docs/08_Architecture_Map.md`, `docs/09_Release_Checklist.md` |

진행 상태 및 토론 로그는 [`Tasklist.md`](Tasklist.md) 참고.
Xcode 셋업 절차는 [`docs/01_Xcode_Setup_Guide.md`](docs/01_Xcode_Setup_Guide.md).

---

## 핵심 설계 결정 요약

### 역-화이트리스트 전략 (`.all(except:)`)

사용자 요구는 "허용 앱 N개만 남기고 나머지 전부 차단"이지만
Apple 의 `FamilyActivitySelection` 은 기본적으로 blocklist 구조다.
해법: `ManagedSettingsStore.shield.applicationCategories = .all(except: selection.applicationTokens)`
로 **카테고리 전체를 차단 + 사용자가 고른 앱만 예외**.
설치 앱을 enumerate 하는 API 가 없으므로 이 패턴이 whitelist 의 **유일한 근사**다.
시스템 앱(전화·메시지·설정) 일부가 카테고리 밖이라 차단되지 않을 가능성이 있어
온보딩 Step 2 에서 "기본 프리셋" 안전판을 제공한다.

### Shield 가 1차 인터셉트 (ShieldAction → queue-and-poll)

앱이 열리기 "직전"에 우리 뷰를 삽입하는 공식 API 는 존재하지 않는다.
현실 경로는 **Shield → 버튼 탭 → ShieldAction Extension → App Group 큐 적재 → 메인 앱 포그라운드 진입 시 큐 drain → InterceptView 자동 프레젠테이션**.
Shield 자체가 이미 1단계 인지 개입이며, Shield 카피를 따뜻하게 디자인해 UX 손실을 최소화했다.

### 3 Extension 타깃

Apple 의 Screen Time 확장 포인트는 서로 독립이다.
`DeviceActivityMonitorExtension` 이 스케줄 경계 훅을, `ShieldConfigurationExtension` 이 Shield UI 를,
`ShieldActionExtension` 이 버튼 탭을 각각 담당한다.
Phase 2 설계 시 `ShieldActionExtension` 이 누락된 것을 팀리더가 식별, Phase 2.5 에서 추가했다.

### App Group 기반 상태 공유

Extension ↔ 메인 앱 간 상시 공유 채널은 `UserDefaults(suiteName: group.com.imurmkj.LockinFocus)` 가
1 순위이며, `FamilyActivitySelection` 의 `Codable` 준수를 활용해 JSON 직렬화한다.
쓰기 가시성은 1 – 3 초 지연 허용으로 설계 (실시간 push 불필요).
키 상수는 현재 메인 앱 + 2 Extension 에 중복 선언되어 있으며, 23 테스트 케이스가 계약 회귀를 방어한다.
소스 단일화 리팩터는 Phase 5 로 이월.

---

## 알려진 한계

아직 해결되지 않은 이슈 (Tasklist.md 토론 로그 기반).

- **App Group 상수·키·activity 이름이 4 곳에 중복 선언**. 테스트 계약으로 런타임 회귀는 방어 중이나
  리팩터는 Phase 5 `Project.yml` 수정(Extension sources 에 `Core/Shared/AppGroup.swift` 개별 추가) 필요.
- **`ManagedSettingsBlockingEngine.temporarilyAllow(token:for:)`** — `.all(except:)` 의
  associated value 를 런타임에 역추출할 공식 API 가 없어 토큰 단위 해제가 어려움.
  MVP 는 "전체 5 분 해제 + 자동 재차단"으로 단순화. Phase 5 에서 ViewModel 쪽 현재 selection 주입 래퍼 필요.
- **InterceptView Timer** 가 `Timer.scheduledTimer` 기반. 일부 iOS 버전에서 백그라운드 복귀 시
  RunLoop 일시 정지로 시각적 카운트가 멈출 수 있음. Phase 5 에서 `Date` targetDate 모델 권고.
- **UserDefaults 인/디코딩 실패가 silent**. `os_log` 로 관측성 추가 권고 (Phase 5).
- **시뮬레이터에서 Shield/DeviceActivity 미동작**. 구조적 제약이라 해결 불가. 실기기 QA 필수.

---

## 라이선스

TBD — 사용자 결정 예정.

---

## 기여자

- [@moonkj](https://github.com/moonkj) — 제품 오너
- Claude Code 에이전트 팀 (UX / Architect / Coder-A / Coder-B / Debugger / Test+Reviewer / Doc Writer)
