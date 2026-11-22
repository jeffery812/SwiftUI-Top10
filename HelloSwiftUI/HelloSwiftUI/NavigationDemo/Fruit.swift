import SwiftUI

/// Sample model shared by all NavigationStack demos.
/// `Hashable` is required to be used as a NavigationLink value;
/// `Codable` lets a NavigationPath containing it be saved and restored.
struct Fruit: Identifiable, Hashable, Codable {
    let id: String          // name doubles as a stable identity
    let emoji: String
    let origin: String
    let calories: Int

    static let samples: [Fruit] = [
        Fruit(id: "Apple",  emoji: "🍎", origin: "Kazakhstan",       calories: 52),
        Fruit(id: "Banana", emoji: "🍌", origin: "Southeast Asia",   calories: 89),
        Fruit(id: "Mango",  emoji: "🥭", origin: "South Asia",       calories: 60),
        Fruit(id: "Kiwi",   emoji: "🥝", origin: "China",            calories: 61),
        Fruit(id: "Cherry", emoji: "🍒", origin: "Anatolia",         calories: 50),
        Fruit(id: "Lemon",  emoji: "🍋", origin: "Northeast India",  calories: 29),
    ]

    static func find(_ id: Fruit.ID) -> Fruit {
        samples.first { $0.id == id } ?? samples[0]
    }
}

// MARK: - Shared small views

struct FruitRow: View {
    let fruit: Fruit
    var body: some View {
        HStack(spacing: 12) {
            Text(fruit.emoji).font(.largeTitle)
            VStack(alignment: .leading) {
                Text(fruit.id).font(.headline)
                Text("\(fruit.calories) kcal / 100 g").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct FruitHeader: View {
    @Binding var path: [Route]
    let fruit: Fruit
    var body: some View {
        VStack(spacing: 8) {
            Text(fruit.emoji).font(.system(size: 96))
            Text(fruit.id).font(.largeTitle.bold())
            Text("\(fruit.calories) kcal / 100 g").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
        .onTapGesture {
            print("== go next")
            path.append(.int(9))
            path.append(.string("99"))
        }
    }
}

struct OriginView: View {
    let fruit: Fruit
    var body: some View {
        ContentUnavailableView(
            "Origin of \(fruit.id)",
            systemImage: "globe.europe.africa.fill",
            description: Text("\(fruit.emoji) was first cultivated in \(fruit.origin).")
        )
        .navigationTitle("Origin")
    }
}
