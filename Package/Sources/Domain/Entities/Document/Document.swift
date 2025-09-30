import Amplify
import Foundation

public struct Document: Model, @unchecked Sendable {
  public let id: String
  public var content: String
  public var text: String
  // swiftlint:disable:next identifier_name
  internal var _category: LazyReference<Category>
  public var category: Category? {
    get async throws {
      try await _category.get()
    }
  }
  public var createdAt: Temporal.DateTime
  public var updatedAt: Temporal.DateTime
  public var globalPartition: String

  public init(
    id: String = UUID().uuidString,
    content: String,
    text: String,
    category: Category? = nil,
    createdAt: Temporal.DateTime,
    updatedAt: Temporal.DateTime,
    globalPartition: String = Partition.global.rawValue
  ) {
    self.id = id
    self.content = content
    self.text = text
    self._category = LazyReference(category)
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.globalPartition = globalPartition
  }

  public mutating func setCategory(_ category: Category? = nil) {
    self._category = LazyReference(category)
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(String.self, forKey: .id)
    content = try values.decode(String.self, forKey: .content)
    text = try values.decode(String.self, forKey: .text)
    // swiftlint:disable:next line_length
    _category = try values.decodeIfPresent(LazyReference<Category>.self, forKey: .category) ?? LazyReference(identifiers: nil)
    createdAt = try values.decode(Temporal.DateTime.self, forKey: .createdAt)
    updatedAt = try values.decode(Temporal.DateTime.self, forKey: .updatedAt)
    globalPartition = try values.decode(String.self, forKey: .globalPartition)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(content, forKey: .content)
    try container.encode(text, forKey: .text)
    try container.encode(_category, forKey: .category)
    try container.encode(createdAt, forKey: .createdAt)
    try container.encode(updatedAt, forKey: .updatedAt)
    try container.encode(globalPartition, forKey: .globalPartition)
  }
}

extension Document: Identifiable {}

extension Document: Equatable {

  public static func == (lhs: Document, rhs: Document) -> Bool {
    return lhs.id == rhs.id && lhs.content == rhs.content && lhs.text == rhs.text && lhs.createdAt == rhs.createdAt && lhs.updatedAt == rhs.updatedAt
  }
}
