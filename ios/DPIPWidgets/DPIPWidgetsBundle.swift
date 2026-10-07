import WidgetKit
import SwiftUI

@main
struct DPIPWidgetsBundle: WidgetBundle {
    var body: some Widget {
        DPIPWidgets()
        if #available(iOS 16.1, *) {
            EEWLiveActivity()
        }
    }
}
