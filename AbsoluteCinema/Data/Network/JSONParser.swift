import Dispatch
import Foundation

enum JSONParser {
    static func decode<Value: Decodable & Sendable>(
        _ type: Value.Type, from data: Data
    ) async throws -> Value {
        try Task.checkCancellation()
        let value: Value = try await withCheckedThrowingContinuation { continuation in
            // GCD разбирает JSON в фоновой очереди, не занимая поток интерфейса.
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    continuation.resume(returning: try JSONDecoder().decode(type, from: data))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        // Отмена задачи не останавливает уже начатый блок GCD, но его результат не применится.
        try Task.checkCancellation()
        return value
    }
}
