public struct RingBuffer<Element: Sendable>: Sendable {
    private var storage: [Element?]
    private var writeIndex: Int = 0
    private var count: Int = 0
    private let capacity: Int

    public init(capacity: Int) {
        self.capacity = max(1, capacity)
        storage = Array(repeating: nil, count: max(1, capacity))
    }

    public mutating func append(_ element: Element) {
        storage[writeIndex] = element
        writeIndex = (writeIndex + 1) % capacity
        if count < capacity { count += 1 }
    }

    public mutating func removeAll() {
        storage = Array(repeating: nil, count: capacity)
        writeIndex = 0
        count = 0
    }

    public var isEmpty: Bool {
        count == 0 // swiftlint:disable:this empty_count
    }

    public var elements: [Element] {
        guard !isEmpty else { return [] }
        if count < capacity {
            return storage.prefix(count).compactMap(\.self)
        }
        return (0 ..< capacity).compactMap { storage[(writeIndex + $0) % capacity] }
    }
}
