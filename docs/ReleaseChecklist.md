# 락인 포커스 — 릴리스 체크리스트

마지막 업데이트: 2026-04-24 (저녁)

**팀리더 결정**: A(출시 준비) → B(커버리지) → C(기능) → D(국제화) 순으로 진행.
**추가 Phase**: iPad 레이아웃, Live Activity, 친구/그룹 랭킹 완료 (2번 Pomodoro 는 건너뜀).

---

## A. 출시 전 외부 작업 (코드 작업으로 못 함)

### A-1. Family Controls 배포 승인 [필수 · 차단 항목]

- **무엇**: iOS Screen Time API 를 쓰는 앱은 App Store 출시 전에 Apple 승인 필요.
- **어디**: https://developer.apple.com/contact/request/family-controls-distribution
- **누가**: 앱 개발자 (imurmkj@naver.com)
- **소요**: 5–14 영업일
- **준비물**:
  - 앱 스크린샷 몇 장
  - 자기관리용 앱이라는 설명 (부모 통제가 아님)
  - 오용 방지 정책 설명
  - 사용자에게 어떤 가치를 주는지 요약
- **상태**: ⬜ 신청 전

### A-2. CloudKit Production 스키마 배포 [필수 · 차단 항목]

- **무엇**: 개발 환경에 있는 `LeaderboardEntry` 레코드 타입과 `recordName` Queryable 인덱스를 Production 으로 복사.
- **어디**: CloudKit Console → iCloud.com.moonkj.LockinFocus → Schema → Deploy Schema Changes
- **누가**: 앱 개발자
- **소요**: 5분
- **단계**:
  1. https://icloud.developer.apple.com/dashboard/
  2. Container: `iCloud.com.moonkj.LockinFocus` 선택
  3. Schema → **Deploy Schema Changes to Production** 버튼 클릭
  4. LeaderboardEntry 레코드 타입과 인덱스 변경사항 확인
  5. 배포 실행
- **검증**: TestFlight 빌드에서 랭킹 조회 성공 여부로 확인
- **상태**: ⬜ 배포 전

### A-3. 개인정보 처리방침 호스팅 [필수 · 차단 항목]

- **무엇**: App Store Connect 제출 폼에서 Privacy Policy URL 필수 입력.
- **이미 작성됨**: `docs/PrivacyPolicy.md` (한국어+영어+일본어+중국어간체+프랑스어+힌디어)
- **배포 인프라 준비 완료**:
  - `docs/_config.yml` — Jekyll 빌드 설정 (내부 설계 문서는 제외)
  - `docs/index.md` — 랜딩 페이지
  - `docs/PrivacyPolicy.md` — front matter `permalink: /PrivacyPolicy/` 지정
  - `.github/workflows/pages.yml` — main 브랜치 push 시 자동 배포
- **GitHub 저장소 설정 (1회성, 사용자 작업)**:
  1. https://github.com/moonkj/lockin/settings/pages
  2. **Source**: "GitHub Actions" 선택 (Deploy from a branch 아님)
  3. 저장 → 첫 배포가 `.github/workflows/pages.yml` 로 자동 트리거
- **최종 URL**:
  - 랜딩: `https://moonkj.github.io/lockin/`
  - Privacy Policy: `https://moonkj.github.io/lockin/PrivacyPolicy/`
- **App Store Connect 에 입력할 값**: `https://moonkj.github.io/lockin/PrivacyPolicy/`
- **상태**: ⬜ 저장소 Pages 활성화 전

### A-4. App Store Connect 메타데이터 [사용자가 직접]

