# 09 — Release Checklist (실기기 QA + App Store 제출 전 체크리스트)

> 작성: Doc Writer · 2026-04-23
> 대상: 팀리더 (수동 실행), 배포 담당자.
> 기반: `docs/05_Debugger_Report.md §실기기 추가 검증` 7 항목 + `docs/07_Review_Report.md §3` 개선 항목 + 일반적 iOS 배포 관행.

---

## 0. 사용 방법

본 체크리스트는 TestFlight 업로드 직전까지의 최소 요구사항이다.
각 항목은 담당자/일자와 함께 체크하여 `docs/` 내부 별도 기록으로 남겨두면 감사 시 편하다.

---

## 1. 코드 서명 / Entitlement

- [ ] `Project.yml` 의 `DEVELOPMENT_TEAM` 를 본인 팀 ID 로 설정 (또는 Xcode 에서 Signing & Capabilities 자동 관리 체크)
- [ ] Apple Developer Portal 에서 App Group `group.com.imurmkj.LockinFocus` 등록 확인 (4 타깃 모두)
- [ ] Apple Developer 에서 **Family Controls distribution entitlement** 승인 받음
      → [신청 링크](https://developer.apple.com/contact/request/family-controls-distribution)
      → 앱 목적, 스크린샷, 허위 사용 방지 정책 첨부 필요
- [ ] 메인 앱 + 3 Extension 모두 Family Controls capability 활성
- [ ] Provisioning profile 이 4 타깃 모두 올바른 bundle id 와 매칭:
      - `com.imurmkj.LockinFocus`
      - `com.imurmkj.LockinFocus.DeviceActivityMonitorExtension`
      - `com.imurmkj.LockinFocus.ShieldConfigurationExtension`
      - `com.imurmkj.LockinFocus.ShieldActionExtension`

---

## 2. 빌드 검증

- [ ] `xcodegen generate` 이후 `LockinFocus.xcodeproj` 재생성 (Swift 파일 추가/삭제 반영)
- [ ] 시뮬레이터 빌드 성공 (서명 없이)
      ```bash
      xcodebuild -project LockinFocus.xcodeproj -scheme LockinFocus \
                 -sdk iphonesimulator \
                 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
                 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
      ```
- [ ] 실기기 빌드 성공 (서명 포함)
- [ ] Archive 성공 (Release 구성)
- [ ] 단위 테스트 전체 통과 (23 케이스 / 5 파일)
      ```bash
      xcodebuild test -project LockinFocus.xcodeproj -scheme LockinFocus \
                 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
                 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
      ```

---

## 3. 실기기 기능 QA (3 – 5 대 디바이스)

본 항목은 `docs/05_Debugger_Report.md §실기기 추가 검증 필요 항목` 을 그대로 승격한 것이다.
시뮬레이터에서 자동화 불가능하므로 수동 검증이 유일한 검증 수단이다.

- [ ] **(Debugger DEFER #1)** 주 스케줄 activity 이름 `block_main` 경로
      — 평일 17:00 종료 시 Shield 가 자동 해제되는가
- [ ] **(DEFER #2)** `ShieldActionExtension` 의 `completionHandler(.defer)` 이후 메인 앱 자동 포그라운드화
      — `NSExtensionContext.open(_:)` 호출 추가 가능 여부 평가
      — 현재는 사용자가 메인 앱을 수동 탭해야 InterceptView 가 뜨므로 안전판으로 동작
- [ ] **(DEFER #3)** `FamilyActivitySelection` 토큰의 Extension ↔ 메인 앱 크로스 비교
      — App Group 직렬화된 토큰이 `.all(except:)` 인자로 동일 인식되는지
- [ ] **(DEFER #4)** `ManagedSettingsStore(named: .lockinPrimary)` 를 메인 앱과 Extension 이 공유하는지
      — shield 적용/해제가 양쪽에서 반영되는지
- [ ] **(DEFER #5)** 온보딩 완료 후 RootView 전환
      — `requestAuthorization` 이 시스템 UI 없이 즉시 성공 반환하는 iOS 18+ 경로에서도
      `deps.objectWillChange.send()` fix 가 RootView 재렌더를 보장하는지
- [ ] **(DEFER #6)** InterceptView Timer 백그라운드 복귀 품질
      — 홈으로 내린 후 5 초 후 복귀 시 카운트가 어디부터 재개되는지
      — 팀 결정(리셋) 과 괴리 시 Phase 5 `Date` 기반 리팩터
- [ ] **(DEFER #7)** `.all(except:)` 정책의 시스템 앱 영향
      — 전화·메시지·설정·시계 등이 실수로 차단되지 않는지
      — 차단된다면 온보딩 Step 2 "기본 프리셋" 에 추가

---

## 4. UX 최종 점검

- [ ] 느낌표(!) 카피 0 건 유지 (Grep: `grep -rn "!" LockinFocus/Features | grep -v "//" | grep "Text("`)
- [ ] 명령형 "하세요/해주세요" 0 건 (Review §1.E 의 "켜주세요" 는 Phase 5 폴리싱 가능)
- [ ] 앱 이름 노출 금지 (쟁점 2) — InterceptView 카피 일반화 확인
- [ ] "돌아가기" = `PrimaryButton` (52pt 높이, 검은 배경) / "그래도 열기" = `SecondaryLinkButton` (연회색) 대비 유지
- [ ] 다크 모드 — v1 흰색 배경 전용. 다크 모드 사용자 방문 시 자동 흰색 유지 확인 (v1.1 정식 지원)

---

## 5. 에셋 / 메타데이터

- [ ] `AppIcon.appiconset` 실제 아이콘으로 교체 (현재 placeholder)
- [ ] `AccentColor.colorset` 최종 색상 확정 (`AppColors` 토큰과 일관)
- [ ] LaunchScreen — SwiftUI 앱은 별도 LaunchScreen.storyboard 불필요하나
      `Info.plist` 의 `UILaunchScreen` 섹션 확인
- [ ] App Store Connect 메타데이터
      - 앱 이름 / 부제 / 키워드
      - 프로모션 텍스트 (170 자)
      - 설명 (4000 자) — 허위 사용 방지 정책 포함
      - 스크린샷 (6.7", 6.5", 5.5" / iPad 12.9", 11")
      - 카테고리: Productivity 또는 Health & Fitness
      - 연령 등급
      - 저작권 표시
- [ ] 개인정보 처리방침 URL (iOS 앱 필수)
- [ ] 마케팅 URL (선택)
- [ ] 지원 URL (필수)

---

## 6. Privacy / 규제

- [ ] **Privacy Manifest 추가** (`PrivacyInfo.xcprivacy`)
      — iOS 17+ 배포 및 2024년 5월부터 필수. UserDefaults API 사용 사유 기재 필요
- [ ] App Tracking Transparency 불필요 확인 (본 앱은 추적 없음)
- [ ] Screen Time 데이터 처리 고지 — 앱 내 설명 카드 + 개인정보 처리방침 링크
- [ ] 모든 데이터가 로컬에 머문다는 사실을 App Store 설명과 프라이버시 라벨에 명시

---

## 7. TestFlight 베타

- [ ] 내부 테스터 등록 (팀 계정)
- [ ] 외부 테스터 5 – 10 인 초대
- [ ] 최소 1 주간 피드백 수집
      - Shield 가 실제로 뜨는지
      - "그래도 열기" 5분 해제가 정확히 재차단되는지
      - 온보딩 완료율
      - Crash-free 비율 99%+
- [ ] TestFlight 에서 발견된 Critical/High 수정 후 재업로드

---

## 8. App Store 심사

- [ ] Apple Review 예상 거절 사유 사전 대비:
      - "다른 앱 차단" 기능의 구체적 사용 목적 증명 (self-management 강조)
      - Family Controls entitlement 승인 증명
      - Screen Time 데이터 오용 방지 정책
- [ ] 심사 노트에 FamilyControls `.individual` 모드 사용 명시
- [ ] 데모 계정 불필요 (로그인 없음)

---

## 9. Phase 5 이월 개선 (배포 차단 아님)

아래 항목은 `docs/07_Review_Report.md §3` 에서 제기된 개선이지만
MVP 배포를 막지 않는다. Phase 5 착수 시 우선 처리 권고.

- [ ] App Group 상수·키·activity 이름의 소스 단일화
      (`Project.yml` 의 Extension `sources` 에 `Core/Shared/AppGroup.swift` 개별 추가)
- [ ] AuthorizationStepView denied 카피 "켜주세요" → 선언형으로 폴리싱
- [ ] InterceptView Timer 를 `Date` 기반 targetDate 모델로 전환
- [ ] `UserDefaultsPersistenceStore` 의 인/디코딩 실패에 `os_log` 관측성 추가
- [ ] `AppGroup.sharedDefaults` 의 `fatalError` → `os_log(.fault)` + 빈 UserDefaults 폴백
- [ ] `PersistenceStore` 프로토콜 확장 준비 (FocusDay, WeeklyReport — SwiftData 도입)

---

## 10. 배포 후 모니터링

- [ ] Xcode Organizer 의 Crashes 모니터링 (첫 7 일 매일)
- [ ] App Store 리뷰 대응 (특히 권한 관련 불만)
- [ ] TestFlight 피드백 채널 유지 (v1.1 계획용)

---

## 참고

- `docs/05_Debugger_Report.md` — 실기기 QA 원문 근거
- `docs/07_Review_Report.md §3` — Phase 5 이월 상세
- `README.md` — 한 화면 요약
- `docs/08_Architecture_Map.md` — 코드 수준 지도
