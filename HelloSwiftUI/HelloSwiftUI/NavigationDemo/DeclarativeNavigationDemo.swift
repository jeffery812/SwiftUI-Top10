import SwiftUI

// ============================================================================
// Demo 1 — Declarative navigation (非代码控制)
//
// The user drives navigation by tapping NavigationLinks. There is NO path
// binding: NavigationStack manages its own internal stack, so code cannot
// push, pop, or deep-link. This is fine for simple drill-down UIs.
//
// Two styles are shown:
//   A. NavigationLink { destination } label: { ... }
//      – destination view is built inline. Simple, but tightly couples the
//        list to the destination and can't be driven from data later.
//   B. NavigationLink(value:) + .navigationDestination(for:)
//      – the link only carries a Hashable value; the stack maps values to
//        views in one place. Recommended — the same links keep working if
//        you later add a `path:` binding for programmatic control.
// ============================================================================

struct DeclarativeNavigationDemo: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Fruit.samples.prefix(2)) { fruit in
                        // A. Destination closure
                        NavigationLink {
                            DeclarativeFruitDetail(fruit: fruit)
                        } label: {
                            FruitRow(fruit: fruit)
                        }
                    }
                } header: {
                    Text("A · NavigationLink { destination }")
                } footer: {
                    Text("The destination view is written inline in the link.")
                }

                Section {
                    ForEach(Fruit.samples) { fruit in
                        // B. Value-based link
                        NavigationLink(value: fruit) {
                            FruitRow(fruit: fruit)
                        }
                    }
                    // Different value types can live in the same stack;
                    // each needs its own navigationDestination(for:).
                    NavigationLink(value: 42) {
                        Label("Lucky number 42", systemImage: "number")
                    }
                } header: {
                    Text("B · NavigationLink(value:) ✅ recommended")
                } footer: {
                    Text("Links carry values; .navigationDestination(for:) maps each value type to a view.")
                }
            }
            .navigationTitle("Declarative")
            // Register destinations OUTSIDE lazy containers (List/LazyVStack),
            // on a view that is always present in the stack.
            .navigationDestination(for: Fruit.self) { fruit in
                DeclarativeFruitDetail(fruit: fruit)
            }
            .navigationDestination(for: Int.self) { number in
                NumberDetail(number: number)
            }
        }
    }
}

/// Detail screen: keeps drilling down with more value-based links.
private struct DeclarativeFruitDetail: View {
    //@State private var path = NavigationPath()
    @State private var router = Router()
    let fruit: Fruit

    var body: some View {
        List {
            FruitHeader(path: $router.path, fruit: fruit)
                .listRowBackground(Color.clear)

            Section("Keep drilling down") {
                // A destination-closure link to a different screen
                NavigationLink {
                    OriginView(fruit: fruit)
                } label: {
                    Label("Where does it come from?", systemImage: "globe")
                }

                // Value links reuse the destinations registered at the root
                ForEach(Fruit.samples.filter { $0 != fruit }.prefix(3)) { other in
                    NavigationLink(value: other) {
                        Label("Try \(other.id) \(other.emoji)", systemImage: "arrow.right.circle")
                    }
                }
            }

            Section {
                Text("Use the back button or swipe from the left edge to go back. There's no way to jump back to the root from code here, because the stack isn't bound to any state.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(fruit.id)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

private struct NumberDetail: View {
    let number: Int
    var body: some View {
        VStack(spacing: 16) {
            Text("\(number)").font(.system(size: 120, weight: .black, design: .rounded))
            NavigationLink("Next: \(number + 1)", value: number + 1)
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Number")
    }
}

#Preview {
    DeclarativeNavigationDemo()
}
