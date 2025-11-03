//
//  TableRepository.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/03/20.
//

import AWSAPIPlugin
import Amplify
import Foundation

/// TemplateRepositoryのinterface
public protocol TemplateRepository {
  /// データを作成
  func create(_ template: Template) async throws
  /// すべてのデータを取得
  func fetchAll(partition: Partition, limit: Int, sortDirection: SortDirection) async throws -> PaginatedList<Template>
  /// idが一致するデータを取得
  func fetchById(by id: String) async throws -> Template?
  /// データを更新
  func update(_ template: Template) async throws
  /// データを削除
  func delete(_ template: Template) async throws
}

/// TemplateRepositoryの実装クラス
public actor TemplateRepositoryImpl: TemplateRepository {

  init() {}

  public func create(_ template: Template) async throws {
    _ = try await AmplifyAPIClient.shared.mutate(request: .create(template))
  }

  public func fetchAll(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Template> {

    let document = TemplateQueries.buildTemplateQuery(
      partition: partition,
      limit: limit,
      sortDirection: sortDirection
    )

    let request = GraphQLRequest<PaginatedList<Template>>(
      document: document,
      responseType: PaginatedList<Template>.self,
      decodePath: TemplateQueries.decodePath
    )

    let result = try await AmplifyAPIClient.shared.query(request: request)
    return result
  }

  public func fetchById(by id: String) async throws -> Template? {
    return try await AmplifyAPIClient.shared.query(request: .get(Template.self, byId: id))
  }

  public func update(_ template: Template) async throws {
    _ = try await AmplifyAPIClient.shared.mutate(request: .update(template))
  }

  public func delete(_ template: Template) async throws {
    _ = try await AmplifyAPIClient.shared.mutate(request: .delete(template))
  }
}

// MARK: - Demo Implementation

/// デモ環境用のTemplateRepository実装（オンメモリ）
public actor TemplateRepositoryDemoImpl: TemplateRepository {

  private var templates: [Template] = []

  public init() {
    self.templates = SampleDataProvider.sampleTemplates()
  }

  public func create(_ template: Template) async throws {
    templates.append(template)
  }

  public func fetchAll(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Template> {
    let sorted = sortTemplates(templates, direction: sortDirection)
    let items = Array(sorted.prefix(limit))
    let nextToken = items.count < sorted.count ? "has_more" : nil
    return PaginatedList(items: items, nextToken: nextToken)
  }

  public func fetchById(by id: String) async throws -> Template? {
    return templates.first { $0.id == id }
  }

  public func update(_ template: Template) async throws {
    if let index = templates.firstIndex(where: { $0.id == template.id }) {
      templates[index] = template
    }
  }

  public func delete(_ template: Template) async throws {
    templates.removeAll { $0.id == template.id }
  }

  // MARK: - Helper Methods

  private func sortTemplates(_ items: [Template], direction: SortDirection) -> [Template] {
    switch direction {
    case .asc:
      return items.sorted { $0.updatedAt.foundationDate < $1.updatedAt.foundationDate }
    case .desc:
      return items.sorted { $0.updatedAt.foundationDate > $1.updatedAt.foundationDate }
    }
  }
}
