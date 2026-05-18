import AppVitalsCore
import Foundation

public actor NetworkTransactionStore {
    private var transactions: RingBuffer<NetworkTransaction>

    public init(limit: Int = AppVitalsLimits.production.maxNetworkTransactions) {
        transactions = RingBuffer(capacity: limit)
    }

    public func append(_ transaction: NetworkTransaction) {
        transactions.append(transaction)
    }

    public func all() -> [NetworkTransaction] {
        transactions.elements
    }

    public func search(_ query: String) -> [NetworkTransaction] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return transactions.elements }
        return transactions.elements.filter { transaction in
            transaction.request.url.absoluteString.localizedCaseInsensitiveContains(trimmed)
                || transaction.request.method.localizedCaseInsensitiveContains(trimmed)
                || transaction.response.map { String($0.statusCode).contains(trimmed) } == true
                || transaction.errorDescription?.localizedCaseInsensitiveContains(trimmed) == true
        }
    }

    public func removeAll() {
        transactions.removeAll()
    }
}
