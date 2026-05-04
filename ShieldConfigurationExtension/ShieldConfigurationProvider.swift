import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Shield 기본 UI 커스터마이징. 완전 커스텀 뷰는 불가능하며,
/// title/subtitle/primaryButton/secondaryButton/icon/backgroundColor 수준의 수정만 허용된다.
/// 본격 심리 개입 UI는 Shield 전에 메인 앱이 띄우는 "중간 인터셉트 화면"에서 담당한다.
class ShieldConfigurationProvider: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return lockinShield(
            title: "잠시 멈춰요",
            subtitle: "왜 이 앱을 열려고 했나요?"
        )
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        return lockinShield(
            title: "잠시 멈춰요",
            subtitle: "지금 이 카테고리의 앱들은 제한 중이에요."
        )
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return lockinShield(
            title: "잠시 멈춰요",
            subtitle: "이 사이트는 지금 제한 중이에요."
        )
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        return lockinShield(
            title: "잠시 멈춰요",
            subtitle: "지금 이 카테고리는 제한 중이에요."
        )
    }

    private func lockinShield(title: String, subtitle: String) -> ShieldConfiguration {
        // secondary 버튼은 의도적으로 미설정. ShieldActionExtension 에서 메인 앱을
        // 자동 포그라운드화할 수 없는 Apple API 제약 때문에, 누름 후 "아무것도 동작
        // 안 함" 으로 보이는 사용자 혼동이 컸음. 메인 앱에서 별도 진입점으로 임시
        // 해제 흐름을 제공할 예정.
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: .white,
            title: ShieldConfiguration.Label(text: title, color: .black),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: .darkGray),
            primaryButtonLabel: ShieldConfiguration.Label(text: "돌아가기", color: .white),
            primaryButtonBackgroundColor: .black
        )
    }
}
