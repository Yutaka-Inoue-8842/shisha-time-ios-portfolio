//
//  Data+.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/02/22.
//

import Foundation

#if canImport(UIKit)
  import UIKit
#endif

extension Data {
  /// Data→AttributedStringへの変換
  public func toAttributedString() -> NSAttributedString? {
    return try? NSKeyedUnarchiver.unarchivedObject(
      ofClass: NSAttributedString.self,
      from: self
    )
  }
}
