import Foundation

/// Джерело рівня: звідки беруться платформи для ігрової сесії.
/// ViewModel знає лише цей протокол, конкретну реалізацію передають ззовні.
protocol LevelProviding {
    func makeLevel() -> [Platform]
}
