import SwiftUI

/// Demo app entry. Copy this file into an Xcode App target (or use as SPM example).
@main
struct IridescentBlobApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 360, minHeight: 360)
        }
        #if os(macOS)
        .windowResizability(.contentMinSize)
        #endif
    }
}

struct ContentView: View {
    /// 1.0 matches the reference; push toward 1.3 for more pronounced folds
    @State private var morph: Float = 1.0
    @State private var speed: Float = 1.0

    var body: some View {
        ZStack {
            // Reference background: light cool gray
            Color(red: 0.945, green: 0.945, blue: 0.950)
                .ignoresSafeArea()

            IridescentBlobView(morph: morph, speed: speed)
        }
        #if os(macOS)
        .toolbar {
            ToolbarItemGroup {
                Slider(value: $morph, in: 0.4...1.4) {
                    Text("Morph")
                }
                .frame(width: 120)

                Slider(value: $speed, in: 0.4...1.8) {
                    Text("Speed")
                }
                .frame(width: 120)
            }
        }
        #endif
    }
}
