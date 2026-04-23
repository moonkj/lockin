# 04 — 팀리더 통합 결론 (UX ↔ Architect 과학적 토론)

> 작성: 팀리더 (Architect/Team Lead) · 2026-04-23
> 입력: `docs/02_UX_Design.md` §7 (10개 질문) + `docs/03_Architecture.md` §7 (11개 조율) + UX §5 (충돌/트레이드오프)
> 목적: 충돌 해소, 합의 사항 확정, Coder 착수 가능한 MVP 범위 확정.

---

## 0. 요약

두 산출물은 **병렬 작성되었음에도 핵심 경로에서 우연한 합의**에 도달했다.

| 지점 | UX 문서 | Architect 문서 | 결과 |
|---|---|---|---|
| 차단 전략 | `shield.applicationCategories = .all(except:)` 언급 | 동일 전략 정식 제안 | ✅ 일치 |
| 인터셉트 경로 | "경로 1만 신뢰 가능" (Shield→딥링크) | 동일 | ✅ 일치 |
| 저장소 | App Group `UserDefaults` 기본 | 동일 + 확장 SwiftData | ✅ 일치 |
| 온보딩 스텝 | 4 스텝 | 4 스텝 | ✅ 일치 |

충돌은 **해석 차이**(ex. 인터셉트 화면의 위치 해석) 수준. 기술적 모순은 없음. 팀리더가 16개 쟁점을 모두 정리하여 Coder 단계 착수를 가능하게 한다.

---

## 1. 쟁점별 결론 (총 16개)

### 쟁점 1 — Shield "전" 인터셉트 삽입
**결론: 불가능. UX 스토리보드를 "Shield 이후 인터셉트"로 수정.**
- 흐름: 차단앱 실행 → **Shield 1차 개입** (카피 "잠깐 멈춰요") → 버튼 탭 → **메인 앱 InterceptView** → 10초 카운트다운 → 선택.
- Shield 자체가 이미 심리 개입의 1단계다. Shield 카피를 따뜻하게 디자인.

### 쟁점 2 — 차단 앱 bundle ID 식별 (UX-Q2)
**결론: 불가능. 카피 일반화.**
- `ApplicationToken`은 암호화된 불투명 값이며 bundle ID 노출은 Apple 정책 금지.
- InterceptView 카피: `"Instagram이 지금…"` ❌ → `"이 앱이 지금 필요한가요?"` ✅
- 앱 아이콘은 Shield가 대신 보여준다 → 사용자는 여전히 시각적으로 식별.

### 쟁점 3 — 인터셉트 variant MVP 종류 (Architect-Q8)
**결론: MVP는 countdown(10초) 단 1종. 나머지는 Phase 5.**
- Phase 3 목표: "end-to-end 인터셉트 동작"의 실기기 검증.
- breath / sentence / goalRemind 는 `InterceptVariant` enum 만 미리 정의해두고 UI는 Phase 5.

### 쟁점 4 — 단계별 차단 Lv.1~4 (UX §5.2 + Architect-Q7)
**결론: 전부 Phase 5로 이동. MVP는 "켬/끔 2단계".**
- Lv.3 흑백 필터는 iOS Color Filter 프로그래밍 토글 불가 → 앱 내 반투명 오버레이로 축소.
- MVP 상태기: `isBlocking: Bool`.

### 쟁점 5 — "그래도 열기" 임시 허용 (UX-Q5 + Architect-Q5)
**결론: 5분 일시 해제 + 자동 재차단 (MVP 기본값).**
- 구현: `ManagedSettingsStore.shield.applications` 에서 해당 토큰만 일시 제거 → `DeviceActivityCenter.startMonitoring(...)` 로 5분 타이머 → `intervalDidEnd` 에서 재추가.
- 1/5/15분 선택 UI는 Phase 5.

### 쟁점 6 — 시스템 앱 기본 허용 (Architect-Q3)
**결론: 온보딩 Step 2 "기본 프리셋" 추가.**
- 기본 체크 해제 불가 앱(보호 필수): 전화 / 메시지 / 설정.
- 기본 체크, 해제 가능: 시계 / 지도 / 카메라.
- 이 스텝은 **FamilyActivityPicker 진입 전**에 등장.

