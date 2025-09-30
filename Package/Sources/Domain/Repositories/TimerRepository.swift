//
//  TimerRepository.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/03/20.
//

import AWSAPIPlugin
import Amplify
import Foundation

/// TimerRepositoryのinterface
public protocol TimerRepository {
  /// データを作成
  func create(_ timer: Timer) async throws
  /// すべてのデータを取得
  func fetch(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Timer>
  /// ページネーションのための追加データを取得（nextTokenを使用）
  func fetchMore(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String
  ) async throws -> PaginatedList<Timer>
  /// idが一致するデータを取得
  func fetchById(by id: String) async throws -> Timer?
  /// データを更新
  func update(_ timer: Timer) async throws
  /// データを削除
  func delete(_ timer: Timer) async throws
}

/// TimerRepositoryの実装クラス
public actor TimerRepositoryImpl: TimerRepository {

  init() {}

  public func create(_ timer: Timer) async throws {
    _ = try await AmplifyAPIClient.shared.mutate(request: .create(timer))
  }

  public func fetch(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Timer> {

    let document = TimerQueries.buildTimerQuery(
      partition: partition,
      limit: limit,
      sortDirection: sortDirection
    )

    let request = GraphQLRequest<PaginatedList<Timer>>(
      document: document,
      responseType: PaginatedList<Timer>.self,
      decodePath: TimerQueries.decodePath
    )

    let result = try await AmplifyAPIClient.shared.query(request: request)
    return result
  }

  public func fetchMore(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String
  ) async throws -> PaginatedList<Timer> {

    let document = TimerQueries.buildTimerQuery(
      partition: partition,
      limit: limit,
      sortDirection: sortDirection,
      nextToken: nextToken
    )

    let request = GraphQLRequest<PaginatedList<Timer>>(
      document: document,
      responseType: PaginatedList<Timer>.self,
      decodePath: TimerQueries.decodePath
    )

    let result = try await AmplifyAPIClient.shared.query(request: request)
    return result
  }

  public func fetchById(by id: String) async throws -> Timer? {
    return try await AmplifyAPIClient.shared.query(request: .get(Timer.self, byId: id))
  }

  public func update(_ timer: Timer) async throws {
    _ = try await AmplifyAPIClient.shared.mutate(request: .update(timer))
  }

  public func delete(_ timer: Timer) async throws {
    _ = try await AmplifyAPIClient.shared.mutate(request: .delete(timer))
  }
}
