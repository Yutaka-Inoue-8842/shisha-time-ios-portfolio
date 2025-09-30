//
//  LocalPushNotificationRepository.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/05/18.
//

import Foundation
@preconcurrency import UserNotifications

/// LocalPushNotificationRepositoryのinterface
public protocol LocalPushNotificationRepository {
  /// ローカルプッシュ通をを作成
  func add(_ request: UNNotificationRequest) async throws
  /// idが一致する通知を削除
  func removePendingRequest(_ identifier: String) async
  /// 待機中のプッシュ通知を取得
  func getPendingRequests() async -> [UNNotificationRequest]
  /// リクエストを作成
  func makeRequest(id: String, title: String, body: String, date: Date) async -> UNNotificationRequest
}

public actor LocalPushNotificationRepositoryImpl: LocalPushNotificationRepository {

  private let center: UNUserNotificationCenter = UNUserNotificationCenter.current()

  public init() {}

  public func add(_ request: UNNotificationRequest) async throws {
    try await center.add(request)
  }

  public func removePendingRequest(_ identifier: String) async {
    center.removePendingNotificationRequests(withIdentifiers: [identifier])
  }

  public func getPendingRequests() async -> [UNNotificationRequest] {
    await center.pendingNotificationRequests()
  }

  public func makeRequest(id: String, title: String, body: String, date: Date) async -> UNNotificationRequest {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(
      timeInterval: max(date.timeIntervalSinceNow, 1),
      repeats: false
    )

    return UNNotificationRequest(
      identifier: id,
      content: content,
      trigger: trigger
    )
  }
}
