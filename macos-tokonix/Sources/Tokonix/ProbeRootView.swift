import SwiftUI

struct ProbeRootView: View {
    @StateObject private var model = OverlayViewModel()

    var body: some View {
        Color.clear
            .frame(width: OverlayLayout.windowWidth, height: OverlayLayout.windowHeight)
            .onAppear {
                model.start()
            }
    }
}
