import SwiftUI

@main
struct InternetSpeedApp: App {
    @StateObject private var speedTest = SpeedTestManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(manager: speedTest)
                .frame(width: 320, height: 360)
        } label: {
            Text(speedTest.menuBarTitle)
        }
        .menuBarExtraStyle(.window)
    }
}
