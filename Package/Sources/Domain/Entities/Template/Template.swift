import Amplify
import Foundation

public struct Template: Model, @unchecked Sendable {
  public let id: String
  public var title: String
  public var content: String
  public var createdAt: Temporal.DateTime
  public var updatedAt: Temporal.DateTime
  public var globalPartition: String

  public init(
    id: String = UUID().uuidString,
    title: String,
    content: String,
    createdAt: Temporal.DateTime,
    updatedAt: Temporal.DateTime,
    globalPartition: String = Partition.global.rawValue
  ) {
    self.id = id
    self.title = title
    self.content = content
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.globalPartition = globalPartition
  }
}

extension Template: Identifiable {}

extension Template: Equatable {}
