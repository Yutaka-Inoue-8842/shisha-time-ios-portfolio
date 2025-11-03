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
public protocol CategoryRepository: Sendable {
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

// MARK: - Demo Implementation

/// デモ環境用のCategoryRepository実装（オンメモリ）
public actor CategoryRepositoryDemoImpl: CategoryRepository {

  private var categories: [Category] = []

  public init() {
    self.categories = SampleDataProvider.sampleCategories()
  }

  public func create(_ category: Category) async throws {
    categories.append(category)
  }

  public func fetch(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Category> {
    let sorted = sortCategories(categories, direction: sortDirection)
    let items = Array(sorted.prefix(limit))
    let nextToken = items.count < sorted.count ? "has_more" : nil
    return PaginatedList(items: items, nextToken: nextToken)
  }

  public func fetchMore(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String
  ) async throws -> PaginatedList<Category> {
    // オンメモリでは簡易的な実装
    let sorted = sortCategories(categories, direction: sortDirection)
    let offset = min(limit, sorted.count)
    let items = Array(sorted.dropFirst(offset).prefix(limit))
    let newNextToken = (offset + items.count) < sorted.count ? "has_more" : nil
    return PaginatedList(items: items, nextToken: newNextToken)
  }

  public func fetchById(by id: String) async throws -> Category? {
    return categories.first { $0.id == id }
  }

  public func update(_ category: Category) async throws {
    if let index = categories.firstIndex(where: { $0.id == category.id }) {
      categories[index] = category
    }
  }

  public func delete(_ category: Category) async throws {
    categories.removeAll { $0.id == category.id }
  }

  // MARK: - Helper Methods

  private func sortCategories(_ items: [Category], direction: SortDirection) -> [Category] {
    switch direction {
    case .asc:
      return items.sorted { $0.updatedAt.foundationDate < $1.updatedAt.foundationDate }
    case .desc:
      return items.sorted { $0.updatedAt.foundationDate > $1.updatedAt.foundationDate }
    }
  }
}
