import AppVitalsCore
import Testing

@Test func ringBufferRetainsNewestElements() {
    var buffer = RingBuffer<Int>(capacity: 3)

    buffer.append(1)
    buffer.append(2)
    buffer.append(3)
    buffer.append(4)

    #expect(buffer.elements == [2, 3, 4])
}

@Test func ringBufferUnderCapacityRetainsAll() {
    var buffer = RingBuffer<Int>(capacity: 5)
    buffer.append(10)
    buffer.append(20)
    #expect(buffer.elements == [10, 20])
}

@Test func ringBufferRemoveAllClearsElements() {
    var buffer = RingBuffer<Int>(capacity: 3)
    buffer.append(1)
    buffer.append(2)
    buffer.removeAll()
    #expect(buffer.elements.isEmpty)
}

@Test func ringBufferExactCapacityRetainsAll() {
    var buffer = RingBuffer<Int>(capacity: 3)
    buffer.append(1)
    buffer.append(2)
    buffer.append(3)
    #expect(buffer.elements == [1, 2, 3])
}
