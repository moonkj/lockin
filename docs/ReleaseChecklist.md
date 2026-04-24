# 락인 포커스 — 릴리스 체크리스트

마지막 업데이트: 2026-04-24

**팀리더 결정**: A(출시 준비) → B(커버리지) → C(기능) → D(국제화) 순으로 진행.

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
- **호스팅 옵션**:
  1. GitHub Pages: `https://moonkj.github.io/lockin/privacy` 로 노출
  2. 개인 블로그 / Notion public page
  3. GitHub raw 링크: `https://raw.githubusercontent.com/moonkj/lockin/main/docs/PrivacyPolicy.md`
- **추천**: GitHub Pages (무료, 변경 이력 자동, 공식 URL 형태)
- **상태**: ⬜ 호스팅 전

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

현재 416 tests / 87.94% 메인 앱 커버리지.

- ⬜ Widget 타깃 커버리지 (현재 ~11% → 60%+ 목표)
- ⬜ Extension 타깃 커버리지 (ShieldAction / DeviceActivityMonitor 지표, 계약 회귀 방지)

---

## C. 기능 추가

- ⬜ Haptic 피드백 (뱃지 해제, Intercept 돌아가기, 엄격 모드 만료)
- ⬜ 대시보드 7일 스트릭 점 시각화

---

## D. 국제화 (6개 언어)

한국어 / 영어 / 일본어 / 중국어 간체 / 프랑스어 / 힌디어

- ⬜ Localizable.strings 파일 + 각 언어 .lproj 디렉터리
- ⬜ 모든 하드코딩된 한국어 문자열을 LocalizedStringKey 로 전환
- ⬜ Info.plist `CFBundleLocalizations` 배열 추가
- ⬜ 날짜/숫자 포맷 로케일 대응

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
