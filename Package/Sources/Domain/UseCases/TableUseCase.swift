//
//  TableUseCase.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/02/22.
//

import ComposableArchitecture
import Foundation

/// TableUseCase
@DependencyClient
public struct TableUseCase: Sendable {
  /// データを作成
  public var create: @Sendable (_ name: String) async throws -> Table
  /// すべてのデータを取得
  public var fetchAll: @Sendable () async throws -> [Table]
  /// データを更新
  public var update: @Sendable (_ table: Table, _ newName: String) async throws -> Table
  /// データを削除
  public var delete: @Sendable (_ table: Table) async throws -> Void
}

extension TableUseCase {
  /// バリデーション
  public static func validate(name: String) throws {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedName.isEmpty else {
      throw TableValidationError.invalidNameEmpty
    }

    guard trimmedName.count <= 20 else {
      throw TableValidationError.invalidNameLength
    }
  }
}

extension TableUseCase: DependencyKey {
  /// TableUseCaseのDependencyKey
  public static let liveValue: TableUseCase = {
    let repository = TableRepositoryImpl()
    return Self(
      create: { name in
        try TableUseCase.validate(name: name)
        let table = Table(
          name: name,
          createdAt: .init(Date()),
          updatedAt: .init(Date())
        )
        try await repository.create(table)
        return table
      },
      fetchAll: {
        let list = try await repository.fetchAll(
          partition: .global,
          limit: 60,
          sortDirection: .desc
        )
        return list.items
      },
      update: { table, newName in
        try TableUseCase.validate(name: newName)
        var targetTable = table
        targetTable.name = newName
        targetTable.updatedAt = .init(Date())
        try await repository.update(targetTable)
        return targetTable
      },
      delete: { table in
        try await repository.delete(table)
      }
    )
  }()
}

extension TableUseCase: TestDependencyKey {
  public static let testValue: TableUseCase = Self()
  public static let previewValue: TableUseCase = Self()
}

extension DependencyValues {
  /// TableUseCaseのDependencyValues
  public var tableUseCase: TableUseCase {
    get { self[TableUseCase.self] }
    set { self[TableUseCase.self] = newValue }
  }
}
