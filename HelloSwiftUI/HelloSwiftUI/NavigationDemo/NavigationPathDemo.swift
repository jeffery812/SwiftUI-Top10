import SwiftUI

// ============================================================================
// Demo 3 — NavigationPath (type-erased, programmatic)
//
// When one stack must hold DIFFERENT value types (Fruit, Int, String…),
// bind it to a NavigationPath instead of a typed array.
//   + Mixed types, each mapped by its own navigationDestination(for:)
//   + Can be saved / restored via `path.codable` when all elements are Codable
//   – You can't read the elements back (only count / append / removeLast)
// A typed `[Route]` (Demo 2) is usually clearer; reach for NavigationPath
// when features in different modules push their own types.
// ============================================================================

struct NavigationPathDemo: View {
    //@State private var path = NavigationPath()
    @State private var router = Router()
    @State private var savedPath: Data?

    var body: some View {
        NavigationStack(path: $router.path) {
            List {
                Section("Append different types") {
                    Button("Append Fruit (Cherry)")  { router.path.append(.fruit(Fruit.find("Cherry").id)) }
                    Button("Append Int (7)")         { router.path.append(.int(7)) }
                    Button("Append String (\"Hej\")") { router.path.append(.string("Hej")) }
                    Button("Append all three")       {
                        router.path.append(.fruit(Fruit.find("Lemon").id))
                        router.path.append(.int(99))
                        router.path.append(.string("Hello"))
                    }
                }
            }
            .navigationTitle("NavigationPath")
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
            .navigationDestination(for: Fruit.self) { fruit in
//                Text("FruitHeader")
                FruitHeader(path: $router.path, fruit: fruit).navigationTitle("Fruit")
            }
            .navigationDestination(for: Int.self) { number in
                Text("\(number)")
                    .font(.system(size: 120, weight: .black, design: .rounded))
                    .navigationTitle("Int")
            }
            .navigationDestination(for: String.self) { text in
                Text("text: \(text)").font(.largeTitle).navigationTitle("String")
            }
        }
        .environment(router)
        .safeAreaInset(edge: .bottom) {
            controls
        }
    }
    
    
    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .fruit(let id):
//            ProgrammaticFruitDetail(fruit: .find(id))
            FruitHeader(path: $router.path, fruit: .find(id))
                .navigationTitle("Fruit")
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

    /// Stays visible on every pushed screen.
    @ViewBuilder
    private var controls: some View {
        let path = router.path
        VStack(spacing: 8) {
            Text("path.count = \(path.count)")
                .font(.caption.monospaced())
            HStack {
                Button("Pop") { if !path.isEmpty { router.path.removeLast() } }
                Button("Root") { router.path = [] }
                Button("Save") { save() }
                    .disabled(path.isEmpty)
                Button("Restore") { restore() }
                    .disabled(savedPath == nil)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    // State restoration. In a real app, keep the Data in @SceneStorage.
    private func save() {
//        guard let representation = router.path.codable else { return }   // nil if any element isn't Codable
//        savedPath = try? JSONEncoder().encode(representation)
    }

    private func restore() {
//        guard let savedPath,
//              let representation = try? JSONDecoder().decode(NavigationPath.CodableRepresentation.self,
//                                                             from: savedPath)
//        else { return }
//        path = NavigationPath(representation)
    }
}

#Preview {
    NavigationPathDemo()
}
