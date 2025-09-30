//
//  DocumentRepository.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/03/20.
//

import AWSAPIPlugin
import Amplify
import Foundation

/// DocumentRepositoryのinterface
public protocol DocumentRepository {
  /// データを作成
  func create(_ document: Document) async throws
  /// すべてのデータを取得
  func fetch(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Document>
  /// ページネーションのために追加のデータを取得（nextTokenを使用）
  func fetchMore(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String
  ) async throws -> PaginatedList<Document>
  /// idが一致するデータを取得
  func fetchById(by id: String) async throws -> Document?
  /// データを更新
  func update(_ document: Document) async throws
  /// データを削除
  func delete(_ document: Document) async throws
  /// カテゴリでフィルタリングしたドキュメントを取得
  func fetchByCategory(
    categoryId: String,
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Document>
  /// カテゴリでフィルタリングした追加のドキュメントを取得（nextTokenを使用）
  func fetchMoreByCategory(
    categoryId: String,
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String
  ) async throws -> PaginatedList<Document>
  /// 検索クエリでドキュメントを検索
  func searchDocuments(
    query: String,
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Document>
  /// 検索クエリで追加のドキュメントを取得（nextTokenを使用）
  func searchMoreDocuments(
    query: String,
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String
  ) async throws -> PaginatedList<Document>
  /// カテゴリ内で検索クエリでドキュメントを検索
  func searchDocumentsByCategory(
    query: String,
    categoryId: String,
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Document>
  /// カテゴリ内で検索クエリで追加のドキュメントを取得（nextTokenを使用）
  func searchMoreDocumentsByCategory(
    query: String,
    categoryId: String,
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String
  ) async throws -> PaginatedList<Document>
}

/// DocumentRepositoryの実装クラス
public actor DocumentRepositoryImpl: DocumentRepository {

  init() {}

  public func create(_ document: Document) async throws {
    _ = try await AmplifyAPIClient.shared.mutate(request: .create(document))
  }

  public func fetch(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Document> {

    let document = DocumentQueries.buildDocumentQuery(
      partition: partition,
      limit: limit,
      sortDirection: sortDirection
    )

    let request = GraphQLRequest<PaginatedList<Document>>(
      document: document,
      responseType: PaginatedList<Document>.self,
      decodePath: DocumentQueries.decodePath
    )

    let result = try await AmplifyAPIClient.shared.query(request: request)
    return result
  }

  public func fetchById(by id: String) async throws -> Document? {
    return try await AmplifyAPIClient.shared.query(request: .get(Document.self, byId: id))
  }

  public func update(_ document: Document) async throws {
    _ = try await AmplifyAPIClient.shared.mutate(request: .update(document))
  }

  public func fetchMore(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String
  ) async throws -> PaginatedList<Document> {

    let document = DocumentQueries.buildDocumentQuery(
      partition: partition,
      limit: limit,
      sortDirection: sortDirection,
      nextToken: nextToken
    )

    let request = GraphQLRequest<PaginatedList<Document>>(
      document: document,
      responseType: PaginatedList<Document>.self,
      decodePath: DocumentQueries.decodePath
    )

    let result = try await AmplifyAPIClient.shared.query(request: request)
    return result
  }

  public func delete(_ document: Document) async throws {
    _ = try await AmplifyAPIClient.shared.mutate(request: .delete(document))
  }

  public func fetchByCategory(
    categoryId: String,
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Document> {

    let filter = DocumentQueries.categoryFilter(categoryId: categoryId)

    let document = DocumentQueries.buildDocumentQuery(
      partition: partition,
      limit: limit,
      sortDirection: sortDirection,
      filter: filter
    )

    let request = GraphQLRequest<PaginatedList<Document>>(
      document: document,
      responseType: PaginatedList<Document>.self,
      decodePath: DocumentQueries.decodePath
    )

    let result = try await AmplifyAPIClient.shared.query(request: request)
    return result
  }

  public func fetchMoreByCategory(
    categoryId: String,
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String
  ) async throws -> PaginatedList<Document> {

    let filter = DocumentQueries.categoryFilter(categoryId: categoryId)

    let document = DocumentQueries.buildDocumentQuery(
      partition: partition,
      limit: limit,
      sortDirection: sortDirection,
      nextToken: nextToken,
      filter: filter
    )

    let request = GraphQLRequest<PaginatedList<Document>>(
      document: document,
      responseType: PaginatedList<Document>.self,
      decodePath: DocumentQueries.decodePath
    )

    let result = try await AmplifyAPIClient.shared.query(request: request)
    return result
  }

  public func searchDocuments(
    query: String,
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Document> {

    let filter = DocumentQueries.searchFilter(query: query)

    let document = DocumentQueries.buildDocumentQuery(
      partition: partition,
      limit: limit,
      sortDirection: sortDirection,
      filter: filter
    )

    let request = GraphQLRequest<PaginatedList<Document>>(
      document: document,
      responseType: PaginatedList<Document>.self,
      decodePath: DocumentQueries.decodePath
    )

    let result = try await AmplifyAPIClient.shared.query(request: request)
    return result
  }

  public func searchMoreDocuments(
    query: String,
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String
  ) async throws -> PaginatedList<Document> {

    let filter = DocumentQueries.searchFilter(query: query)

    let document = DocumentQueries.buildDocumentQuery(
      partition: partition,
      limit: limit,
      sortDirection: sortDirection,
      nextToken: nextToken,
      filter: filter
    )

    let request = GraphQLRequest<PaginatedList<Document>>(
      document: document,
      responseType: PaginatedList<Document>.self,
      decodePath: DocumentQueries.decodePath
    )

    let result = try await AmplifyAPIClient.shared.query(request: request)
    return result
  }

  public func searchDocumentsByCategory(
    query: String,
    categoryId: String,
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Document> {

    let filter = DocumentQueries.categorySearchFilter(query: query, categoryId: categoryId)

    let document = DocumentQueries.buildDocumentQuery(
      partition: partition,
      limit: limit,
      sortDirection: sortDirection,
      filter: filter
    )

    let request = GraphQLRequest<PaginatedList<Document>>(
      document: document,
      responseType: PaginatedList<Document>.self,
      decodePath: DocumentQueries.decodePath
    )

    let result = try await AmplifyAPIClient.shared.query(request: request)
    return result
  }

  public func searchMoreDocumentsByCategory(
    query: String,
    categoryId: String,
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String
  ) async throws -> PaginatedList<Document> {

    let filter = DocumentQueries.categorySearchFilter(query: query, categoryId: categoryId)

    let document = DocumentQueries.buildDocumentQuery(
      partition: partition,
      limit: limit,
      sortDirection: sortDirection,
      nextToken: nextToken,
      filter: filter
    )

    let request = GraphQLRequest<PaginatedList<Document>>(
      document: document,
      responseType: PaginatedList<Document>.self,
      decodePath: DocumentQueries.decodePath
    )

    let result = try await AmplifyAPIClient.shared.query(request: request)
    return result
  }
}
