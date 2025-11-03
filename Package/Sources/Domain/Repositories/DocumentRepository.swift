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

// MARK: - Demo Implementation

/// デモ環境用のDocumentRepository実装（オンメモリ）
public actor DocumentRepositoryDemoImpl: DocumentRepository {

  private var documents: [Document] = []

  public init() {
    // カテゴリ関連のサンプルデータが必要な場合は、
    // 先にCategoryRepositoryを初期化してからDocumentを生成する必要がある
    let categories = SampleDataProvider.sampleCategories()
    self.documents = SampleDataProvider.sampleDocuments(categories: categories)
  }

  public func create(_ document: Document) async throws {
    documents.append(document)
  }

  public func fetch(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Document> {
    let sorted = sortDocuments(documents, direction: sortDirection)
    let items = Array(sorted.prefix(limit))
    let nextToken = items.count < sorted.count ? "has_more" : nil
    return PaginatedList(items: items, nextToken: nextToken)
  }

  public func fetchMore(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String
  ) async throws -> PaginatedList<Document> {
    let sorted = sortDocuments(documents, direction: sortDirection)
    let offset = min(limit, sorted.count)
    let items = Array(sorted.dropFirst(offset).prefix(limit))
    let newNextToken = (offset + items.count) < sorted.count ? "has_more" : nil
    return PaginatedList(items: items, nextToken: newNextToken)
  }

  public func fetchById(by id: String) async throws -> Document? {
    return documents.first { $0.id == id }
  }

  public func update(_ document: Document) async throws {
    if let index = documents.firstIndex(where: { $0.id == document.id }) {
      documents[index] = document
    }
  }

  public func delete(_ document: Document) async throws {
    documents.removeAll { $0.id == document.id }
  }

  public func fetchByCategory(
    categoryId: String,
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Document> {
    let filtered = try await filterByCategory(documents, categoryId: categoryId)
    let sorted = sortDocuments(filtered, direction: sortDirection)
    let items = Array(sorted.prefix(limit))
    let nextToken = items.count < sorted.count ? "has_more" : nil
    return PaginatedList(items: items, nextToken: nextToken)
  }

  public func fetchMoreByCategory(
    categoryId: String,
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String
  ) async throws -> PaginatedList<Document> {
    let filtered = try await filterByCategory(documents, categoryId: categoryId)
    let sorted = sortDocuments(filtered, direction: sortDirection)
    let offset = min(limit, sorted.count)
    let items = Array(sorted.dropFirst(offset).prefix(limit))
    let newNextToken = (offset + items.count) < sorted.count ? "has_more" : nil
    return PaginatedList(items: items, nextToken: newNextToken)
  }

  public func searchDocuments(
    query: String,
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Document> {
    let filtered = documents.filter { document in
      document.text.localizedCaseInsensitiveContains(query)
    }
    let sorted = sortDocuments(filtered, direction: sortDirection)
    let items = Array(sorted.prefix(limit))
    let nextToken = items.count < sorted.count ? "has_more" : nil
    return PaginatedList(items: items, nextToken: nextToken)
  }

  public func searchMoreDocuments(
    query: String,
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String
  ) async throws -> PaginatedList<Document> {
    let filtered = documents.filter { document in
      document.text.localizedCaseInsensitiveContains(query)
    }
    let sorted = sortDocuments(filtered, direction: sortDirection)
    let offset = min(limit, sorted.count)
    let items = Array(sorted.dropFirst(offset).prefix(limit))
    let newNextToken = (offset + items.count) < sorted.count ? "has_more" : nil
    return PaginatedList(items: items, nextToken: newNextToken)
  }

  public func searchDocumentsByCategory(
    query: String,
    categoryId: String,
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Document> {
    let categoryFiltered = try await filterByCategory(documents, categoryId: categoryId)
    let filtered = categoryFiltered.filter { document in
      document.text.localizedCaseInsensitiveContains(query)
    }
    let sorted = sortDocuments(filtered, direction: sortDirection)
    let items = Array(sorted.prefix(limit))
    let nextToken = items.count < sorted.count ? "has_more" : nil
    return PaginatedList(items: items, nextToken: nextToken)
  }

  public func searchMoreDocumentsByCategory(
    query: String,
    categoryId: String,
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String
  ) async throws -> PaginatedList<Document> {
    let categoryFiltered = try await filterByCategory(documents, categoryId: categoryId)
    let filtered = categoryFiltered.filter { document in
      document.text.localizedCaseInsensitiveContains(query)
    }
    let sorted = sortDocuments(filtered, direction: sortDirection)
    let offset = min(limit, sorted.count)
    let items = Array(sorted.dropFirst(offset).prefix(limit))
    let newNextToken = (offset + items.count) < sorted.count ? "has_more" : nil
    return PaginatedList(items: items, nextToken: newNextToken)
  }

  // MARK: - Helper Methods

  private func sortDocuments(_ items: [Document], direction: SortDirection) -> [Document] {
    switch direction {
    case .asc:
      return items.sorted { $0.updatedAt.foundationDate < $1.updatedAt.foundationDate }
    case .desc:
      return items.sorted { $0.updatedAt.foundationDate > $1.updatedAt.foundationDate }
    }
  }

  private func filterByCategory(_ items: [Document], categoryId: String) async throws -> [Document] {
    var filtered: [Document] = []
    for document in items {
      if let category = try await document.category, category.id == categoryId {
        filtered.append(document)
      }
    }
    return filtered
  }
}
