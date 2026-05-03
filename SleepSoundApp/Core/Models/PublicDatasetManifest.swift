import Foundation

public struct PublicDatasetManifest: Codable, Equatable, Identifiable, Sendable {
  public var id: UUID
  public var datasetName: String
  public var localFilePath: String
  public var subjectId: String?
  public var segmentStartSeconds: TimeInterval
  public var segmentDurationSeconds: TimeInterval
  public var expectedLabels: [SleepEventType]
  public var notes: String?
  public var licenseNote: String

  public init(
    id: UUID = UUID(),
    datasetName: String,
    localFilePath: String,
    subjectId: String? = nil,
    segmentStartSeconds: TimeInterval = 0,
    segmentDurationSeconds: TimeInterval,
    expectedLabels: [SleepEventType] = [],
    notes: String? = nil,
    licenseNote: String
  ) {
    self.id = id
    self.datasetName = datasetName
    self.localFilePath = localFilePath
    self.subjectId = subjectId
    self.segmentStartSeconds = max(0, segmentStartSeconds)
    self.segmentDurationSeconds = max(0, segmentDurationSeconds)
    self.expectedLabels = expectedLabels
    self.notes = notes
    self.licenseNote = licenseNote
  }
}
