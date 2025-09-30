import Amplify
import Foundation

public struct Category: Model, @unchecked Sendable {
  public let id: String
  public var name: String
  public var documents: List<Document>?
  public var createdAt: Temporal.DateTime
  public var updatedAt: Temporal.DateTime
  public var globalPartition: String

  public init(
    id: String = UUID().uuidString,
    name: String,
    documents: List<Document>? = [],
    createdAt: Temporal.DateTime,
    updatedAt: Temporal.DateTime,
    globalPartition: String = Partition.global.rawValue
  ) {
    self.id = id
    self.name = name
    self.documents = documents
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.globalPartition = globalPartition
  }
}

extension Category: Identifiable {}

extension Category: Hashable {

  public static func == (lhs: Category, rhs: Category) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name && lhs.createdAt == rhs.createdAt && lhs.updatedAt == rhs.updatedAt
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(name)
    hasher.combine(createdAt.foundationDate)
    hasher.combine(updatedAt.foundationDate)
  }
}
