import SwiftUI

struct RootView: View {
    /// Bumped whenever a registration changes, so the other tabs refetch instead
    /// of showing a stale list when the user switches to them.
    @State private var registrationsChanged = 0

    var body: some View {
        TabView {
            VoyageListView(registrationsChanged: $registrationsChanged)
                .tabItem { Label("Voyages", systemImage: "sailboat") }

            MyRegistrationsView(registrationsChanged: $registrationsChanged)
                .tabItem { Label("My Registrations", systemImage: "checklist") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}
