import Foundation

#if canImport(HealthKit) && os(iOS)
@preconcurrency import HealthKit
#endif

public final class HealthKitService: HealthKitServiceProtocol, @unchecked Sendable {
    #if canImport(HealthKit) && os(iOS)
    private let healthStore: HKHealthStore

    public init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }
    #else
    public init() {}
    #endif

    public var isAvailable: Bool {
        #if canImport(HealthKit) && os(iOS)
        HKHealthStore.isHealthDataAvailable()
        #else
        false
        #endif
    }

    public func authorizationStatusDescription() -> String {
        guard isAvailable else {
            return "이 기기에서는 Apple 건강앱 데이터를 읽을 수 없습니다."
        }

        return "건강 데이터 연결을 누르면 Apple 건강앱 읽기 권한만 요청합니다."
    }

    public func requestReadPermission() async -> HealthMetricPermissionState {
        #if canImport(HealthKit) && os(iOS)
        guard isAvailable else { return .unavailable }

        do {
            let readTypes = Set(readQuantityTypes().values.map { $0 as HKObjectType })
            try await healthStore.requestAuthorization(
                toShare: Set<HKSampleType>(),
                read: readTypes
            )
            return .readRequestCompleted
        } catch {
            return .denied
        }
        #else
        .unavailable
        #endif
    }

    public func fetchSamples(
        metricType: HealthMetricType,
        dateRange: HealthMetricDateRange
    ) async -> [HealthMetricSample] {
        #if canImport(HealthKit) && os(iOS)
        guard isAvailable,
              let quantityType = readQuantityTypes()[metricType],
              let unit = unit(for: metricType) else {
            return []
        }

        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: dateRange.start,
                end: dateRange.end,
                options: [.strictStartDate]
            )
            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: true
            )
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard error == nil,
                      let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let mappedSamples = quantitySamples.map { sample in
                    let rawValue = sample.quantity.doubleValue(for: unit)
                    return HealthMetricSample(
                        metricType: metricType,
                        value: HealthMetricUnitConverter.displayValue(
                            metricType: metricType,
                            healthKitQuantityValue: rawValue
                        ),
                        unit: metricType.unitLabel,
                        measuredAt: sample.startDate,
                        sourceName: sample.sourceRevision.source.name,
                        sourceBundleIdentifier: sample.sourceRevision.source.bundleIdentifier
                    )
                }
                .sortedByMeasuredAtAscending()

                continuation.resume(returning: mappedSamples)
            }

            healthStore.execute(query)
        }
        #else
        []
        #endif
    }

    public func fetchLatestSample(metricType: HealthMetricType) async -> HealthMetricSample? {
        let samples = await fetchSamples(
            metricType: metricType,
            dateRange: .days(365, endingAt: Date())
        )
        return samples.latestSample(metricType: metricType)
    }
}

#if canImport(HealthKit) && os(iOS)
private extension HealthKitService {
    func readQuantityTypes() -> [HealthMetricType: HKQuantityType] {
        var quantityTypes: [HealthMetricType: HKQuantityType] = [:]

        for metricType in HealthMetricType.readOnlyHealthKitMetrics {
            guard let identifier = quantityIdentifier(for: metricType),
                  let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
                continue
            }
            quantityTypes[metricType] = quantityType
        }

        return quantityTypes
    }

    func quantityIdentifier(for metricType: HealthMetricType) -> HKQuantityTypeIdentifier? {
        switch metricType {
        case .systolicBloodPressure:
            .bloodPressureSystolic
        case .diastolicBloodPressure:
            .bloodPressureDiastolic
        case .bodyMass:
            .bodyMass
        case .bodyFatPercentage:
            .bodyFatPercentage
        case .bodyMassIndex:
            .bodyMassIndex
        case .leanBodyMass:
            .leanBodyMass
        case .restingHeartRate:
            .restingHeartRate
        case .respiratoryRate:
            .respiratoryRate
        case .sleepDuration:
            nil
        }
    }

    func unit(for metricType: HealthMetricType) -> HKUnit? {
        switch metricType {
        case .systolicBloodPressure, .diastolicBloodPressure:
            .millimeterOfMercury()
        case .bodyMass, .leanBodyMass:
            .gramUnit(with: .kilo)
        case .bodyFatPercentage:
            .percent()
        case .bodyMassIndex:
            .count()
        case .restingHeartRate, .respiratoryRate:
            .count().unitDivided(by: .minute())
        case .sleepDuration:
            nil
        }
    }
}
#endif
