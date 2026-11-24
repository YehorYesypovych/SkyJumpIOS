import Foundation

/// Стан екрана, що завантажує дані з сервера.
enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(message: String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    /// Дані, якщо вони вже є.
    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }
}

extension LoadState: Equatable where Value: Equatable {}