사용자가 나중에 등록할 항목들:
- 앱 이름: **락인 포커스**
- 부제 / Subtitle: 미정
- 카테고리: Productivity 또는 Health & Fitness
- 나이 등급: 4+
- 스크린샷 (6.7" / 6.1" / iPad 13")
- 앱 설명 (한국어 + 선택 로케일)
- 키워드
- 저작권 표시
- 지원 URL
- 개인정보 처리방침 URL (A-3 에서 준비)

### A-5. 앱 내 준비 상태 (코드 작업 완료)

- ✅ `LockinFocus/PrivacyInfo.xcprivacy`: UserDefaults + CloudKit 데이터 수집 선언
- ✅ `LockinFocus/LockinFocus.entitlements`: family-controls, app-groups, CloudKit, ubiquity-kvstore 모두 설정
- ✅ `Info.plist`: `lockinfocus://` 딥링크 스킴 등록, 디스플레이 이름 설정
- ✅ AppIcon 1024×1024 설정 완료 (알파 없는 PNG)
- ✅ Build.xcconfig 로 관리자 도구 flag 격리 (gitignored, Production 빌드에서 elided)
- ✅ iOS 16.0 최소 배포 타깃 준수
- ✅ 실기기 전용 코드 경로 Noop 처리 (시뮬레이터 호환)

---

## B. 테스트 커버리지 확장

현재 469 tests (= 430 + 39 new feature tests) / 메인 앱 ~88% 커버리지.

- ✅ Widget/AppGroup 계약 테스트 (WidgetProviderTests — 7건, UserDefaults 키 고정)
- ✅ Extension 계약 테스트 (ExtensionContractTests — InterceptEvent rawValue 스키마 고정)
- ✅ 신규 기능 단위 테스트 (39건 추가)
  - FriendInviteLink URL 파싱/빌드 왕복 (12건)
  - FocusActivityAttributes Codable/Hashable + Service no-op 안전성 (10건)
  - ReadingWidthModifier inspect 안정성 (6건)
  - AppDependencies 친구 초대 생명주기 (10건)
- ⚠️ 기존 81 건 뷰 테스트 실패는 iOS 26 + ViewInspector `AccessibilityImageLabel` 블로커 (인프라 이슈, 프로덕션 영향 없음). ViewInspector 0.10.x + main branch 둘 다 미해결.

---

## C. 기능 추가

- ✅ Haptic 피드백 (뱃지 해제 success + 뱃지 탭 selection, Intercept 돌아가기, 엄격 모드 자동 만료)
- ✅ 대시보드 7일 스트릭 점 시각화 (StreakDotsCard)

---

## D. 국제화 (6개 언어)

한국어 / 영어 / 일본어 / 중국어 간체 / 프랑스어 / 힌디어

- ✅ Localizable.strings 파일 + 6 개 .lproj 디렉터리 (docs/gen_strings.py 로 자동 생성 — 각 언어 134 개 키)
- ✅ 앱 내 하드코딩 문자열이 LocalizedStringKey 해석됨 (SwiftUI `Text("…")` 은 기본 LocalizedStringKey)
- ✅ Info.plist `CFBundleLocalizations` = [ko, en, ja, zh-Hans, fr, hi], `CFBundleDevelopmentRegion` = ko
- ✅ 테스트용 `L()` 헬퍼 (Bundle.main.localizedString) 로 시뮬레이터 locale 독립 매칭

---

## E. 추가 Phase (세션 중 완료)

- ✅ **iPad 레이아웃 최적화**: `readingWidth(520–720)` 모디파이어로 13개 상위 뷰가 iPad 에서 가독 폭 중앙 정렬. iPhone 에선 no-op.
- ✅ **Live Activity + Dynamic Island** (iOS 16.2+): 집중 세션 활성 시 Lock Screen 카드 + Dynamic Island (compact/minimal/expanded). `FocusActivityService` 가 manual focus 토글 + strict 시작/자동만료에 훅.
- ✅ **친구 + 그룹 랭킹**: `lockinfocus://friend?uid=X&nick=Y` 초대 링크 → RootView alert 확인 → 친구 목록 저장. LeaderboardView 의 전체/친구 scope picker 로 그룹 비교. FriendsManagementView 에서 초대/삭제.

---

## 제출 직전 최종 체크

- ⬜ CloudKit Production 스키마 배포 완료
- ⬜ Family Controls 승인 수신
- ⬜ Privacy Policy URL 공개 접근 가능
- ⬜ TestFlight 내부 테스트 1주일 이상
- ⬜ 크래시 모니터링 리포트 0건
- ⬜ 스크린샷/설명/키워드 등록
- ⬜ `DEVELOPMENT_TEAM` 변경 후 Archive
- ⬜ `Build.xcconfig` 없는 상태로 빌드 확인 (관리자 코드 제거 확인)
