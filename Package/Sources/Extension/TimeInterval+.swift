//
//  TimeInterval+.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/01/26.
//

import Foundation

extension TimeInterval {
  /// `TimeInterval` (秒) を `Int` (分) に変換
  public var toMinutes: Int {
    return Int(self / 60)
  }
}
