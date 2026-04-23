import SwiftUI
import FamilyControls

/// 온보딩 Step 3 — 허용 앱 선택.
/// `FamilyActivityPicker` 는 실기기 + 권한 부여 이후 실제 카탈로그가 뜬다.
/// 시뮬레이터/권한 없음 상태에서는 빈 리스트로 보이지만 UI 동작은 정상.
struct AppPickerStepView: View {
    @Binding var selection: FamilyActivitySelection
    let onNext: () -> Void

    @State private var showPicker: Bool = false

    private var selectedCount: Int {
        selection.applicationTokens.count + selection.categoryTokens.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("쉬게 할 앱을 골라주세요")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                Text("여기서 고른 앱·카테고리만 집중 시간에 쉬어요.\n고르지 않은 앱은 그대로 열립니다.")
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.secondaryText)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 12) {
                Button {
                    showPicker = true
                } label: {
                    HStack {
                        Text("허용 앱 고르기")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(AppColors.primaryText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppColors.surface)
                    )
                }
                .buttonStyle(.plain)

                Text(selectedCount == 0
                     ? "지금 건너뛰어도 돼요. 나중에 설정에서 추가할 수 있어요."
                     : "현재 선택: \(selectedCount)개")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.secondaryText)
            }
            .padding(.horizontal, 24)

            Spacer()

            PrimaryButton("다음", action: onNext)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .familyActivityPicker(isPresented: $showPicker, selection: $selection)
    }
}

#Preview {
    AppPickerStepView(selection: .constant(FamilyActivitySelection()), onNext: {})
        .background(AppColors.background)
}
