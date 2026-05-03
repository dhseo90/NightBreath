import Foundation

public enum DatasetManifestLabel: String, Codable, CaseIterable, Identifiable, Sendable {
  case snore
  case bruxismLike
  case breathingPauseSuspected
  case gaspLike
  case coughLike
  case sleepTalkLike
  case movementLike
  case environmentalNoise
  case awakeningSuspected
  case unknown
  case silence

  public var id: String { rawValue }
}

public enum DatasetRecordingType: String, Codable, CaseIterable, Identifiable, Sendable {
  case publicDataset
  case personalDebugSample
  case synthetic

  public var id: String { rawValue }
}

public enum DatasetMicrophoneType: String, Codable, CaseIterable, Identifiable, Sendable {
  case unknown
  case ambient
  case tracheal
  case iPhone
  case other

  public var id: String { rawValue }
}

public struct PublicDatasetManifest: Codable, Equatable, Identifiable, Sendable {
  public var datasetName: String
  public var datasetLicenseNote: String?
  public var segments: [PublicDatasetManifestSegment]

  public var id: String { datasetName }

  public init(
    datasetName: String,
    datasetLicenseNote: String? = nil,
    segments: [PublicDatasetManifestSegment]
  ) {
    self.datasetName = datasetName
    self.datasetLicenseNote = datasetLicenseNote
    self.segments = segments
  }
}

public struct PublicDatasetManifestSegment: Codable, Equatable, Identifiable, Sendable {
  public var fileId: String
  public var localFilePath: String
  public var subjectId: String?
  public var recordingType: DatasetRecordingType
  public var microphoneType: DatasetMicrophoneType
  public var segmentStartSeconds: TimeInterval
  public var segmentDurationSeconds: TimeInterval
  public var expectedLabels: [DatasetManifestLabel]
  public var negativeLabels: [DatasetManifestLabel]
  public var confidenceNote: String?
  public var notes: String?

  public var id: String { fileId }

  public init(
    fileId: String,
    localFilePath: String,
    subjectId: String? = nil,
    recordingType: DatasetRecordingType,
    microphoneType: DatasetMicrophoneType = .unknown,
    segmentStartSeconds: TimeInterval,
    segmentDurationSeconds: TimeInterval,
    expectedLabels: [DatasetManifestLabel],
    negativeLabels: [DatasetManifestLabel] = [],
    confidenceNote: String? = nil,
    notes: String? = nil
  ) {
    self.fileId = fileId
    self.localFilePath = localFilePath
    self.subjectId = subjectId
    self.recordingType = recordingType
    self.microphoneType = microphoneType
    self.segmentStartSeconds = max(0, segmentStartSeconds)
    self.segmentDurationSeconds = max(0, segmentDurationSeconds)
    self.expectedLabels = expectedLabels
    self.negativeLabels = negativeLabels
    self.confidenceNote = confidenceNote
    self.notes = notes
  }
}
