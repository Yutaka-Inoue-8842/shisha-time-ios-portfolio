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
