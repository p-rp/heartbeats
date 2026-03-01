import Foundation
import HealthKit
import WatchConnectivity
import Combine

/// Manages heart rate data from HealthKit
class HeartRateManager: NSObject, ObservableObject, WKExtensionDelegate {
    static let shared = HeartRateManager()

    // MARK: - Published Properties
    @Published var currentHeartRate: Double = 0
    @Published var isAuthorized = false
    @Published var authorizationError: Error?

    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKObserverQuery?
    private var anchor: HKQueryAnchor?
    private var heartbeatTimer: Timer?
    private var bpmHandler: ((Double) -> Void)?

    // Heart rate types to query
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

    private override init() {
        super.init()

        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
    }

    // MARK: - Authorization
    /// Requests HealthKit authorization for heart rate access
    func requestAuthorization() async throws {
        let typesToRead: Set<HKObjectType> = [heartRateType]

        try await healthStore.requestAuthorization(toShare: nil, read: typesToRead)

        await MainActor.run {
            self.isAuthorized = true
        }
    }

    // MARK: - Heart Rate Queries
    /// Starts streaming heart rate updates
    func startHeartRateUpdates(bpmHandler: @escaping (Double) -> Void) throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }

        self.bpmHandler = bpmHandler

        // Create an observer query for heart rate
        let observerQuery = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                print("Heart rate observer error: \(error.localizedDescription)")
                return
            }

            self?.fetchLatestHeartRate()
            completionHandler()
        }

        healthStore.execute(observerQuery)
        heartRateQuery = observerQuery

        // Fetch initial heart rate
        fetchLatestHeartRate()

        // Enable background delivery for heart rate
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { success, error in
            if let error = error {
                print("Background delivery error: \(error.localizedDescription)")
            }
        }
    }

    /// Stops heart rate updates
    func stopUpdates() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }

        healthStore.disableAllBackgroundDelivery()

        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        bpmHandler = nil

        DispatchQueue.main.async {
            self.currentHeartRate = 0
        }
    }

    /// Fetches the latest heart rate reading from HealthKit
    private func fetchLatestHeartRate() {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-60), end: Date(), options: .strictEndDate),
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            guard let self = self else { return }

            if let error = error {
                print("Heart rate query error: \(error.localizedDescription)")
                return
            }

            guard let sample = samples?.first as? HKQuantitySample else {
                return
            }

            let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
            let bpm = sample.quantity.doubleValue(for: heartRateUnit)

            DispatchQueue.main.async {
                self.currentHeartRate = bpm
                self.bpmHandler?(bpm)
            }
        }

        healthStore.execute(query)
    }

    /// Returns an async stream of heart rate updates
    func startHeartRateUpdates() async throws -> AsyncStream<Double> {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }

        return AsyncStream { continuation in
            Task {
                do {
                    try self.startHeartRateUpdates { bpm in
                        continuation.yield(bpm)
                    }
                } catch {
                    continuation.finish()
                }
            }

            continuation.onTermination = { @Sendable _ in
                self.stopUpdates()
            }
        }
    }

    // MARK: - Simulated Heart Rate (for testing without real data)
    /// Starts generating simulated heart rate data
    func startSimulatedHeartRate(bpmHandler: @escaping (Double) -> Void) {
        self.bpmHandler = bpmHandler

        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            // Generate realistic heart rate between 60-100 with some variation
            let baseBPM = 75.0
            let variation = Double.random(in: -15...25)
            let bpm = baseBPM + variation

            DispatchQueue.main.async {
                self?.currentHeartRate = bpm
                bpmHandler(bpm)
            }
        }
    }
}

// MARK: - HealthKit Errors
enum HealthKitError: LocalizedError {
    case notAuthorized
    case notAvailable
    case queryFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "HealthKit authorization is required to read heart rate data"
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .queryFailed(let error):
            return "Failed to query heart rate: \(error.localizedDescription)"
        }
    }
}
