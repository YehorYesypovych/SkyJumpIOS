import Foundation

/// Стан гри з погляду гравця.
enum GameOutcome: Equatable {
    case playing
    case won     // піднявся до висоти верхньої платформи
    case lost    // впав нижче екрана
}
