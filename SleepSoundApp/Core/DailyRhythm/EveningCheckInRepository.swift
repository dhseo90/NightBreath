import Foundation

public protocol EveningCheckInRepositoryProtocol: AnyObject {
    func save(_ checkIn: EveningCheckIn)
    func all() -> [EveningCheckIn]
    func latest(on date: Date, calendar: Calendar) -> EveningCheckIn?
}

public extension EveningCheckInRepositoryProtocol {
    func latest(on date: Date, calendar: Calendar = .current) -> EveningCheckIn? {
        all()
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                return lhs.updatedAt > rhs.updatedAt
            }
            .first
    }
}

public final class InMemoryEveningCheckInRepository: EveningCheckInRepositoryProtocol {
    private var checkIns: [EveningCheckIn]

    public init(checkIns: [EveningCheckIn] = []) {
        self.checkIns = checkIns
    }

    public func save(_ checkIn: EveningCheckIn) {
        checkIns.removeAll { $0.id == checkIn.id }
        checkIns.append(checkIn)
    }

    public func all() -> [EveningCheckIn] {
        checkIns.sorted(by: Self.sortDescending)
    }

    private static func sortDescending(_ lhs: EveningCheckIn, _ rhs: EveningCheckIn) -> Bool {
        if lhs.date == rhs.date {
            return lhs.updatedAt > rhs.updatedAt
        }
        return lhs.date > rhs.date
    }
}

public final class JSONEveningCheckInRepository: EveningCheckInRepositoryProtocol {
    public let fileURL: URL

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let lock = NSLock()

    public init(
        fileURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultStoreURL(fileManager: fileManager)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder
        self.decoder = JSONDecoder()

        try? fileManager.createDirectory(
            at: self.fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    public func save(_ checkIn: EveningCheckIn) {
        updateArchive { archive in
            archive.checkIns.removeAll { $0.id == checkIn.id }
            archive.checkIns.append(checkIn)
        }
    }

    public func all() -> [EveningCheckIn] {
        readArchive().checkIns.sorted { lhs, rhs in
            if lhs.date == rhs.date {
                return lhs.updatedAt > rhs.updatedAt
            }
            return lhs.date > rhs.date
        }
    }

    private static func defaultStoreURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent("NightBreath", isDirectory: true)
            .appendingPathComponent("evening-check-ins.json")
    }

    private func readArchive() -> EveningCheckInArchive {
        lock.lock()
        defer { lock.unlock() }

        return loadArchiveWithoutLock()
    }

    private func updateArchive(_ update: (inout EveningCheckInArchive) -> Void) {
        lock.lock()
        defer { lock.unlock() }

        var archive = loadArchiveWithoutLock()
        update(&archive)
        persistArchiveWithoutLock(archive)
    }

    private func loadArchiveWithoutLock() -> EveningCheckInArchive {
        guard let data = try? Data(contentsOf: fileURL), !data.isEmpty else {
            return EveningCheckInArchive()
        }

        return (try? decoder.decode(EveningCheckInArchive.self, from: data)) ?? EveningCheckInArchive()
    }

    private func persistArchiveWithoutLock(_ archive: EveningCheckInArchive) {
        guard let data = try? encoder.encode(archive) else { return }

        try? fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: fileURL, options: [.atomic])
    }
}

public struct EveningCheckInArchive: Codable, Equatable {
    public var schemaVersion: Int
    public var checkIns: [EveningCheckIn]

    public init(
        schemaVersion: Int = 1,
        checkIns: [EveningCheckIn] = []
    ) {
        self.schemaVersion = schemaVersion
        self.checkIns = checkIns
    }
}
