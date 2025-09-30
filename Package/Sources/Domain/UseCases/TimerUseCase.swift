//
//  TimerUseCase.swift
//  Package
//
//  Created by Yutaka Inoue on 2024/10/26.
//

import Amplify
import ComposableArchitecture
import Extension
import Foundation
@preconcurrency import UserNotifications

/// TimerUseCase
@DependencyClient
public struct TimerUseCase: Sendable {
  /// データを作成
  public var create: @Sendable (_ minutesInterval: Int?, _ table: Table?) async throws -> Timer
  /// すべてのデータを取得
  public var fetchAll: @Sendable () async throws -> PaginatedList<Timer>
  /// ページネーション対応でデータを取得（初回）
  public var fetch: @Sendable (_ limit: Int) async throws -> PaginatedList<Timer>
  /// ページネーション対応でデータを取得（続きページ）
  public var fetchMore: @Sendable (_ nextToken: String, _ limit: Int) async throws -> PaginatedList<Timer>
  /// タイマーリセット
  public var reset: @Sendable (_ timer: Timer) async throws -> Timer
  /// タイマーを更新
  public var update: @Sendable (_ timer: Timer, _ newMinutesInterval: Int?, _ newTable: Table?) async throws -> Timer
  /// データを削除
  public var delete: @Sendable (_ timer: Timer) async throws -> Void
}

extension TimerUseCase {
  /// バリデーション
  public static func validate(minutesInterval: Int?, table: Table?) throws {
    guard let table else {
      throw TimerValidationError.invalidTableSelection
    }

    guard table.name.count <= 20 else {
      throw TimerValidationError.invalidTableNameLength
    }

    guard minutesInterval != nil else {
      throw TimerValidationError.invalidMinutesIntervalSelection
    }
  }
}

extension TimerUseCase: DependencyKey {
  /// TimerUseCaseのDependencyKey
  public static let liveValue: TimerUseCase = {
    let timerRepository = TimerRepositoryImpl()
    let tableRepository = TableRepositoryImpl()
    let localPushNotificationRepository = LocalPushNotificationRepositoryImpl()

    return Self(
      create: { minutesInterval, table in
        try TimerUseCase.validate(minutesInterval: minutesInterval, table: table)

        guard let minutesInterval else {
          throw TimerValidationError.invalidMinutesIntervalSelection
        }

        let nextCheckTime = Date().addingTimeInterval(minutesInterval.toTimeInterval)
        var timer = Timer(
          nextCheckTime: .init(nextCheckTime),
          minutesInterval: minutesInterval,
          createdAt: .init(Date()),
          updatedAt: .init(Date())
        )
        timer.setTable(table)
        try await timerRepository.create(timer)

        // ローカルプッシュ通知の作成・登録 (UNNotificationRequestはSendableでないため分離)
        let request = await localPushNotificationRepository.makeRequest(
          id: timer.id,
          title: table?.name ?? "",
          body: "炭をチェックしてください",
          date: nextCheckTime
        )
        try await localPushNotificationRepository.add(request)

        return timer
      },
      fetchAll: {
        try await timerRepository.fetch(
          partition: .global,
          limit: 60,
          sortDirection: .asc
        )
      },
      fetch: { limit in
        try await timerRepository.fetch(
          partition: .global,
          limit: limit,
          sortDirection: .asc
        )
      },
      fetchMore: { nextToken, limit in
        try await timerRepository.fetchMore(
          partition: .global,
          limit: limit,
          sortDirection: .asc,
          nextToken: nextToken
        )
      },
      reset: { timer in
        var targetTimer = timer
        let minutesInterval = targetTimer.minutesInterval
        let newNextCheckTime = Date().addingTimeInterval(minutesInterval.toTimeInterval)
        targetTimer.nextCheckTime = .init(newNextCheckTime)

        try await timerRepository.update(targetTimer)

        let table = try await timer.table

        let request = await localPushNotificationRepository.makeRequest(
          id: timer.id,
          title: table?.name ?? "",
          body: "炭をチェックしてください",
          date: newNextCheckTime
        )
        try await localPushNotificationRepository.add(request)

        return targetTimer
      },
      update: { timer, newMinutesInterval, newTable in
        try TimerUseCase.validate(minutesInterval: newMinutesInterval, table: newTable)

        guard let newMinutesInterval else {
          throw TimerValidationError.invalidMinutesIntervalSelection
        }

        var targetTimer = timer
        targetTimer.minutesInterval = newMinutesInterval
        targetTimer.updatedAt = .init(Date())
        targetTimer.setTable(newTable)

        let newNextCheckTime = Date().addingTimeInterval(newMinutesInterval.toTimeInterval)
        targetTimer.nextCheckTime = .init(newNextCheckTime)

        try await timerRepository.update(targetTimer)

        let request = await localPushNotificationRepository.makeRequest(
          id: targetTimer.id,
          title: newTable?.name ?? "",
          body: "炭をチェックしてください",
          date: newNextCheckTime
        )
        try await localPushNotificationRepository.add(request)

        return targetTimer
      },
      delete: { timer in
        try await timerRepository.delete(timer)
        await localPushNotificationRepository.removePendingRequest(timer.id)
      }
    )
  }()
}

extension TimerUseCase: TestDependencyKey {
  public static let testValue: TimerUseCase = Self()
  public static let previewValue: TimerUseCase = Self()
}

extension DependencyValues {
  /// TimerUseCaseのDependencyValues
  public var timerUseCase: TimerUseCase {
    get { self[TimerUseCase.self] }
    set { self[TimerUseCase.self] = newValue }
  }
}
