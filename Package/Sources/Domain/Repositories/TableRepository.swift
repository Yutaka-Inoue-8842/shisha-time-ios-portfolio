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
