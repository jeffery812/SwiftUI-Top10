import SwiftUI
import Observation

// ============================================================================
// Nested objects & Observation
//
// Question: CartModel is @Observable. If one of its members is a class and
// that class changes, does the view refresh?
//
// Answer: only if the member class is ALSO @Observable. Observation records
// every property a view's body reads along the key path:
//     Text(cart.customer.name)
//          → registers CartModel.customer  AND  Customer.name
// so only views that read the changed property refresh.
//
// Each "reader" row below reads exactly ONE thing and shows how many times
// its body has run. The background tint changes on every body evaluation,
// so a refresh is easy to see. The console also logs Self._printChanges().
// ============================================================================

// MARK: - Model

/// Plain class: invisible to Observation.
final class PlainCustomer {
    var name: String
    init(name: String) { self.name = name }
}

/// Observable class: each property is tracked individually.
@Observable
final class ObservableCustomer {
    var name = "Anna"
    var level = 1
}

/// Struct member: changing any field reassigns the WHOLE property.
struct Address {
    var city = "Solna"
    var zip = "169 70"
}

struct CartItem: Identifiable {
    let id = UUID()
}

@Observable
final class NestedCartModel {
    var plainCustomer = PlainCustomer(name: "Anna")
    var customer = ObservableCustomer()
    var address = Address()
    var items: [CartItem] = []
}

// MARK: - Screen

struct NestedObservationDemo: View {
    @State private var cart = NestedCartModel()

    // NOTE: this view's body reads NO cart properties itself, so it never
    // refreshes. Reads inside button actions aren't tracked.
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ReaderRow(title: "plainCustomer.name", note: "plain class") {
                        PlainNameReader(cart: cart)
                    }
                    ReaderRow(title: "customer.name", note: "@Observable class") {
                        CustomerNameReader(cart: cart)
                    }
                    ReaderRow(title: "customer.level", note: "@Observable class") {
                        CustomerLevelReader(cart: cart)
                    }
                    ReaderRow(title: "address.city", note: "struct") {
                        CityReader(cart: cart)
                    }
                    ReaderRow(title: "address.zip", note: "struct") {
                        ZipReader(cart: cart)
                    }
                    ReaderRow(title: "items.count", note: "array") {
                        ItemsReader(cart: cart)
                    }
                } header: {
                    Text("Readers: each reads one property")
                } footer: {
                    Text("The badge counts body evaluations. The tint changes every time body runs.")
                }

                Section("1 · Member is a plain class") {
                    MutationButton(
                        "plainCustomer.name = random",
                        expect: "❌ Nothing refreshes. The plain row shows a stale name."
                    ) {
                        cart.plainCustomer.name = randomName()
                    }
                    MutationButton(
                        "plainCustomer = PlainCustomer(…)",
                        expect: "✅ Plain row refreshes (the reference was reassigned) and the hidden name shows up."
                    ) {
                        cart.plainCustomer = PlainCustomer(name: cart.plainCustomer.name)
                    }
                }

                Section("2 · Member is an @Observable class") {
                    MutationButton(
                        "customer.name = random",
                        expect: "✅ Only the customer.name row refreshes."
                    ) {
                        cart.customer.name = randomName()
                    }
                    MutationButton(
                        "customer.level += 1",
                        expect: "✅ Only the customer.level row refreshes."
                    ) {
                        cart.customer.level += 1
                    }
                    MutationButton(
                        "customer = ObservableCustomer()",
                        expect: "✅ Both customer rows refresh (CartModel.customer changed)."
                    ) {
                        cart.customer = ObservableCustomer()
                    }
                }

                Section("3 · Member is a struct") {
                    MutationButton(
                        "address.city = random",
                        expect: "⚠️ BOTH city and zip rows refresh: the whole address property was set."
                    ) {
                        cart.address.city = ["Solna", "Uppsala", "Malmö", "Lund"].randomElement()!
                    }
                }

                Section("4 · Array") {
                    MutationButton(
                        "items.append(…)",
                        expect: "✅ Only the items.count row refreshes."
                    ) {
                        cart.items.append(CartItem())
                    }
                }
            }
            .navigationTitle("Nested Observation")
        }
    }

    private func randomName() -> String {
        ["Anna", "Erik", "Mia", "Max", "Lars", "Sofia", "Oskar"].randomElement()!
    }
}

// MARK: - Readers (each body reads exactly one property)

private struct PlainNameReader: View {
    let cart: NestedCartModel
    @State private var renders = RenderCount()
    var body: some View {
        let _ = Self._printChanges()
        RenderBadge(count: renders.bump()) { Text(cart.plainCustomer.name) }
    }
}

private struct CustomerNameReader: View {
    let cart: NestedCartModel
    @State private var renders = RenderCount()
    var body: some View {
        let _ = Self._printChanges()
        RenderBadge(count: renders.bump()) { Text(cart.customer.name) }      // registers .customer + .name
    }
}

private struct CustomerLevelReader: View {
    let cart: NestedCartModel
    @State private var renders = RenderCount()
    var body: some View {
        let _ = Self._printChanges()
        RenderBadge(count: renders.bump()) { Text("Lv \(cart.customer.level)") }
    }
}

private struct CityReader: View {
    let cart: NestedCartModel
    @State private var renders = RenderCount()
    var body: some View {
        let _ = Self._printChanges()
        RenderBadge(count: renders.bump()) { Text(cart.address.city) }
    }
}

private struct ZipReader: View {
    let cart: NestedCartModel
    @State private var renders = RenderCount()
    var body: some View {
        let _ = Self._printChanges()
        RenderBadge(count: renders.bump()) { Text(cart.address.zip) }       // refreshes when city changes, too
    }
}

private struct ItemsReader: View {
    let cart: NestedCartModel
    @State private var renders = RenderCount()
    var body: some View {
        let _ = Self._printChanges()
        RenderBadge(count: renders.bump()) { Text("\(cart.items.count)") }
    }
}

// MARK: - Building blocks

/// Not observable on purpose: bumping it inside body must not trigger updates.
/// Held in @State so it survives body re-evaluations of the reader.
private final class RenderCount {
    private(set) var value = 0
    func bump() -> Int { value += 1; return value }
}

/// Shows a reader's content with its body-evaluation count.
/// The count is taken in the READER's body, so it counts exactly that body.
private struct RenderBadge<Content: View>: View {
    let count: Int
    let content: Content

    init(count: Int, @ViewBuilder content: () -> Content) {
        self.count = count
        self.content = content()
    }

    var body: some View {
        HStack {
            content
                .font(.body.monospaced())
            Spacer()
            Text("body × \(count)")
                .font(.caption.monospacedDigit().bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.thinMaterial, in: .capsule)
        }
        .padding(8)
        .background(
            Color(hue: .random(in: 0...1), saturation: 0.5, brightness: 1).opacity(0.35),
            in: .rect(cornerRadius: 8)
        )
    }
}

private struct ReaderRow<Reader: View>: View {
    let title: String
    let note: String
    @ViewBuilder var reader: Reader

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.caption.monospaced().bold())
                Text(note).font(.caption2).foregroundStyle(.secondary)
            }
            reader
        }
    }
}

private struct MutationButton: View {
    let title: String
    let expect: String
    let action: () -> Void

    init(_ title: String, expect: String, action: @escaping () -> Void) {
        self.title = title
        self.expect = expect
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.callout.monospaced())
                Text(expect).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NestedObservationDemo()
}
