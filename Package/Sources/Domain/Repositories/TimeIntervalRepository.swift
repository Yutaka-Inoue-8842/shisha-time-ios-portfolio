//
//  TimeIntervalRepository.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/05/17.
//

import Foundation

/// TimeIntervalRepositoryのinterface
public protocol TimeIntervalRepository {
  /// データをセット
  func set(_ timeIntervals: [Int])
  /// すべてのデータを取得
  func fetch() -> [Int]
}

/// TimeIntervalRepositoryの実装クラス
public class TimeIntervalRepositoryImpl: TimeIntervalRepository {
  public var userDefaultsClient: UserDefaultsClient = UserDefaultsClient()
  private let defaultValue: [Int] = [5, 10, 15, 20, 25]

  init() {}

  public func set(_ timeIntervals: [Int]) {
    userDefaultsClient.setValue(timeIntervals, forKey: .timeIntervals)
  }

  public func fetch() -> [Int] {
    userDefaultsClient.getValue(forKey: .timeIntervals) as? [Int] ?? defaultValue
  }
}
