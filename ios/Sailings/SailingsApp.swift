import SwiftUI

@main
struct SailingsApp: App {
    @State private var auth = AuthStore()

    var body: some Scene {
        WindowGroup {
            Group {
                switch auth.state {
                case .restoring:
                    ProgressView()
                case .signedOut:
                    LoginView()
                case .signedIn:
                    RootView()
                }
            }
            .environment(auth)
            .task { await auth.restore() }
        }
    }
}
