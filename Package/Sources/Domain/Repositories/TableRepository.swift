//
//  TableRepository.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/03/20.
//

import AWSAPIPlugin
import Amplify
import Foundation

/// TableRepositoryのinterface
public protocol TableRepository {
  /// データを作成
  func create(_ table: Table) async throws
  /// すべてのデータを取得
  func fetchAll(partition: Partition, limit: Int, sortDirection: SortDirection) async throws -> PaginatedList<Table>
  /// idが一致するデータを取得
  func fetchById(by id: String) async throws -> Table?
  /// データを更新
  func update(_ table: Table) async throws
  /// データを削除
  func delete(_ table: Table) async throws
}

/// TableRepositoryの実装クラス
public actor TableRepositoryImpl: TableRepository {

  init() {}

  public func create(_ table: Table) async throws {
    _ = try await AmplifyAPIClient.shared.mutate(request: .create(table))
  }

  public func fetchAll(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Table> {
    let document = TableQueries.buildTableQuery(
      partition: partition,
      limit: limit,
      sortDirection: sortDirection
    )

    let request = GraphQLRequest<PaginatedList<Table>>(
      document: document,
      responseType: PaginatedList<Table>.self,
      decodePath: TableQueries.decodePath
    )

    let result = try await AmplifyAPIClient.shared.query(request: request)
    return result
  }

  public func fetchById(by id: String) async throws -> Table? {
    return try await AmplifyAPIClient.shared.query(request: .get(Table.self, byId: id))
  }

  public func update(_ table: Table) async throws {
    _ = try await AmplifyAPIClient.shared.mutate(request: .update(table))
  }

  public func delete(_ table: Table) async throws {
    _ = try await AmplifyAPIClient.shared.mutate(request: .delete(table))
  }
}

// MARK: - Demo Implementation

/// デモ環境用のTableRepository実装（オンメモリ）
public actor TableRepositoryDemoImpl: TableRepository {

  private var tables: [Table] = []

  public init() {
    self.tables = SampleDataProvider.sampleTables()
  }

  public func create(_ table: Table) async throws {
    tables.append(table)
  }

  public func fetchAll(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Table> {
    let sorted = sortTables(tables, direction: sortDirection)
    let items = Array(sorted.prefix(limit))
    let nextToken = items.count < sorted.count ? "has_more" : nil
    return PaginatedList(items: items, nextToken: nextToken)
  }

  public func fetchById(by id: String) async throws -> Table? {
    return tables.first { $0.id == id }
  }

  public func update(_ table: Table) async throws {
    if let index = tables.firstIndex(where: { $0.id == table.id }) {
      tables[index] = table
    }
  }

  public func delete(_ table: Table) async throws {
    tables.removeAll { $0.id == table.id }
  }

  // MARK: - Helper Methods

  private func sortTables(_ items: [Table], direction: SortDirection) -> [Table] {
    switch direction {
    case .asc:
      return items.sorted { $0.updatedAt.foundationDate < $1.updatedAt.foundationDate }
    case .desc:
      return items.sorted { $0.updatedAt.foundationDate > $1.updatedAt.foundationDate }
    }
  }
}
