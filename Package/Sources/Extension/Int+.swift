//
//  Int+.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/01/26.
//

import Foundation

extension Int {
  /// `Int` (分) を `TimeInterval` (秒) に変換
  public var toTimeInterval: TimeInterval {
    return TimeInterval(self * 60)
  }
}
