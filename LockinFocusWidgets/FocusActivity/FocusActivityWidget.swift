import WidgetKit
import SwiftUI
import ActivityKit

/// Live Activity — Lock Screen + Dynamic Island 양쪽에서 집중 세션 상태를 보여준다.
@available(iOS 16.2, *)
struct FocusActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            // Lock Screen / StandBy
            lockScreenView(state: context.state)
                .activityBackgroundTint(Color(uiColor: .systemBackground))
                .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: context.state.isStrict ? "lock.fill" : "leaf.fill")
                            .foregroundStyle(context.state.isStrict ? .red : .green)
                        Text(context.state.isStrict ? "엄격" : "집중")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let end = context.state.strictEndDate {
                        Text(end, style: .timer)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                            .frame(minWidth: 70, alignment: .trailing)
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 1) {
                            Text("\(context.state.focusScore)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text("/ 100")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("허용 앱 \(context.state.allowedCount)개")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isStrict {
                        Text("엄격 모드 — 시간이 끝나기 전엔 풀 수 없어요.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("집중 중 — 허용한 앱 외엔 열리지 않아요.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.isStrict ? "lock.fill" : "leaf.fill")
                    .foregroundStyle(context.state.isStrict ? .red : .green)
            } compactTrailing: {
                if let end = context.state.strictEndDate {
                    Text(end, style: .timer)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .frame(minWidth: 44, alignment: .trailing)
                } else {
                    Text("\(context.state.focusScore)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
            } minimal: {
                Image(systemName: context.state.isStrict ? "lock.fill" : "leaf.fill")
                    .foregroundStyle(context.state.isStrict ? .red : .green)
            }
            .keylineTint(context.state.isStrict ? .red : .green)
        }
    }

    @ViewBuilder
    private func lockScreenView(state: FocusActivityAttributes.State) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: state.isStrict ? "lock.fill" : "leaf.fill")
                        .foregroundStyle(state.isStrict ? .red : .green)
                    Text(state.isStrict ? "엄격 모드" : "집중 중")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                }

                Text("허용 앱 \(state.allowedCount)개 · 오늘 \(state.focusScore)점")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let end = state.strictEndDate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(end, style: .timer)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                    Text("남음")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("\(state.focusScore)")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("/ 100")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Text("집중 점수")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
