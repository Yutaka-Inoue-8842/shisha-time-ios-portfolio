//
//  Date+.swift
//  Package
//
//  Created by Yutaka Inoue on 2024/10/16.
//

import Foundation

extension Date {
  /// Date -> Stringの変換
  /// - Parameters:
  ///   - format: フォーマットの指定
  /// - Returns: 変換された文字列
  public func toString(format: DateFormat) -> String {
    let formatter = DateFormatter.format(format)
    return formatter.string(from: self)
  }

  /// `timeIntervalSinceNow` を分単位の `Int` に変換（切り上げ）
  public var minutesUntilNow: Int {
    return Int(ceil(self.timeIntervalSinceNow / 60))
  }

  /// 更新日時を適切な形式でフォーマット
  public var formattedUpdateTime: String {
    let formatter = DateFormatter()
    let calendar = Calendar.current

    if calendar.isDateInToday(self) {
      formatter.dateFormat = "HH:mm"
      return formatter.string(from: self)
    } else if calendar.isDateInYesterday(self) {
      return "昨日"
    } else if let daysBetween = calendar.dateInterval(of: .weekOfYear, for: Date())?.contains(self),
      daysBetween
    {
      formatter.dateFormat = "E"
      formatter.locale = Locale(identifier: "ja_JP")
      return formatter.string(from: self)
    } else {
      formatter.dateFormat = "M/d"
      return formatter.string(from: self)
    }
  }
}
