import SwiftUI

/// Each tab owns its own NavigationStack — never nest stacks.
struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Declarative", systemImage: "hand.tap") {
                DeclarativeNavigationDemo()
            }
            Tab("Programmatic", systemImage: "curlybraces") {
                ProgrammaticNavigationDemo()
            }
            Tab("NavigationPath", systemImage: "point.3.connected.trianglepath.dotted") {
                NavigationPathDemo()
            }
            Tab("Identity", systemImage: "square.on.square") {
                AnyViewIdentityDemo()
            }
            Tab("Nested", systemImage: "eye") {
                NestedObservationDemo()
            }
            Tab("Init", systemImage: "hammer") {
                StateInitDemo()
            }
        }
    }
}

#Preview {
    ContentView()
}
