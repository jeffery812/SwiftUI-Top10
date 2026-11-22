import SwiftUI

// ============================================================================
// AnyView makes identity accidental
//
// SwiftUI ties @State, lifetime and transitions to a view's IDENTITY.
// With @ViewBuilder, identity comes from the structure you wrote
// (each if/else branch is a separate slot of _ConditionalContent).
// With AnyView, identity comes from whichever concrete type happens to be
// inside the box at runtime:
//   • same wrapped type      → treated as the SAME view (state kept, no transition)
//   • different wrapped type → treated as a NEW view    (state reset, transition)
//
// Each card below has its own @State counter, so you can see when SwiftUI
// keeps a view and when it destroys and recreates it.
// ============================================================================

struct AnyViewIdentityDemo: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 36) {
                    Text("Tap **+1** on the cards a few times, then use the buttons below them. Watch the counters and the animations.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    SameTypeSection()
                    Divider()
                    TypeChangeSection()
                    Divider()
                    TakeawaySection()
                }
                .padding()
            }
            .navigationTitle("AnyView Identity")
        }
    }
}

// MARK: - 1. Same wrapped type → "same view" (the reverse case)

private struct SameTypeSection: View {
    @State private var flag = true

    private let slide: AnyTransition = .asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading)
    ).combined(with: .opacity)

    var body: some View {
        let _ = Self._printChanges()
        DemoSection(
            number: "1",
            title: "Same type inside AnyView = same view",
            detail: "Both sides switch between card A and card B. With @ViewBuilder the two branches are two distinct identities: the old card slides out, a new one slides in, and its counter starts at 0. With AnyView both branches wrap the same type (CounterCard), so SwiftUI treats it as ONE view whose content changed: no transition, and the counter carries over from A to B."
        ) {
            HStack(alignment: .top, spacing: 12) {
                Column(caption: "@ViewBuilder if / else", code: "if flag { A } else { B }") {
                    ZStack { viewBuilderVersion }          // ZStack so in/out cards can overlap
                }
                Column(caption: "AnyView ternary", code: "flag ? AnyView(A) : AnyView(B)") {
                    ZStack { anyViewVersion }
                }
            }

            Button {
                withAnimation(.easeInOut(duration: 0.5)) { flag.toggle() }
            } label: {
                Label("Toggle flag (now \(flag ? "A" : "B"))", systemImage: "arrow.left.arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // Static type: _ConditionalContent<CounterCard…, CounterCard…>
    // → two slots, two identities.
    @ViewBuilder
    private var viewBuilderVersion: some View {
        if flag {
//            CounterCard(label: "A", color: .orange).transition(slide)
            CounterCard(label: "A", color: .orange).transition(.blurReplace)
        } else {
            CounterCard(label: "B", color: .blue).transition(.blurReplace)
        }
    }

    // Static type: AnyView. Wrapped type is identical in both branches
    // → SwiftUI updates the existing view in place. The .transition never runs.
    private var anyViewVersion: AnyView {
        flag
            ? AnyView(CounterCard(label: "A", color: .orange).transition(slide))
            : AnyView(CounterCard(label: "B", color: .blue).transition(slide))
    }
}

// MARK: - 2. Different wrapped type → state reset, invisible in the code

private struct TypeChangeSection: View {
    @State private var highlighted = false

    var body: some View {
        DemoSection(
            number: "2",
            title: "Wrapped type changes = state reset",
            detail: "Turning on the highlight looks purely cosmetic. But on the left the AnyView holds CounterCard in one case and CounterCard + overlay in the other: two different types. Every toggle destroys the card and builds a new one, so the counter resets. It behaves like an if/else, but nothing in the code shows it. On the right a modifier changes only an attribute, so the identity stays the same and the counter is kept."
        ) {
            HStack(alignment: .top, spacing: 12) {
                Column(caption: "AnyView, type changes",
                       code: "hl ? AnyView(card.overlay(…))\n   : AnyView(card)") {
                    anyViewVersion
                }
                Column(caption: "Modifier, same type ✅",
                       code: "card.overlay(…\n  hl ? .red : .clear)") {
                    modifierVersion
                }
            }

            Toggle("Highlight", isOn: $highlighted.animation())
                .padding(.horizontal, 4)
        }
    }

    // Wrapped type flips between
    //   CounterCard
    //   ModifiedContent<CounterCard, _OverlayModifier<…>>
    // → a brand-new identity on every toggle.
    private var anyViewVersion: AnyView {
        highlighted
            ? AnyView(CounterCard(label: "C", color: .green).overlay(highlightBorder(.red)))
            : AnyView(CounterCard(label: "C", color: .green))
    }

    // One static type; only the stroke colour changes → identity and state preserved.
    private var modifierVersion: some View {
        CounterCard(label: "C", color: .green)
            .overlay(highlightBorder(highlighted ? .red : .clear))
    }

    private func highlightBorder(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 12).stroke(color, lineWidth: 3)
    }
}

// MARK: - Takeaway

private struct TakeawaySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Takeaway").font(.title3.bold())
            Text("With AnyView, identity depends on **which type happens to be inside at runtime**, not on the structure you wrote. That makes state resets and missing transitions hard to predict and hard to debug.")
            Text("Prefer `@ViewBuilder`, `some View`, or modifiers that change attributes. Keep AnyView for real runtime heterogeneity, at a stable, high-level boundary.")
        }
        .font(.callout)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.yellow.opacity(0.12), in: .rect(cornerRadius: 12))
    }
}

// MARK: - Building blocks

/// A card with its own @State. If the counter goes back to 0,
/// SwiftUI destroyed the old view and created a new identity.
private struct CounterCard: View {
    let label: String
    let color: Color
    @State private var count = 0

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 44, weight: .black, design: .rounded))
            Text("count = \(count)")
                .font(.callout.monospacedDigit())
            Button("+1") { count += 1 }
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.18), in: .rect(cornerRadius: 12))
    }
}

private struct Column<Content: View>: View {
    let caption: String
    let code: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(caption).font(.caption.bold())
            Text(code)
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            content
                .frame(height: 150, alignment: .top)
                .clipped()                                // keep sliding cards inside the column
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DemoSection<Content: View>: View {
    let number: String
    let title: String
    let detail: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(number). \(title)").font(.title3.bold())
            Text(detail).font(.callout).foregroundStyle(.secondary)
            content
        }
    }
}

#Preview {
    AnyViewIdentityDemo()
}
