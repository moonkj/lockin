# 01 — Xcode 프로젝트 생성 가이드

## 왜 GUI인가
FamilyControls, DeviceActivity, ManagedSettings는 **Capabilities**와 **App Extension 타깃**을 함께 설정해야 합니다. Xcode GUI가 가장 안전합니다.

---

## 1. 프로젝트 생성

1. Xcode 실행 → `File ▸ New ▸ Project...`
2. **iOS ▸ App** 선택 → Next
3. 입력값
   - **Product Name**: `LockinFocus`
   - **Team**: (유료 Developer 계정 선택)
   - **Organization Identifier**: `com.imurmkj` (본인 역도메인 권장)
   - **Bundle Identifier**: 자동 → `com.imurmkj.LockinFocus`
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Storage**: `None` (나중에 SwiftData/CoreData 필요 시 추가)
   - **Include Tests**: ✅ 체크 (Test Engineer가 사용)
4. 저장 위치: `/Users/kjmoon/Lockin Focus`
5. **Create Git repository on my Mac**: ✅ 체크

## 2. Deployment Target

- `LockinFocus` 타깃 → **General** 탭
- **Minimum Deployments**: **iOS 16.0** 이상 (FamilyControls는 iOS 15+이지만 DeviceActivity가 안정화된 16 기준 권장)

## 3. Capabilities 추가

`Signing & Capabilities` 탭 → `+ Capability`:
1. **Family Controls** ← 반드시 추가. 이걸 추가하면 entitlement가 생성됩니다.
2. **Background Modes**
   - ✅ Background fetch
   - ✅ Background processing
3. **App Groups** ← 확장과 데이터 공유용
   - `+` → `group.com.imurmkj.LockinFocus` 생성·체크

## 4. Family Controls Entitlement 신청

개발/시뮬레이터에서 사용하려면 Apple에 **배포용** 권한 신청이 추가로 필요합니다 (App Store 출시 시 필수):
- 신청 페이지: `https://developer.apple.com/contact/request/family-controls-distribution`
- 승인 보통 수 일~수 주 소요. **설계/UI 구현을 먼저 진행**하고 병행 신청하는 것을 권장.

개발 기기 테스트용 entitlement는 Xcode Capabilities 추가만으로 자동 발급됩니다 (`com.apple.developer.family-controls`).

## 5. App Extension 타깃 추가

### 5-1. DeviceActivityMonitor Extension
- `File ▸ New ▸ Target...`
- **Device Activity Monitor Extension** 검색 → 선택
- Product Name: `DeviceActivityMonitorExtension`
- Bundle ID: 자동으로 `com.imurmkj.LockinFocus.DeviceActivityMonitorExtension`
- **Embed in Application**: `LockinFocus`
- 생성 후 해당 타깃도 Capabilities에:
  - ✅ **Family Controls**
  - ✅ **App Groups** (같은 `group.com.imurmkj.LockinFocus` 선택)

### 5-2. ShieldConfiguration Extension
- `File ▸ New ▸ Target...`
- **Shield Configuration Extension** → 생성
- Product Name: `ShieldConfigurationExtension`
- 같은 방식으로 Capabilities의 Family Controls + App Groups 추가.

### 5-3. (선택) ShieldAction Extension
- 사용자가 Shield 화면에서 버튼을 눌렀을 때 앱을 깨워 "중간 인터셉트 UI"로 유도하는 데 사용.
- **Shield Action Extension** 타깃 생성, 같은 Capabilities.

## 6. 폴더 구조 제안

프로젝트 생성 후 Xcode에서 그룹 만들기:
```
LockinFocus/
├── App/                 # @main, 진입점
├── Features/
│   ├── Onboarding/
│   ├── AppSelection/    # FamilyActivityPicker
│   ├── Schedule/
│   ├── Intercept/       # 10초 지연 화면
│   ├── Dashboard/
│   └── Settings/
├── Core/
│   ├── BlockingEngine/  # ManagedSettings 래퍼
│   ├── MonitoringEngine/ # DeviceActivityCenter 래퍼
│   ├── Persistence/     # AppStorage/UserDefaults 또는 SwiftData
│   └── Theme/           # AppColors (흰색 기반)
└── Shared/              # 확장과 공유할 모델·키
```

## 7. 완료 신호

Xcode에서 `⌘+B` 로 빌드가 성공하면 다음을 터미널에서 확인:

```sh
cd "/Users/kjmoon/Lockin Focus"
ls LockinFocus LockinFocus.xcodeproj
```

두 항목이 보이면 완료입니다. **완료되면 "Xcode 세팅 완료"라고 알려주세요** — 팀이 Phase 3 코드 작성으로 진입합니다.

---

## 트러블슈팅

- **`Family Controls` capability가 목록에 없음**: Team이 무료 계정이거나 로그인 누락. `Xcode ▸ Settings ▸ Accounts`에서 유료 Team 확인.
- **Build 실패 `Provisioning profile doesn't support com.apple.developer.family-controls`**: Xcode가 자동으로 provisioning을 갱신할 때까지 1–2분 대기하거나, Signing의 `Automatically manage signing` 끄고 다시 켜기.
- **시뮬레이터에서 Shield가 안 뜸**: Screen Time API 상당수는 실기기에서만 동작합니다. 실제 동작 테스트는 실기기로.
