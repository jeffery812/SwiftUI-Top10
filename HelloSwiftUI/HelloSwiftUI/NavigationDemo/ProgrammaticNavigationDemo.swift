import SwiftUI

// ============================================================================
// Demo 2 — Programmatic navigation (代码控制)
//
// NavigationStack(path:) is bound to an array of Route values that WE own.
// The navigation stack is now just data:
//     push        → path.append(route)
//     pop         → path.removeLast()
//     pop to root → path.removeAll()
//     deep link   → path = [.fruit(id), .origin(id)]   (jump several levels)
//
// The Router is injected through the environment so any screen can navigate
// without knowing who presented it.
//
// Also shown at the bottom of the root list:
//     .navigationDestination(item:)        – push driven by an Optional (iOS 17+)
//     .navigationDestination(isPresented:) – push driven by a Bool
// ============================================================================

/// Every screen reachable in this stack. Small, Hashable, and pass IDs —
/// not big models — so the destination always shows fresh data.
enum Route: Hashable {
    case string(String)
    case int(Int)
    case fruit(Fruit.ID)
    case origin(Fruit.ID)
    case compare(Fruit.ID, Fruit.ID)
}

@Observable
final class Router {
    var path: [Route] = []

    func push(_ route: Route) { path.append(route) }
    func pop()                { if !path.isEmpty { path.removeLast() } }
    func popToRoot()          { path.removeAll() }
    func pop(to index: Int)   { path.removeLast(path.count - index - 1) }

    /// Simulates handling a URL like  myapp://fruit/Mango/origin
    func handleDeepLink(fruit id: Fruit.ID) {
        path = [.fruit(id), .origin(id)]
    }
}

struct ProgrammaticNavigationDemo: View {
    @State private var router = Router()

    // State for the single-destination variants
    @State private var selectedFruit: Fruit?
    @State private var showRandom = false

    var body: some View {
        NavigationStack(path: $router.path) {
            List {
                Section("Push from code") {
                    Button("Push Apple") {
                        router.push(.fruit("Apple"))
                    }
                    Button("Push 3 screens at once") {
                        router.path.append(contentsOf: [.fruit("Kiwi"), .fruit("Lemon"), .fruit("Cherry")])
                    }
                    Button("Deep link → Mango › Origin") {
                        router.handleDeepLink(fruit: "Mango")
                    }
                    Button("Push after 1 s (e.g. after a network call)") {
                        Task {
                            try? await Task.sleep(for: .seconds(1))
                            router.push(.compare("Banana", "Mango"))
                        }
                    }
                }

                Section("Value links still work") {
                    // With a typed path, the value must be of the path's element type.
                    ForEach(Fruit.samples) { fruit in
                        NavigationLink(value: Route.fruit(fruit.id)) {
                            FruitRow(fruit: fruit)
                        }
                    }
                }

                Section {
                    Button("navigationDestination(item:) → random fruit") {
                        selectedFruit = Fruit.samples.randomElement()
                    }
                    Button("navigationDestination(isPresented:)") {
                        showRandom = true
                    }
                } header: {
                    Text("Single destination, driven by state")
                } footer: {
                    Text("These don't touch router.path. Setting the item to nil or the Bool to false pops the screen.")
                }
            }
            .navigationTitle("Programmatic")
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
            .navigationDestination(item: $selectedFruit) { fruit in
                FruitHeader(path: $router.path, fruit: fruit)
                    .navigationTitle("item:")
            }
            .navigationDestination(isPresented: $showRandom) {
                ContentUnavailableView("Pushed by a Bool", systemImage: "switch.2",
                                       description: Text("Set showRandom = false to pop."))
            }
        }
        .environment(router)
        // Applied to the stack itself, so it stays visible on every pushed screen.
        .safeAreaInset(edge: .bottom) {
            PathDebugBar(router: router)
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .fruit(let id):
            ProgrammaticFruitDetail(fruit: .find(id))
        case .origin(let id):
            OriginView(fruit: .find(id))
        case .compare(let a, let b):
            CompareView(a: .find(a), b: .find(b))
        case .int(let value):
            Text("Int \(value)")
        case .string(let value):
            Text("String \(value)")
        }
    }
}

// MARK: - Screens

struct ProgrammaticFruitDetail: View {
    @Environment(Router.self) private var router
    let fruit: Fruit

    var body: some View {
        List {
//            FruitHeader(path: router.path, fruit: fruit)
//                .listRowBackground(Color.clear)

            Section("Navigate from code") {
                Button("Push origin", systemImage: "globe") {
                    router.push(.origin(fruit.id))
                }
                Button("Compare with a random fruit", systemImage: "arrow.left.arrow.right") {
                    let other = Fruit.samples.filter { $0 != fruit }.randomElement()!
                    router.push(.compare(fruit.id, other.id))
                }
                Button("Pop", systemImage: "chevron.backward") {
                    router.pop()
                }
                Button("Pop to root", systemImage: "house") {
                    router.popToRoot()
                }
                .tint(.red)
            }
        }
        .navigationTitle(fruit.id)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct CompareView: View {
    @Environment(Router.self) private var router
    let a: Fruit
    let b: Fruit

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 40) {
                ForEach([a, b]) { fruit in
                    VStack {
                        Text(fruit.emoji).font(.system(size: 72))
                        Text("\(fruit.calories) kcal")
                    }
                }
            }
            Text(a.calories > b.calories ? "\(a.id) has more energy" : "\(b.id) has more energy")
                .font(.headline)
            Button("Replace whole stack with \(b.id)") {
                router.path = [.fruit(b.id)]       // replace instead of push
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Compare")
    }
}

/// Shows the current path and lets you jump to any level — proof that
/// the navigation stack is plain data.
private struct PathDebugBar: View {
    let router: Router

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Button("root") { router.popToRoot() }
                ForEach(Array(router.path.enumerated()), id: \.offset) { index, route in
                    Image(systemName: "chevron.right").font(.caption2)
                    Button(label(for: route)) { router.pop(to: index) }
                }
            }
            .font(.caption.monospaced())
            .buttonStyle(.bordered)
            .controlSize(.small)
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func label(for route: Route) -> String {
        switch route {
        case .fruit(let id):          id
        case .origin(let id):         "\(id).origin"
        case .compare(let a, let b):  "\(a)↔\(b)"
        case .int(let value): "Int \(value)"
        case .string(let value): "String \(value)"
        }
    }
}

#Preview {
    ProgrammaticNavigationDemo()
}
