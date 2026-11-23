import SwiftUI
import Observation
import Combine          // for ObservableObject / @Published (MemberImportVisibility is on)

// ============================================================================
// When does a property wrapper's initial value actually get evaluated?
//
//   @StateObject private var model = LegacyModel()
//       Documented: the parameter is an @autoclosure. SwiftUI calls it once,
//       when the view's identity is first installed.
//
//   @State private var model = ObservableModel()
//       Commonly taught (iOS 17 era): an ordinary expression, evaluated every
//       time the view struct is created; SwiftUI keeps the first instance
//       and throws the rest away.
//
// MEASURED with Xcode 27.1 / iOS 27 SDK: @State's initial value is ALSO
// evaluated only once per identity, when the view is installed — both for
// @Observable classes and for plain classes. The SDK declares an
// @autoclosure overload of State.init(wrappedValue:) for Observable classes.
//
// This screen doesn't assume either behaviour: it counts struct creations and
// model inits separately, so it shows the truth for whatever SDK you build with.
// Tap "Re-render parent" and compare the two numbers in each row.
// ============================================================================

// MARK: - Global counters (deliberately NOT observable, so bumping them
// inside init/deinit never triggers a SwiftUI update by itself)

nonisolated enum InitStats {
    nonisolated(unsafe) static var counts: [String: Int] = [:]

    @discardableResult
    static func bump(_ key: String) -> Int {
        counts[key, default: 0] += 1
        return counts[key]!
    }
    static func count(_ key: String) -> Int { counts[key, default: 0] }
}

// MARK: - Models

/// iOS 17+ model, owned with @State.
@Observable
final class ObservableModel {
    let serial = InitStats.bump("model.observable")
    var taps = 0
    init() { print("🟠 ObservableModel #\(serial) init (pretend: open a database connection)") }
}

/// A plain class (not Observable) held in @State.
final class PlainModel {
    let serial = InitStats.bump("model.plain")
    var taps = 0          // not observed: changing it won't refresh the view
    init() { print("🟣 PlainModel #\(serial) init") }
}

/// Legacy model, owned with @StateObject.
final class LegacyModel: ObservableObject {
    let serial = InitStats.bump("model.legacy")
    @Published var taps = 0
    init() { print("🔵 LegacyModel #\(serial) init") }
}

// MARK: - Screen

struct StateInitDemo: View {
    @State private var parentTick = 0

    // Every run of this body calls the three child initializers again,
    // i.e. creates NEW child view structs.
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        parentTick += 1
                    } label: {
                        Label("Re-render parent (tick \(parentTick))", systemImage: "arrow.clockwise")
                    }
                } footer: {
                    Text("Each tap runs this screen's body again, which re-creates the child view structs below. Watch “struct created” grow while “model init” may not.")
                }

                Section("@State var model = ObservableModel()") {
                    ObservableStateChild(tick: parentTick)
                }

                Section("@State var model = PlainModel()") {
                    PlainStateChild(tick: parentTick)
                }

                Section("@StateObject var model = LegacyModel()") {
                    StateObjectChild(tick: parentTick)
                }

                Section {
                    // Reads the counters in ITS OWN body, which runs after the
                    // parent's body has created the child structs.
                    StatsView(tick: parentTick)
                } header: {
                    Text("Counters")
                } footer: {
                    Text("If “model init” equals “struct created”, the initial value is evaluated every time the struct is created. If it stays at 1, it's evaluated once per identity (lazily, like an @autoclosure). The console logs each init in order.")
                }
            }
            .navigationTitle("Initial-value evaluation")
        }
    }
}

// MARK: - Children (each counts its own struct creations)

private struct ObservableStateChild: View {
    let tick: Int
    @State private var model = ObservableModel()

    init(tick: Int) {
        self.tick = tick
        InitStats.bump("struct.observable")
        print("📦 ObservableStateChild struct created (tick \(tick))")
    }

    var body: some View {
        ModelRow(serial: model.serial, taps: model.taps) { model.taps += 1 }
    }
}

private struct PlainStateChild: View {
    let tick: Int
    @State private var model = PlainModel()

    init(tick: Int) {
        self.tick = tick
        InitStats.bump("struct.plain")
        print("📦 PlainStateChild struct created (tick \(tick))")
    }

    var body: some View {
        // PlainModel isn't observable: +1 changes `taps`, but the row only
        // shows it after the next parent re-render.
        ModelRow(serial: model.serial, taps: model.taps) { model.taps += 1 }
    }
}

private struct StateObjectChild: View {
    let tick: Int
    @StateObject private var model = LegacyModel()

    init(tick: Int) {
        self.tick = tick
        InitStats.bump("struct.legacy")
        print("📦 StateObjectChild struct created (tick \(tick))")
    }

    var body: some View {
        ModelRow(serial: model.serial, taps: model.taps) { model.taps += 1 }
    }
}

// MARK: - Building blocks

/// Shows which instance the view is actually using, and lets you change its
/// state to prove the state survives parent re-renders.
private struct ModelRow: View {
    let serial: Int
    let taps: Int
    let onTap: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Instance in use: #\(serial)").font(.body.monospaced().bold())
                Text("taps = \(taps)").font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            Spacer()
            Button("+1", action: onTap).buttonStyle(.bordered)
        }
    }
}

private struct StatsView: View {
    let tick: Int

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
            GridRow {
                Text("Wrapper + model").bold()
                Text("struct created").bold()
                Text("model init").bold()
            }
            Divider()
            row("@State + @Observable", "observable")
            row("@State + plain class", "plain")
            row("@StateObject", "legacy")
        }
        .font(.caption.monospaced())
    }

    private func row(_ title: String, _ key: String) -> some View {
        let structs = InitStats.count("struct.\(key)")
        let inits = InitStats.count("model.\(key)")
        return GridRow {
            Text(title)
            Text("\(structs)")
            Text("\(inits)").foregroundStyle(inits > 1 ? .red : .green)
        }
    }
}

#Preview {
    StateInitDemo()
}