### 쟁점 7 — 도파민 디톡스 (UX 시나리오 F + Architect-Q4)
**결론: Phase 5. MVP 제외.**
- 카테고리 자동분류 불가. 사용자 수동 Picker 필요.
- MVP에서는 enum case 만 선언 (`enum PresetMode { case whitelist, dopamineDetox }`).

### 쟁점 8 — 엄격(Nuclear) 모드 (UX §4.5 + Architect-Q7)
**결론: Phase 5.**
- 30초 대기 + 문장 입력 + Face ID 재인증은 UX 무게가 MVP 대비 과도.
- 토글 필드만 모델에 미리 둠(`strictMode: Bool`).

### 쟁점 9 — 주간 리포트 알림
**결론: Phase 5.**
- 첫 주는 데이터 없음. `UNCalendarNotificationTrigger(일요일 20:00, repeats: true)` 레퍼런스 구현은 준비.

### 쟁점 10 — App Group 동기화 지연 (UX-Q9 + Architect)
**결론: 배치 허용 (1–3초 지연 OK).**
- Extension에서 큐 쓰기 → 메인 앱이 포그라운드 진입 시 일괄 읽기.
- 실시간 push 불필요.

### 쟁점 11 — 시뮬레이터 QA 전략 (UX-Q10 + Architect 부록 B)
**결론: Shield/DeviceActivity는 실기기 전용. 시뮬레이터에선 SwiftUI 뷰 디자인 QA만.**
- `BlockingEngine`, `MonitoringEngine`을 프로토콜로 분리 → 시뮬레이터용 Fake 주입.
- `#if targetEnvironment(simulator)` 분기는 최소화, 대신 DI로 해결.

### 쟁점 12 — 권한 거부 UX (Architect-Q6)
**결론: UX §4.1 유지.**
- `UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)` 로 설정 앱 딥링크 + "다시 요청" 버튼.

### 쟁점 13 — 온보딩 스텝 수 (UX §1.A + Architect-Q9)
**결론: 5 스텝.**
1. 가치 제안 (Hero)
2. 기본 프리셋 허용 (시스템 앱 안전판)
3. 허용 앱 선택 (FamilyActivityPicker)
4. 스케줄 (지금 / 평일 9-17 / 커스텀)
5. 권한 요청 (`AuthorizationCenter.shared.requestAuthorization(for: .individual)`)

### 쟁점 14 — 대시보드 MVP 구성 (Architect-Q10)
**결론: 3요소.**
- 집중 점수 (숫자, 0~100)
- 허용 앱 카드 (선택된 앱 수 + "편집" 링크)
- 다음 스케줄 카드 (시작/종료 시각 + "편집" 링크)
- 나무 성장 / 시도 횟수 상세는 Phase 5.

### 쟁점 15 — 엄격 모드 타이머 백그라운드 (UX-Q7)
**결론: Phase 5 이동으로 쟁점 지연.**

### 쟁점 16 — ShieldAction → 메인 앱 직접 오픈 가능성 (UX-Q1 + Architect-Q11)
**결론: 미확정. 안전판 UX + Debugger 실기기 1순위 검증.**
- 안전판(기본): `ShieldAction.defer` 반환. 사용자가 메인 앱을 직접 탭해야 InterceptView로 진입.
- 보조: Extension이 App Group 큐에 이벤트 기록 → 메인 앱 포그라운드 진입 시 큐 읽어 자동 InterceptView 프레젠테이션.
- `NSExtensionContext.open(_:)` 실기기 성공 시에는 자동 오픈으로 업그레이드 (Phase 3 중반 확인).

---

## 2. MVP 구현 범위 (Phase 3 확정)

