import Foundation

#if canImport(HealthKit) && os(iOS)
@preconcurrency import HealthKit
#endif

public final class RealHealthKitService: HealthKitServiceProtocol, HealthDataServiceProtocol, @unchecked Sendable {
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

        return "건강 데이터 연결을 선택하면 Apple 건강앱 읽기 권한만 요청합니다."
    }

    public func requestReadPermission() async -> HealthMetricPermissionState {
        #if canImport(HealthKit) && os(iOS)
        guard isAvailable else { return .unavailable }

        let readTypes = Set(Self.supportedQuantityTypes().values.map { $0 as HKObjectType })
        guard !readTypes.isEmpty else { return .unavailable }

        do {
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
              let quantityType = Self.supportedQuantityTypes()[metricType],
              let unit = Self.unit(for: metricType) else {
            return []
        }

        if metricType.usesDailyCumulativeSum {
            return await fetchDailyCumulativeSamples(
                metricType: metricType,
                quantityType: quantityType,
                unit: unit,
                dateRange: dateRange
            )
        }

        return await fetchQuantitySamples(
            metricType: metricType,
            quantityType: quantityType,
            unit: unit,
            dateRange: dateRange
        )
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

    public func fetchSamplesForDay(
        _ date: Date,
        calendar: Calendar
    ) async -> [HealthMetricSample] {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(24 * 60 * 60)
        let range = HealthMetricDateRange(start: dayStart, end: dayEnd)
        var samples: [HealthMetricSample] = []

        for metricType in HealthMetricType.readOnlyHealthKitMetrics {
            let metricSamples = await fetchSamples(metricType: metricType, dateRange: range)
            samples.append(contentsOf: metricSamples)
        }

        return samples.sortedByMeasuredAtAscending()
    }

    public func fetchDailySummary(
        date: Date,
        calendar: Calendar
    ) async -> HealthDailySummary {
        let samples = await fetchSamplesForDay(date, calendar: calendar)
        return HealthDailySummary(date: calendar.startOfDay(for: date), samples: samples)
    }
}

public typealias HealthKitService = RealHealthKitService

#if canImport(HealthKit) && os(iOS)
private extension RealHealthKitService {
    func fetchQuantitySamples(
        metricType: HealthMetricType,
        quantityType: HKQuantityType,
        unit: HKUnit,
        dateRange: HealthMetricDateRange
    ) async -> [HealthMetricSample] {
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
                    HealthMetricSample(
                        metricType: metricType,
                        value: HealthMetricUnitConverter.displayValue(
                            metricType: metricType,
                            healthKitQuantityValue: sample.quantity.doubleValue(for: unit)
                        ),
                        unit: metricType.unitLabel,
                        measuredAt: sample.startDate,
                        sourceName: sample.sourceRevision.source.name,
                        sourceBundleIdentifier: sample.sourceRevision.source.bundleIdentifier
                    )
                }

                continuation.resume(returning: mappedSamples.sortedByMeasuredAtAscending())
            }

            healthStore.execute(query)
        }
    }

    func fetchDailyCumulativeSamples(
        metricType: HealthMetricType,
        quantityType: HKQuantityType,
        unit: HKUnit,
        dateRange: HealthMetricDateRange,
        calendar: Calendar = .current
    ) async -> [HealthMetricSample] {
        await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: dateRange.start,
                end: dateRange.end,
                options: [.strictStartDate]
            )
            var interval = DateComponents()
            interval.day = 1
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: [.cumulativeSum],
                anchorDate: calendar.startOfDay(for: dateRange.start),
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, collection, error in
                guard error == nil, let collection else {
                    continuation.resume(returning: [])
                    return
                }

                var samples: [HealthMetricSample] = []
                collection.enumerateStatistics(from: dateRange.start, to: dateRange.end) { statistics, _ in
                    guard let quantity = statistics.sumQuantity() else {
                        return
                    }
                    let value = HealthMetricUnitConverter.displayValue(
                        metricType: metricType,
                        healthKitQuantityValue: quantity.doubleValue(for: unit)
                    )
                    samples.append(
                        HealthMetricSample(
                            metricType: metricType,
                            value: value,
                            unit: metricType.unitLabel,
                            measuredAt: statistics.startDate,
                            sourceName: "Apple 건강앱 합계",
                            sourceBundleIdentifier: "apple-health-aggregate"
                        )
                    )
                }

                continuation.resume(returning: samples.sortedByMeasuredAtAscending())
            }

            healthStore.execute(query)
        }
    }

    static func supportedQuantityTypes() -> [HealthMetricType: HKQuantityType] {
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

    static func quantityIdentifier(for metricType: HealthMetricType) -> HKQuantityTypeIdentifier? {
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
        case .stepCount:
            .stepCount
        case .activeEnergy:
            .activeEnergyBurned
        case .heartRate:
            .heartRate
        case .restingHeartRate:
            .restingHeartRate
        case .respiratoryRate:
            .respiratoryRate
        case .sleepDuration:
            nil
        }
    }

    static func unit(for metricType: HealthMetricType) -> HKUnit? {
        switch metricType {
        case .systolicBloodPressure, .diastolicBloodPressure:
            .millimeterOfMercury()
        case .bodyMass, .leanBodyMass:
            .gramUnit(with: .kilo)
        case .bodyFatPercentage:
            .percent()
        case .bodyMassIndex, .stepCount:
            .count()
        case .activeEnergy:
            .kilocalorie()
        case .heartRate, .restingHeartRate, .respiratoryRate:
            .count().unitDivided(by: .minute())
        case .sleepDuration:
            nil
        }
    }
}
#endif
