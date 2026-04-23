# CLAUDE.md — Lockin Focus 프로젝트 컨텍스트

> Claude Code 가 본 프로젝트에서 작업할 때 참조할 짧은 컨텍스트. 상세 설계는 `docs/` 참조.

## 프로젝트 한 줄
손이 움직이기 전에 생각하게 만드는 iOS 집중 강화 앱. iOS 16+ / SwiftUI / FamilyControls.

## 팀 역할 (에이전트)
UX Designer → Architect → Coder-A(Core) + Coder-B(UI) → Debugger → Test Engineer → Reviewer → Doc Writer. 팀리더가 통합·최종 판단.

## 필수 규약
1. **activity 이름**: 주 스케줄 `block_main`, 일시 해제 `temp_allow_*` prefix. 메인 앱 호출부 3 곳 + Extension 1 곳 동시 수정해야 함.
2. **App Group**: `group.com.imurmkj.LockinFocus`. 4 타깃 공유.
3. **InterceptEvent rawValue 고정**: `returned` / `interceptRequested` / `application` / `category` / `webDomain`. Extension 큐 스키마와 계약. 테스트 `InterceptEventTests.testRawValueStability_*` 가 회귀 방어.
4. **Shield 정책**: `shield.applicationCategories = .all(except: selection.applicationTokens)` 역-화이트리스트.
5. **3 Extension 타깃**: DeviceActivityMonitor / ShieldConfiguration / ShieldAction. 독립 entitlement.
6. **시뮬레이터**: Shield/DeviceActivity 미동작. `AppDependencies.live()` 가 Noop 주입. 검증은 실기기 전용.
7. **UX 카피 규칙**: 흰색 배경 · 느낌표(!) 금지 · 명령형 금지 · 앱 이름 노출 금지.
8. **문서 위치**: 설계·리뷰는 `docs/`, 진행/토론은 `Tasklist.md`. 새 결정은 즉시 기록.
9. **테스트**: XcodeGen 기반. `xcodegen generate` 이후 빌드. 23 케이스 유지.

## 주요 진입점
- `LockinFocus/App/LockinFocusApp.swift` — `@main`
- `LockinFocus/App/RootView.swift` — 온보딩/대시보드 분기 + InterceptView sheet
- `LockinFocus/Core/DI/AppDependencies+Live.swift` — 시뮬/실기기 분기
- `DeviceActivityMonitorExtension/DeviceActivityMonitorExtension.swift` — 스케줄 훅
- `ShieldActionExtension/ShieldActionExtensionHandler.swift` — 큐 적재
