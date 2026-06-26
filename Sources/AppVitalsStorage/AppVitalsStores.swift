public struct AppVitalsStores: Sendable {
    public let events: EventStore
    public let network: NetworkTransactionStore
    public let crashContext: CrashContextStore
    public let memory: MemoryStore
    public let sharedState: AppVitalsSharedState

    public init(
        events: EventStore,
        network: NetworkTransactionStore,
        crashContext: CrashContextStore,
        memory: MemoryStore = MemoryStore(),
        sharedState: AppVitalsSharedState = AppVitalsSharedState()
    ) {
        self.events = events
        self.network = network
        self.crashContext = crashContext
        self.memory = memory
        self.sharedState = sharedState
    }
}
