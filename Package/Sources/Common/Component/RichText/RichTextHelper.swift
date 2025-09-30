//
//  RichTextHelper.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/03/03.
//

import Foundation
import SwiftUI

#if canImport(UIKit)
  import UIKit
#endif

enum TextStyle {
  case title,
    headline,
    body,
    bullet
}

struct RichTextHelper {

  static let textColor = UIColor(Color.primaryText)

  /// タイトルのフォントを適用
  static func toggleTitleStyle(
    attributedText: NSMutableAttributedString,
    range: NSRange,
    currentStyle: TextStyle
  ) -> NSMutableAttributedString {

    var range = range
    if currentStyle == .bullet {
      attributedText.replaceCharacters(
        in: NSRange(
          location: range.location,
          length: 1
        ),
        with: ""
      )
      range = NSRange(
        location: range.location,
        length: range.length - 1
      )
    }

    attributedText.addAttributes(
      [
        .font: currentStyle == .title ? UIFont.richTextBody : UIFont.richTextTitle,
        .foregroundColor: textColor
      ],
      range: range
    )
    return attributedText
  }

  /// 見出しのフォントを適用
  static func toggleHeadlineStyle(
    attributedText: NSMutableAttributedString,
    range: NSRange,
    currentStyle: TextStyle
  ) -> NSMutableAttributedString {

    var range = range
    if currentStyle == .bullet {
      attributedText.replaceCharacters(
        in: NSRange(
          location: range.location,
          length: 1
        ),
        with: ""
      )
      range = NSRange(
        location: range.location,
        length: range.length - 1
      )
    }

    attributedText.addAttributes(
      [
        .font: currentStyle == .headline ? UIFont.richTextBody : UIFont.richTextHeadline,
        .foregroundColor: textColor
      ],
      range: range
    )

    return attributedText
  }

  /// 本文のフォントを適用
  static func applyBodyStyle(
    attributedText: NSMutableAttributedString,
    range: NSRange,
    currentStyle: TextStyle
  ) -> NSMutableAttributedString {

    var range = range
    if currentStyle == .bullet {
      attributedText.replaceCharacters(
        in: NSRange(
          location: range.location,
          length: 1
        ),
        with: ""
      )
      range = NSRange(
        location: range.location,
        length: range.length - 1
      )
    }

    attributedText.addAttributes(
      [
        .font: UIFont.richTextBody,
        .foregroundColor: textColor
      ],
      range: range
    )

    return attributedText
  }

  static func toggleBulletStyle(
    attributedText: NSMutableAttributedString,
    range: NSRange,
    currentStyle: TextStyle
  ) -> NSMutableAttributedString {
    if currentStyle == .bullet {
      attributedText.replaceCharacters(
        in: NSRange(
          location: range.location,
          length: 1
        ),
        with: ""
      )
    } else {
      attributedText.insert(
        NSAttributedString(
          attachment: BulletTextAttachment()
        ),
        at: range.location
      )
      attributedText.addAttributes(
        [
          .font: UIFont.richTextBody,
          .foregroundColor: textColor
        ],
        range: NSRange(
          location: range.location,
          length: range.length + 1
        )
      )
    }
    return attributedText
  }

  static func getCurrentLineRange(
    attributedText: NSMutableAttributedString,
    selectedRange: NSRange
  ) -> NSRange? {
    let fullText = attributedText.string as NSString
    let cursorLocation = selectedRange.location

    // もしテキストが空なら nil を返す
    if fullText.length == 0 {
      return nil
    }

    // カーソルの前のテキスト
    let textBeforeCursor = fullText.substring(to: cursorLocation)

    // カーソルの前で最後の改行を探す（現在の行の開始位置）
    // swiftlint:disable:next line_length
    let lineStartIndex = textBeforeCursor.range(of: "\n", options: .backwards)?.upperBound.utf16Offset(in: textBeforeCursor) ?? 0

    // カーソルの後のテキスト
    let textAfterCursor = fullText.substring(from: cursorLocation)

    // カーソルの後で最初の改行を探す（現在の行の終了位置）
    // swiftlint:disable:next line_length
    let lineEndIndexRelative = textAfterCursor.range(of: "\n")?.lowerBound.utf16Offset(in: textAfterCursor) ?? textAfterCursor.count
    let lineEndIndex = cursorLocation + lineEndIndexRelative

    // 現在の行の範囲を作成
    let lineLength = lineEndIndex - lineStartIndex
    return NSRange(location: lineStartIndex, length: lineLength)
  }

  static func getBeforeLineRange(
    attributedText: NSMutableAttributedString,
    selectedRange: NSRange
  ) -> NSRange? {
    // カーソルより前のテキストを取得
    let textBeforeCursor = (attributedText.string as NSString).substring(to: selectedRange.location)

    // テキストを行ごとに分割
    let lines = textBeforeCursor.components(separatedBy: "\n")

    // 前の行があるか確認
    guard lines.count > 1 else {
      // 前の行がない場合は nil
      return nil
    }

    // 前の行のテキストの長さを取得
    let previousLineText = lines[lines.count - 2]  // 直前の行
    let previousLineLength = previousLineText.count

    // 直前の行の開始位置を取得
    let previousLineStartIndex = textBeforeCursor.count - previousLineLength - 1  // -1 は改行分

    // NSRange を作成
    return NSRange(location: previousLineStartIndex, length: previousLineLength)

  }

  static func getLineTextStyle(
    attributedText: NSMutableAttributedString,
    lineRange: NSRange
  ) -> TextStyle {

    var textStyle: TextStyle = .body

    attributedText.enumerateAttribute(.font, in: lineRange, options: []) { (value, _, _) in
      if let font = value as? UIFont {
        if font == .richTextTitle {
          textStyle = .title
        }

        if font == .richTextHeadline {
          textStyle = .headline
        }

        if font == .richTextBody {
          textStyle = .body
        }
      }
    }

    attributedText.enumerateAttribute(.attachment, in: lineRange, options: []) { (value, _, _) in
      if let attachment = value as? NSTextAttachment {
        if attachment is BulletTextAttachment {
          textStyle = .bullet
        }
      }
    }

    return textStyle
  }

  static func getTextStyleAttribute(_ textStyle: TextStyle) -> [NSAttributedString.Key: Any] {

    switch textStyle {
    case .title:
      [
        .font: UIFont.richTextTitle,
        .foregroundColor: textColor
      ]
    case .headline:
      [
        .font: UIFont.richTextHeadline,
        .foregroundColor: textColor
      ]
    case .body:
      [
        .font: UIFont.richTextBody,
        .foregroundColor: textColor
      ]
    case .bullet:
      [
        .font: UIFont.richTextBody,
        .foregroundColor: textColor
      ]
    }

  }
}
