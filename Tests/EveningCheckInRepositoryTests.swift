import Foundation
import Testing
@testable import SleepSoundCore

@Suite("EveningCheckInRepository")
struct EveningCheckInRepositoryTests {
    @Test
    func jsonRepositoryPersistsEveningCheckIns() throws {
        let fileURL = makeTemporaryStoreURL()
        let repository = JSONEveningCheckInRepository(fileURL: fileURL)
        let checkIn = makeCheckIn(dayOffset: 0, updatedOffset: 0)

        repository.save(checkIn)

        let reloadedRepository = JSONEveningCheckInRepository(fileURL: fileURL)

        #expect(reloadedRepository.all() == [checkIn])
        #expect(reloadedRepository.latest(on: checkIn.date, calendar: .current) == checkIn)

        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }

    @Test
    func savingSameIDUpdatesExistingRecord() throws {
        let fileURL = makeTemporaryStoreURL()
        let repository = JSONEveningCheckInRepository(fileURL: fileURL)
        let original = makeCheckIn(dayOffset: 0, updatedOffset: -60, fatigueScore: 2)
        let updated = EveningCheckIn(
            id: original.id,
            date: original.date,
            fatigueScore: 5,
            stressScore: 4,
            moodScore: 2,
            caffeine: true,
            alcohol: false,
            lateMeal: true,
            exercise: false,
            nap: false,
            memo: "저녁 체크인 업데이트",
            createdAt: original.createdAt,
            updatedAt: original.updatedAt.addingTimeInterval(60)
        )

        repository.save(original)
        repository.save(updated)

        #expect(repository.all() == [updated])
        #expect(repository.latest(on: original.date, calendar: .current) == updated)

        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }

    @Test
    func latestForDayUsesUpdatedAtWithoutMergingDifferentDays() {
        let calendar = Calendar(identifier: .gregorian)
        let target = makeCheckIn(dayOffset: 0, updatedOffset: -60, fatigueScore: 2)
        let newerSameDay = makeCheckIn(dayOffset: 0, updatedOffset: 0, fatigueScore: 4)
        let otherDay = makeCheckIn(dayOffset: -1, updatedOffset: 120, fatigueScore: 5)
        let repository = InMemoryEveningCheckInRepository(checkIns: [target, newerSameDay, otherDay])

        #expect(repository.latest(on: target.date, calendar: calendar) == newerSameDay)
        #expect(repository.latest(on: otherDay.date, calendar: calendar) == otherDay)
        #expect(repository.all().count == 3)
    }

    private func makeTemporaryStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("NightBreathEveningCheckInTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("evening-check-ins.json")
    }

    private func makeCheckIn(
        dayOffset: Int,
        updatedOffset: TimeInterval,
        fatigueScore: Int = 3
    ) -> EveningCheckIn {
        let baseDate = Date(timeIntervalSince1970: 1_800_000_000)
        let date = Calendar(identifier: .gregorian).date(byAdding: .day, value: dayOffset, to: baseDate) ?? baseDate
        let createdAt = date.addingTimeInterval(20 * 60 * 60)
        return EveningCheckIn(
            date: createdAt,
            fatigueScore: fatigueScore,
            stressScore: 3,
            moodScore: nil,
            caffeine: false,
            alcohol: false,
            lateMeal: false,
            exercise: false,
            nap: false,
            memo: "",
            createdAt: createdAt,
            updatedAt: createdAt.addingTimeInterval(updatedOffset)
        )
    }
}
