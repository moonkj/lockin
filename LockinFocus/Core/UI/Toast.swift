import SwiftUI

/// 하단 슬라이드업 토스트. 바인딩된 메시지가 nil 이 아니면 표시하고 2.5초 뒤 자동 해제.
/// 별도 네비게이션 없이 짧은 안내가 필요한 곳에만 쓴다.
struct ToastModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    ToastBanner(text: message)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            // 지금 표시 중인 메시지를 캡처. 2.5초 안에 새 메시지로 바뀌면
                            // 캡처값과 달라지므로 옛 타이머는 아무것도 건드리지 않는다.
                            let captured = message
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                guard self.message == captured else { return }
                                withAnimation(.easeOut(duration: 0.25)) {
                                    self.message = nil
                                }
                            }
                        }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: message)
    }
}

private struct ToastBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColors.primaryText)
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
            )
    }
}

extension View {
    /// `message` 가 nil 이 아니면 하단에 토스트를 띄우고 2.5초 뒤 자동으로 nil 로 되돌린다.
    func toast(message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}
