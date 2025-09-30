//
//  String+.swift
//  Package
//
//  Created by Yutaka Inoue on 2024/10/16.
//

import Foundation

extension String {
  /// String -> Dateの変換
  /// - Parameters:
  ///   - format: フォーマットの指定
  /// - Returns: 変換された日付
  public func toDate(format: DateFormat) -> Date? {
    let formatter = DateFormatter.format(format)
    return formatter.date(from: self)
  }

  /// base64EncodedString→Data→AttributedStringへの変換
  public func toAttributedString() -> NSAttributedString? {
    guard let data = Data(base64Encoded: self),
      let attributedString = data.toAttributedString()
    else {
      return nil
    }
    return attributedString
  }
}
