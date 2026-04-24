import WidgetKit
import SwiftUI

@main
struct LockinFocusWidgetsBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        QuoteWidget()
        FocusScoreWidget()
        if #available(iOS 16.2, *) {
            FocusActivityWidget()
        }
    }
}
