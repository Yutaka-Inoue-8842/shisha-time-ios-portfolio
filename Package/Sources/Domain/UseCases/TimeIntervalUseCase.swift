//
//  TimeIntervalUseCase.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/05/17.
//

import ComposableArchitecture
import Foundation

/// TimeIntervalUseCase
@DependencyClient
public struct TimeIntervalUseCase: Sendable {
  /// データを設定
  public var set: @Sendable (_ timeIntervals: [Int]) -> Void
  /// データを取得
  public var fetch: @Sendable () -> [TimeIntervalData] = {
    [
      TimeIntervalData(
        timeInterval: "5",
      ),
      TimeIntervalData(
        timeInterval: "10",
      ),
      TimeIntervalData(
        timeInterval: "15",
      ),
      TimeIntervalData(
        timeInterval: "20",
      ),
      TimeIntervalData(
        timeInterval: "25",
      )
    ]
  }
}

extension TimeIntervalUseCase: DependencyKey {
  /// TimeIntervalUseCaseのDependencyKey
  public static let liveValue: TimeIntervalUseCase = Self(
    set: { timeIntervals in
      TimeIntervalRepositoryImpl().set(timeIntervals)
    },
    fetch: {
      let timeIntervals = TimeIntervalRepositoryImpl().fetch()
      return timeIntervals.map { TimeIntervalData(timeInterval: "\($0)") }
    }
  )
}

extension TimeIntervalUseCase: TestDependencyKey {
  public static let testValue: TimeIntervalUseCase = Self()
  public static let previewValue: TimeIntervalUseCase = Self()
}

extension DependencyValues {
  /// TimeIntervalUseCaseのDependencyValues
  public var timeIntervalUseCase: TimeIntervalUseCase {
    get { self[TimeIntervalUseCase.self] }
    set { self[TimeIntervalUseCase.self] = newValue }
  }
}
