import SwiftUI

@main
struct thirstyinromeApp: App {
    @State private var viewModel = PlaceViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
    }
}
