//
//  TimeInterval.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/08/24.
//
import Foundation

public struct TimeIntervalData: Identifiable, Hashable, Sendable {
  public let id: UUID
  public var timeInterval: String

  public init(
    id: UUID = UUID(),
    timeInterval: String
  ) {
    self.id = id
    self.timeInterval = timeInterval
  }
}
