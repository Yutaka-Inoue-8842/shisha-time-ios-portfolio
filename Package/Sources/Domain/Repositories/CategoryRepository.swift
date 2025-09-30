//
//  CategoryRepository.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/03/20.
//

import AWSAPIPlugin
import Amplify
import Foundation

/// CategoryRepositoryのinterface
public protocol CategoryRepository {
  /// データを作成
  func create(_ category: Category) async throws
  /// すべてのデータを取得
  func fetch(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Category>
  /// ページネーションのために追加のデータを取得（nextTokenを使用）
  func fetchMore(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String
  ) async throws -> PaginatedList<Category>
  /// idが一致するデータを取得
  func fetchById(by id: String) async throws -> Category?
  /// データを更新
  func update(_ category: Category) async throws
  /// データを削除
  func delete(_ category: Category) async throws
}

/// CategoryRepositoryの実装クラス
public actor CategoryRepositoryImpl: CategoryRepository {

  init() {}

  public func create(_ category: Category) async throws {
    _ = try await AmplifyAPIClient.shared.mutate(request: .create(category))
  }

  public func fetch(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Category> {
    let document = CategoryQueries.buildCategoryQuery(
      partition: partition,
      limit: limit,
      sortDirection: sortDirection
    )

    let request = GraphQLRequest<PaginatedList<Category>>(
      document: document,
      responseType: PaginatedList<Category>.self,
      decodePath: CategoryQueries.decodePath
    )

    let result = try await AmplifyAPIClient.shared.query(request: request)
    return result
  }

  public func fetchMore(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String
  ) async throws -> PaginatedList<Category> {

    let document = CategoryQueries.buildCategoryQuery(
      partition: partition,
      limit: limit,
      sortDirection: sortDirection,
      nextToken: nextToken
    )

    let request = GraphQLRequest<PaginatedList<Category>>(
      document: document,
      responseType: PaginatedList<Category>.self,
      decodePath: CategoryQueries.decodePath
    )

    let result = try await AmplifyAPIClient.shared.query(request: request)
    return result
  }

  public func fetchById(by id: String) async throws -> Category? {
    return try await AmplifyAPIClient.shared.query(request: .get(Category.self, byId: id))
  }

  public func update(_ category: Category) async throws {
    _ = try await AmplifyAPIClient.shared.mutate(request: .update(category))
  }

  public func delete(_ category: Category) async throws {
    _ = try await AmplifyAPIClient.shared.mutate(request: .delete(category))
  }
}
