//
//  NSAttributedString+.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/02/22.
//

import Foundation

#if canImport(UIKit)
  import UIKit
#endif

extension NSAttributedString {
  /// AttributedString→Dataへの変換
  public func toData() -> Data? {
    return try? NSKeyedArchiver.archivedData(
      withRootObject: self,
      requiringSecureCoding: false
    )
  }

  /// AttributedString→Data→base64EncodedStringへの変換
  public func toString() -> String? {
    guard let data = self.toData() else {
      return nil
    }
    return data.base64EncodedString()
  }

}
