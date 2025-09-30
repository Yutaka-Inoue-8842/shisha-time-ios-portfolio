@preconcurrency import Amplify
import Foundation

extension Category {
  // MARK: - CodingKeys
  public enum CodingKeys: String, ModelKey {
    case id
    case name
    case documents
    case createdAt
    case updatedAt
    case globalPartition
  }

  public static let keys = CodingKeys.self

  public static let schema = defineSchema { model in
    let category = Category.keys

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

    model.listPluralName = "Categories"
    model.syncPluralName = "Categories"

    model.attributes(
      .index(
        fields: ["globalPartition", "updatedAt"],
        name: "categoriesByGlobalPartitionAndUpdatedAt"
      ),
      .primaryKey(fields: [category.id])
    )

    model.fields(
      .field(
        category.id,
        is: .required,
        ofType: .string
      ),
      .field(
        category.name,
        is: .required,
        ofType: .string
      ),
      .hasMany(
        category.documents,
        is: .optional,
        ofType: Document.self,
        associatedFields: [
          Document.keys.category
        ]
      ),
      .field(
        category.createdAt,
        is: .required,
        ofType: .dateTime
      ),
      .field(
        category.updatedAt,
        is: .required,
        ofType: .dateTime
      ),
      .field(
        category.globalPartition,
        is: .required,
        ofType: .string
      )
    )
  }

  public class Path: ModelPath<Category> {}

  public static var rootPath: PropertyContainerPath? { Path() }
}

extension Category: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}

extension ModelPath where ModelType == Category {
  public var id: FieldPath<String> {
    string("id")
  }
  public var name: FieldPath<String> {
    string("name")
  }
  public var documents: ModelPath<Document> {
    Document.Path(
      name: "documents",
      isCollection: true,
      parent: self
    )
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
