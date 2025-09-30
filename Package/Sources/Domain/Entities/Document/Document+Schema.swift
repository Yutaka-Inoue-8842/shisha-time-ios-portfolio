@preconcurrency import Amplify
import Foundation

extension Document {
  // MARK: - CodingKeys
  public enum CodingKeys: String, ModelKey {
    case id
    case content
    case text
    case category
    case createdAt
    case updatedAt
    case globalPartition
  }

  public static let keys = CodingKeys.self

  public static let schema = defineSchema { model in
    let document = Document.keys

    model.authRules = [
      rule(
        allow: .public,
        provider: .apiKey,
        operations: [
          .create,
          .update,
          .delete,
          .read
        ]
      )
    ]

    model.listPluralName = "Documents"
    model.syncPluralName = "Documents"

    model.attributes(
      .index(
        fields: ["globalPartition", "updatedAt"],
        name: "documentsByGlobalPartitionAndUpdatedAt"
      ),
      .primaryKey(fields: [document.id]
      )
    )

    model.fields(
      .field(
        document.id,
        is: .required,
        ofType: .string
      ),
      .field(
        document.content,
        is: .required,
        ofType: .string
      ),
      .field(
        document.text,
        is: .required,
        ofType: .string
      ),
      .belongsTo(
        document.category,
        is: .optional,
        ofType: Category.self,
        targetNames: ["categoryId"]
      ),
      .field(
        document.createdAt,
        is: .required,
        ofType: .dateTime
      ),
      .field(
        document.updatedAt,
        is: .required,
        ofType: .dateTime
      ),
      .field(
        document.globalPartition,
        is: .required,
        ofType: .string
      )
    )
  }

  public class Path: ModelPath<Document> {}

  public static var rootPath: PropertyContainerPath? { Path() }
}

extension Document: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}

extension ModelPath where ModelType == Document {
  public var id: FieldPath<String> {
    string("id")
  }
  public var content: FieldPath<String> {
    string("content")
  }
  public var text: FieldPath<String> {
    string("text")
  }
  public var category: ModelPath<Category> {
    Category.Path(name: "category", parent: self)
  }
  public var createdAt: FieldPath<Temporal.DateTime> {
    datetime("createdAt")
  }
  public var updatedAt: FieldPath<Temporal.DateTime> {
    datetime("updatedAt")
  }
  public var globalPartition: FieldPath<String> {
    string("globalPartition")
  }
}
