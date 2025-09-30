import Amplify
import Foundation

public struct Timer: Model, @unchecked Sendable {
  public let id: String
  public var nextCheckTime: Temporal.DateTime
  public var minutesInterval: Int
  // swiftlint:disable:next identifier_name
  internal var _table: LazyReference<Table>
  public var table: Table? {
    get async throws {
      try await _table.get()
    }
  }
  public var createdAt: Temporal.DateTime
  public var updatedAt: Temporal.DateTime
  public var globalPartition: String

  public init(
    id: String = UUID().uuidString,
    nextCheckTime: Temporal.DateTime,
    minutesInterval: Int,
    table: Table? = nil,
    createdAt: Temporal.DateTime,
    updatedAt: Temporal.DateTime,
    globalPartition: String = Partition.global.rawValue
  ) {
    self.id = id
    self.nextCheckTime = nextCheckTime
    self.minutesInterval = minutesInterval
    self._table = LazyReference(table)
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.globalPartition = globalPartition
  }

  public mutating func setTable(_ table: Table? = nil) {
    self._table = LazyReference(table)
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(String.self, forKey: .id)
    nextCheckTime = try values.decode(Temporal.DateTime.self, forKey: .nextCheckTime)
    minutesInterval = try values.decode(Int.self, forKey: .minutesInterval)
    _table = try values.decodeIfPresent(LazyReference<Table>.self, forKey: .table) ?? LazyReference(identifiers: nil)
    createdAt = try values.decode(Temporal.DateTime.self, forKey: .createdAt)
    updatedAt = try values.decode(Temporal.DateTime.self, forKey: .updatedAt)
    globalPartition = try values.decode(String.self, forKey: .globalPartition)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(nextCheckTime, forKey: .nextCheckTime)
    try container.encode(minutesInterval, forKey: .minutesInterval)
    try container.encode(_table, forKey: .table)
    try container.encode(createdAt, forKey: .createdAt)
    try container.encode(updatedAt, forKey: .updatedAt)
    try container.encode(globalPartition, forKey: .globalPartition)
  }
}

extension Timer: Identifiable {}

extension Timer: Equatable {
  public static func == (lhs: Timer, rhs: Timer) -> Bool {
    return lhs.id == rhs.id && lhs.nextCheckTime == rhs.nextCheckTime && lhs.minutesInterval == rhs.minutesInterval && lhs.createdAt == rhs.createdAt && lhs.updatedAt == rhs.updatedAt
  }
}
