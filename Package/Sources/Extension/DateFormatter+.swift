//
//  DateFormatter+.swift
//  Package
//
//  Created by Yutaka Inoue on 2024/10/16.
//

import Foundation

extension DateFormatter {
  /// DateFormatterを作成
  /// - Parameters:
  ///   - format: フォーマットの指定
  /// - Returns: 作成されたDateFormatter
  public static func format(_ format: DateFormat) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = format.rawValue
    return formatter
  }
}

public enum DateFormat: String {
  case full = "yyyy-MM-dd'T'HH:mm:ss"
}
