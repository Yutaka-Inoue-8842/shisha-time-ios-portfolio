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
public protocol TimerRepository: Sendable {
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

// MARK: - Demo Implementation

/// デモ環境用のTimerRepository実装（オンメモリ）
public actor TimerRepositoryDemoImpl: TimerRepository {

  private var timers: [Timer] = []

  public init() {
    // テーブル関連のサンプルデータが必要な場合は、
    // 先にTableRepositoryを初期化してからTimerを生成する必要がある
    let tables = SampleDataProvider.sampleTables()
    self.timers = SampleDataProvider.sampleTimers(tables: tables)
  }

  public func create(_ timer: Timer) async throws {
    timers.append(timer)
  }

  public func fetch(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) async throws -> PaginatedList<Timer> {
    let sorted = sortTimers(timers, direction: sortDirection)
    let items = Array(sorted.prefix(limit))
    let nextToken = items.count < sorted.count ? "has_more" : nil
    return PaginatedList(items: items, nextToken: nextToken)
  }

  public func fetchMore(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String
  ) async throws -> PaginatedList<Timer> {
    let sorted = sortTimers(timers, direction: sortDirection)
    let offset = min(limit, sorted.count)
    let items = Array(sorted.dropFirst(offset).prefix(limit))
    let newNextToken = (offset + items.count) < sorted.count ? "has_more" : nil
    return PaginatedList(items: items, nextToken: newNextToken)
  }

  public func fetchById(by id: String) async throws -> Timer? {
    return timers.first { $0.id == id }
  }

  public func update(_ timer: Timer) async throws {
    if let index = timers.firstIndex(where: { $0.id == timer.id }) {
      timers[index] = timer
    }
  }

  public func delete(_ timer: Timer) async throws {
    timers.removeAll { $0.id == timer.id }
  }

  // MARK: - Helper Methods

  private func sortTimers(_ items: [Timer], direction: SortDirection) -> [Timer] {
    switch direction {
    case .asc:
      return items.sorted { $0.nextCheckTime.foundationDate < $1.nextCheckTime.foundationDate }
    case .desc:
      return items.sorted { $0.nextCheckTime.foundationDate > $1.nextCheckTime.foundationDate }
    }
  }
}