### In Scope
| # | 기능 | 담당 레이어 |
|---|---|---|
| 1 | 온보딩 5 스텝 | Features/Onboarding |
| 2 | 홈 대시보드 3요소 | Features/Dashboard |
| 3 | 허용 앱 재선택 (`FamilyActivityPicker` 래퍼) | Features/AppSelection |
| 4 | 스케줄 편집 (3 프리셋 + 커스텀) | Features/Schedule |
| 5 | InterceptView (countdown 10초) | Features/Intercept |
| 6 | Shield 카피(따뜻한 톤) | ShieldConfigurationExtension |
| 7 | ShieldAction primary/secondary | **ShieldActionExtension (신규 타깃)** |
| 8 | DeviceActivityMonitor interval 시작/종료 훅 | DeviceActivityMonitorExtension |
| 9 | "그래도 열기" → 5분 해제 → 자동 재차단 | Core/BlockingEngine + MonitoringEngine |
| 10 | 권한 거부 복귀 플로우 | Features/Onboarding + Settings |

### Out of Scope (Phase 5)
- 랜덤 variant (breath / sentence / goalRemind)
- 단계별 차단 Lv.1~4
- 엄격(Nuclear) 모드 / 지연 해제 점증
- 나무 성장 / 게이미피케이션
- 주간 리포트
- 도파민 디톡스 / 카테고리 자동분류
- 친구 경쟁

---

## 3. 스캐폴드 보정

**`ShieldActionExtension` 타깃이 누락되어 있음** → 이 문서 이후 즉시 추가한다.
- `Project.yml` 에 target 추가
- `ShieldActionExtension/ShieldActionExtensionHandler.swift`
- `ShieldActionExtension/Info.plist` (NSExtensionPointIdentifier: `com.apple.ManagedSettingsUI.shield-action-service`)
- `ShieldActionExtension/ShieldActionExtension.entitlements`
- `LockinFocus` target 의존성에 추가
- xcodegen 재생성 + 빌드 검증

---

## 4. Debugger 실기기 1순위 검증 리스트

Architect 부록 B + 팀리더 추가 = 7개:

1. `ShieldSettings.applicationCategories = .all(except: selection.applicationTokens)` 의 실동작 — 시스템 앱(전화·메시지)이 차단되는지 여부.
2. ShieldActionExtension → `NSExtensionContext.open(url)` 으로 메인 앱 포그라운드화 가능 여부.
3. `eventDidReachThreshold` 의 실제 호출 지연 (분 단위?).
4. App Group `UserDefaults` Extension→App 쓰기 가시성 타이밍.
5. `FamilyActivitySelection` Codable round-trip 안정성.
6. "그래도 열기" 5분 일시 해제 + 자동 재차단 정확성.
7. `AuthorizationCenter.requestAuthorization(for: .individual)` 반복 호출·거부 시 상태.

---

## 5. Phase 3 작업 분할 (Coder 병렬)

2개의 Coder 에이전트를 **병렬** 실행한다.

### Coder-A (Core)
- `Core/Persistence/PersistenceStore.swift`
- `Core/BlockingEngine/BlockingEngine.swift` (프로토콜 + 실구현)
- `Core/MonitoringEngine/MonitoringEngine.swift` (프로토콜 + 실구현)
- `Core/Shared/` 모델 확장 (FamilyActivitySelection Codable wrapper, Schedule 모델)
- Extension 코드 보강 (DeviceActivityMonitor, ShieldAction)

### Coder-B (UI)
- `Features/Onboarding/` (5 스텝)
- `Features/Dashboard/`
- `Features/AppSelection/` (FamilyActivityPicker 래퍼)
- `Features/Schedule/`
- `Features/Intercept/` (10초 countdown)
- `Features/Settings/`

두 Coder는 **`AppColors` / `PersistenceStore` 프로토콜 / `BlockingEngine` 프로토콜** 을 공유 인터페이스로 참조. 실구현은 각자 담당.

**교차 레이어 조정**: Coder-A 가 프로토콜 변경 시 즉시 Tasklist.md "토론/이슈 로그"에 기록 → Coder-B 가 반영.

---

## 6. 다음 단계

1. ShieldActionExtension 즉시 추가 (팀리더).
2. 빌드 재검증 → 커밋.
3. Coder-A + Coder-B 병렬 실행.
4. 1차 완료 후 Debugger 점검 → Test → Reviewer 사이클.
