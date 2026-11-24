import SwiftUI

/// Стікер у стилі «наліпки»: яскрава капсула з білою обвідкою, тінню і легким нахилом.
struct Sticker: View {
    let text: String
    var emoji: String?
    var color: Color = Theme.neonPink
    var angle: Double = -6

    var body: some View {
        HStack(spacing: 4) {
            if let emoji {
                Text(emoji)
            }
            Text(text)
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color, in: Capsule())
        .overlay(Capsule().stroke(.white, lineWidth: 3))
        .shadow(color: .black.opacity(0.25), radius: 4, y: 3)
        .rotationEffect(.degrees(angle))
        .accessibilityElement(children: .combine)
    }
}

/// Набори стікерів для результату гри. Вибір залежить від рахунку, тож однаковий результат — однаковий стікер.
enum StickerSet {
    struct Item {
        let text: String
        let emoji: String
        let color: Color
    }

    static let win: [Item] = [
        Item(text: "ІМБА", emoji: "🔥", color: Theme.neonPink),
        Item(text: "GG", emoji: "🏝️", color: Theme.electricBlue),
        Item(text: "ВЕРШИНА", emoji: "🌴", color: Theme.sunsetOrange)
    ]

    static let lose: [Item] = [
        Item(text: "skill issue", emoji: "💀", color: Theme.dusk),
        Item(text: "ще разок?", emoji: "👀", color: Theme.electricBlue),
        Item(text: "майже!", emoji: "🫠", color: Theme.sunsetOrange)
    ]

    static let newRecord = Item(text: "NEW PB", emoji: "🏆", color: Theme.neonMint)

    static func item(for outcome: GameOutcome, score: Int) -> Item {
        let set = outcome == .won ? win : lose
        return set[abs(score) % set.count]
    }
}

#Preview {
    VStack(spacing: 24) {
        Sticker(text: "ІМБА", emoji: "🔥")
        Sticker(text: "skill issue", emoji: "💀", color: Theme.dusk, angle: 5)
        Sticker(text: "NEW PB", emoji: "🏆", color: Theme.neonMint, angle: -3)
    }
    .padding()
}
