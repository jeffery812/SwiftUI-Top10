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
    var suffix: String {
        String("\(id)".suffix(5))
    }
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
            // Buttons scroll; the readers stay pinned on top so you can see
            // which ones refresh while you tap.
            List {
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
            .safeAreaInset(edge: .top, spacing: 0) {
                readersPanel
            }
            .navigationTitle("Nested Observation")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    /// Six readers, each reading exactly one property. Pinned above the list.
    private var readersPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Each card reads ONE property. Its tint changes and its count goes up whenever its body runs.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    ReaderRow(title: "plainCustomer.name", note: "plain class") { PlainNameReader(cart: cart) }
                    ReaderRow(title: "customer.name", note: "@Observable") { CustomerNameReader(cart: cart) }
                }
                GridRow {
                    ReaderRow(title: "customer.level", note: "@Observable") { CustomerLevelReader(cart: cart) }
                    ReaderRow(title: "items.count", note: "array") { ItemsReader(cart: cart) }
                }
                GridRow {
                    ReaderRow(title: "address.city", note: "struct") { CityReader(cart: cart) }
                    ReaderRow(title: "address.zip", note: "struct") { ZipReader(cart: cart) }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
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
        RenderBadge(count: renders.bump()) { Text("\(cart.items.count) \(cart.items.last?.suffix ?? "")") }
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
        HStack(alignment: .firstTextBaseline) {
            content
                .font(.callout.monospaced().bold())
                .lineLimit(1)
            Spacer(minLength: 4)
            Text("body ×\(count)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Color(hue: .random(in: 0...1), saturation: 0.5, brightness: 1).opacity(0.4),
            in: .rect(cornerRadius: 8)
        )
    }
}

/// A compact card: which property, what kind of member, and the reader itself.
private struct ReaderRow<Reader: View>: View {
    let title: String
    let note: String
    @ViewBuilder var reader: Reader

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(title).font(.caption2.monospaced().bold()).lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                Text(note).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            reader
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        VStack(alignment: .leading, spacing: 6) {
            Button(action: action) {
                Label(title, systemImage: "hand.tap.fill")
                    .font(.footnote.monospaced().weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderedProminent)

            Text("Expect: \(expect)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NestedObservationDemo()
}
