@preconcurrency import Amplify
import Foundation

extension Template {
  // MARK: - CodingKeys
  public enum CodingKeys: String, ModelKey {
    case id
    case title
    case content
    case createdAt
    case updatedAt
    case globalPartition
  }

  public static let keys = CodingKeys.self

  public static let schema: ModelSchema = {
    defineSchema { model in
      let template = Template.keys

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

      model.listPluralName = "Templates"
      model.syncPluralName = "Templates"

      model.attributes(
        .index(
          fields: [
            "globalPartition",
            "updatedAt"
          ],
          name: "templatesByGlobalPartitionAndUpdatedAt"
        ),
        .primaryKey(
          fields: [
            template.id
          ]
        )
      )

      model.fields(
        .field(
          template.id,
          is: .required,
          ofType: .string
        ),
        .field(
          template.title,
          is: .required,
          ofType: .string
        ),
        .field(
          template.content,
          is: .required,
          ofType: .string
        ),
        .field(
          template.createdAt,
          is: .required,
          ofType: .dateTime
        ),
        .field(
          template.updatedAt,
          is: .required,
          ofType: .dateTime
        ),
        .field(
          template.globalPartition,
          is: .required,
          ofType: .string
        )
      )
    }
  }()

  public class Path: ModelPath<Template> {}

  public static var rootPath: PropertyContainerPath? { Path() }
}

extension Template: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}

extension ModelPath where ModelType == Template {
  public var id: FieldPath<String> {
    string("id")
  }
  public var title: FieldPath<String> {
    string("title")
  }
  public var content: FieldPath<String> {
    string("content")
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
