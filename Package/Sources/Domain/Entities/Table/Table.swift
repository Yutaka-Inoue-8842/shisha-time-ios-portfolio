import Amplify
import Foundation

public struct Table: Model, @unchecked Sendable {
  public let id: String
  public var name: String
  public var timers: List<Timer>?
  public var createdAt: Temporal.DateTime
  public var updatedAt: Temporal.DateTime
  public var globalPartition: String

  public init(
    id: String = UUID().uuidString,
    name: String,
    timers: List<Timer>? = [],
    createdAt: Temporal.DateTime,
    updatedAt: Temporal.DateTime,
    globalPartition: String = Partition.global.rawValue
  ) {
    self.id = id
    self.name = name
    self.timers = timers
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.globalPartition = globalPartition
  }
}

extension Table: Identifiable {}

extension Table: Hashable {

  public static func == (lhs: Table, rhs: Table) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name && lhs.createdAt == rhs.createdAt && lhs.updatedAt == rhs.updatedAt
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(name)
    hasher.combine(createdAt.foundationDate)
    hasher.combine(updatedAt.foundationDate)
  }
}
