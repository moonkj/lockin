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
- [ ] GitHub 원격 연결 (보류)

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
- [ ] `Core/Persistence/UserDefaultsPersistenceStore.swift` — App Group + Codable
- [ ] `Core/Persistence/InMemoryPersistenceStore.swift` — 시뮬레이터/테스트용 Fake
- [ ] `Core/BlockingEngine/ManagedSettingsBlockingEngine.swift` — 역-화이트리스트 `.all(except:)`
- [ ] `Core/BlockingEngine/NoopBlockingEngine.swift` — 시뮬레이터용
- [ ] `Core/MonitoringEngine/DeviceActivityMonitoringEngine.swift`
- [ ] `Core/MonitoringEngine/NoopMonitoringEngine.swift`
- [ ] DeviceActivityMonitorExtension 보강: `intervalDidStart` 에서 shield 적용
- [ ] "그래도 열기" 5분 재차단 플로우 (임시 `temp_allow_<token>` interval 종료 시 재추가)

#### Coder-B (UI)
- [ ] `Features/Onboarding/` 5 스텝 (Value / SystemPreset / Picker / Schedule / Authorization)
- [ ] `Features/Dashboard/` 3요소 (집중 점수 / 허용 앱 / 다음 스케줄)
- [ ] `Features/AppSelection/` FamilyActivityPicker 래퍼
- [ ] `Features/Schedule/` 3 프리셋 + 커스텀
- [ ] `Features/Intercept/` countdown 10초
- [ ] `Features/Settings/` 기본 (재선택/스케줄 편집/정보)
- [ ] `App/RootView` 수정: 온보딩 여부 분기 + interceptQueue 자동 프레젠테이션

#### 교차 레이어 조정 규약
- 프로토콜 변경은 "토론/이슈 로그"에 즉시 기록.
- 공유 타입은 `Core/Models/`, `Core/Protocols/` 에만 추가.

### Phase 4 — Debugger → Test → Reviewer 사이클
- [ ] Debugger 1차 점검 (MVP 구현 이후)
- [ ] Test Engineer 단위/통합 테스트 작성
- [ ] Reviewer 최종 리뷰 — 개선 필요 시 R2로 Architect 복귀

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

(비어 있음)
