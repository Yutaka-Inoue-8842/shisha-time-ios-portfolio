@preconcurrency import Amplify
import Foundation

extension Timer {
  // MARK: - CodingKeys
  public enum CodingKeys: String, ModelKey {
    case id
    case nextCheckTime
    case minutesInterval
    case table
    case createdAt
    case updatedAt
    case globalPartition
  }

  public static let keys = CodingKeys.self

  public static let schema: ModelSchema = {
    defineSchema { model in
      let timer = Timer.keys

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

      model.listPluralName = "Timers"
      model.syncPluralName = "Timers"

      model.attributes(
        .index(
          fields: ["globalPartition", "nextCheckTime"],
          name: "timersByGlobalPartitionAndNextCheckTime"
        ),
        .primaryKey(fields: [timer.id])
      )

      model.fields(
        .field(
          timer.id,
          is: .required,
          ofType: .string
        ),
        .field(
          timer.nextCheckTime,
          is: .required,
          ofType: .dateTime
        ),
        .field(
          timer.minutesInterval,
          is: .required,
          ofType: .int
        ),
        .belongsTo(
          timer.table,
          is: .optional,
          ofType: Table.self,
          targetNames: ["tableId"]
        ),
        .field(
          timer.createdAt,
          is: .required,
          ofType: .dateTime
        ),
        .field(
          timer.updatedAt,
          is: .required,
          ofType: .dateTime
        ),
        .field(
          timer.globalPartition,
          is: .required,
          ofType: .string
        )
      )
    }
  }()
  public class Path: ModelPath<Timer> {}

  public static var rootPath: PropertyContainerPath? { Path() }
}

extension Timer: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}

extension ModelPath where ModelType == Timer {
  public var id: FieldPath<String> {
    string("id")
  }
  public var nextCheckTime: FieldPath<Temporal.DateTime> {
    datetime("nextCheckTime")
  }
  public var minutesInterval: FieldPath<Int> {
    int("minutesInterval")
  }
  public var table: ModelPath<Table> {
    Table.Path(name: "table", parent: self)
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
