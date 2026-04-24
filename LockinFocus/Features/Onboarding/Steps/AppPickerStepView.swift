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
        selection.totalItemCount
    }

    private var selectedSummary: String {
        selection.displayBreakdown ?? "0개"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("허용할 앱을 골라주세요")
                    .scaledFont(28, weight: .semibold)
                    .foregroundStyle(AppColors.primaryText)

                Text("여기서 고른 앱만 집중 시간에 열 수 있어요.\n카메라·지도·시계도 필요하면 체크하세요.")
                    .scaledFont(15)
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
                            .scaledFont(16, weight: .medium)
                            .foregroundStyle(AppColors.primaryText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .scaledFont(13, weight: .semibold)
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
                     ? "아무것도 안 고르면 시스템 자동 보호 앱 외 모두 잠겨요. 건너뛰어도 돼요."
                     : "현재 선택: \(selectedSummary)")
                    .scaledFont(14)
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
