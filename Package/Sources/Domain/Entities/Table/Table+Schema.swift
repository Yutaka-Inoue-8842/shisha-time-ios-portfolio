@preconcurrency import Amplify
import Foundation

extension Table {
  // MARK: - CodingKeys
  public enum CodingKeys: String, ModelKey {
    case id
    case name
    case timers
    case createdAt
    case updatedAt
    case globalPartition
  }

  public static let keys = CodingKeys.self

  public static let schema: ModelSchema = {
    defineSchema { model in
      let table = Table.keys

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

      model.listPluralName = "Tables"
      model.syncPluralName = "Tables"

      model.attributes(
        .index(
          fields: ["globalPartition", "updatedAt"],
          name: "tablesByGlobalPartitionAndUpdatedAt"
        ),
        .primaryKey(fields: [table.id])
      )

      model.fields(
        .field(
          table.id,
          is: .required,
          ofType: .string
        ),
        .field(
          table.name,
          is: .required,
          ofType: .string
        ),
        .hasMany(
          table.timers,
          is: .optional,
          ofType: Timer.self,
          associatedFields: [
            Timer.keys.table
          ]
        ),
        .field(
          table.createdAt,
          is: .required,
          ofType: .dateTime
        ),
        .field(
          table.updatedAt,
          is: .required,
          ofType: .dateTime
        ),
        .field(
          table.globalPartition,
          is: .required,
          ofType: .string
        )
      )
    }
  }()
  public class Path: ModelPath<Table> {}

  public static var rootPath: PropertyContainerPath? { Path() }
}

extension Table: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}

extension ModelPath where ModelType == Table {
  public var id: FieldPath<String> {
    string("id")
  }
  public var name: FieldPath<String> {
    string("name")
  }
  public var timers: ModelPath<Timer> {
    Timer.Path(name: "timers", isCollection: true, parent: self)
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
