# SwiftUI Top 10

A study guide to the ten iOS / SwiftUI topics that come up most in senior-level interviews, plus a small SwiftUI app with runnable demos for some of them.

## Contents

| Path | What it is |
|---|---|
| [`index.html`](index.html) | The study guide: a single self-contained HTML page |
| [`HelloSwiftUI/`](HelloSwiftUI) | Xcode project with interactive demos |

## The study guide

Open `index.html` in a browser. It needs no build step and no dependencies; only the web fonts load from Google Fonts.

Each chapter follows the same structure: why interviewers ask about it, the mental model, code you should be able to write on a whiteboard, common traps, and likely interview questions with model answers (click a question to reveal its answer).

1. **View Identity & Lifetime**: structural vs explicit identity, `ForEach` IDs, `AnyView` and type erasure, `.task` vs `onAppear`
2. **State & Data Flow**: ownership, `@Observable` vs `ObservableObject`, migrating from `@StateObject`, nested observable objects
3. **Swift Concurrency**: structured concurrency, actor reentrancy, `@MainActor`, `Sendable`, Swift 6 migration
4. **Memory & ARC**: `weak` vs `unowned`, retain cycles in closures, Combine, timers and tasks
5. **Value Types, Protocols & Generics**: copy-on-write, dispatch, `some` vs `any`
6. **App Architecture**: MVVM / TCA / MV trade-offs, dependency injection, SPM modularisation, mobile system design
7. **Navigation**: `NavigationStack`, routers, deep links, state restoration
8. **Performance**: a profiling method, reducing body invalidation, images, launch time
9. **Layout & Animation**: the layout negotiation between parent and child, a custom `Layout`, transactions and transitions
10. **Testing**: Swift Testing, testing async view models, test strategy

A final section covers quick topics: UIKit interop, SwiftData, Combine, security, accessibility, and more.

## The demo app

Open `HelloSwiftUI/HelloSwiftUI.xcodeproj` and run it on an iPhone simulator.

**Requirements:** Xcode 27, deployment target iOS 27. The demos use `@Observable` and the `Tab` API, so they need at least iOS 18 if you lower the deployment target.

| Tab | Source | Demonstrates |
|---|---|---|
| Declarative | `NavigationDemo/DeclarativeNavigationDemo.swift` | `NavigationStack` without a path: `NavigationLink { destination }` vs `NavigationLink(value:)` + `navigationDestination(for:)` |
| Programmatic | `NavigationDemo/ProgrammaticNavigationDemo.swift` | A typed `[Route]` path in an `@Observable` router: push, pop, pop to root, deep links, `navigationDestination(item:)` / `(isPresented:)`, and a live view of the path |
| NavigationPath | `NavigationDemo/NavigationPathDemo.swift` | A type-erased `NavigationPath` with mixed value types, plus saving and restoring the path with `codable` |
| Identity | `IdentityDemo/AnyViewIdentityDemo.swift` | How `AnyView` makes identity accidental: same wrapped type keeps state with no transition; a changed wrapped type resets state |
| Nested | `ObservationDemo/NestedObservationDemo.swift` | Which views refresh when a member of an `@Observable` model changes: a plain class, an `@Observable` class, a struct, or an array |

The Identity and Nested demos make refreshes visible: cards carry their own `@State` counters, and reader rows show how many times their `body` has run. The Nested demo also logs `Self._printChanges()` to the Xcode console.
