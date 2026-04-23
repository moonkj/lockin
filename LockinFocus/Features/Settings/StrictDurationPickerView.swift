import SwiftUI

/// 엄격 모드 시작 전 지속 시간 선택.
/// 고른 시간이 지나기 전까지는 어떤 방법으로도 해제할 수 없음을 강조.
struct StrictDurationPickerView: View {
    let presets: [(label: String, seconds: TimeInterval)]
    let onStart: (TimeInterval) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedIndex: Int = 1

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    Text("얼마나 집중할까요?")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)

                    Text("고른 시간이 지나기 전까지는 비밀번호를 알아도 풀 수 없어요.")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.secondaryText)

                    VStack(spacing: 10) {
                        ForEach(Array(presets.enumerated()), id: \.offset) { index, preset in
                            let isSelected = selectedIndex == index
                            Button {
                                selectedIndex = index
                            } label: {
                                HStack {
                                    Text(preset.label)
                                        .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                                        .foregroundStyle(isSelected ? Color.white : AppColors.primaryText)
                                    Spacer()
                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .accessibilityHidden(true)
                                    }
                                }
                                .padding(.horizontal, 18)
                                .frame(height: 54)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(isSelected ? AppColors.primaryText : AppColors.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(isSelected ? Color.clear : AppColors.divider, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 4)

                    Spacer()

                    PrimaryButton("시작하기") {
                        let seconds = presets[selectedIndex].seconds
                        onStart(seconds)
                        dismiss()
                    }
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
    }
}

#Preview {
    StrictDurationPickerView(
        presets: [
            ("30분", 1800),
            ("1시간", 3600),
            ("2시간", 7200),
            ("4시간", 14400),
            ("8시간", 28800)
        ],
        onStart: { _ in }
    )
}
