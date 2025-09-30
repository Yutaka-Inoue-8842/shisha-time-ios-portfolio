//
//  File.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/03/01.
//

import Foundation
import SwiftUI

#if canImport(UIKit)
  import UIKit
#endif

// RichTextView に適用するフォントの定義
extension UIFont {
  /// タイトル
  public static let richTextTitle = UIFont.boldSystemFont(ofSize: 28)
  /// 見出し
  public static let richTextHeadline = UIFont.boldSystemFont(ofSize: 24)
  /// 本文
  public static let richTextBody = UIFont.systemFont(ofSize: 16)
}
