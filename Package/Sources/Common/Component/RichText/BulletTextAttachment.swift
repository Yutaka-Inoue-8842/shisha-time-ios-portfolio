//
//  BulletTextAttachment.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/03/03.
//

import Foundation

#if canImport(UIKit)
  import UIKit
#endif

class BulletTextAttachment: NSTextAttachment {

  var customSize: CGSize = CGSize(width: 8, height: 8)
  var padding: UIEdgeInsets = UIEdgeInsets(
    top: 4,
    left: 8,
    bottom: 4,
    right: 8
  )

  static override var supportsSecureCoding: Bool {
    return true
  }

  override func image(
    forBounds imageBounds: CGRect,
    textContainer: NSTextContainer?,
    characterIndex charIndex: Int
  ) -> UIImage? {
    guard let image = UIImage(systemName: "circle.fill") else {
      return nil
    }

    let tintedImage = image.withTintColor(UIColor(.primaryText), renderingMode: .alwaysTemplate)

    let newSize = CGSize(
      width: customSize.width + padding.left + padding.right,
      height: customSize.height + padding.top + padding.bottom
    )

    let renderer = UIGraphicsImageRenderer(size: newSize)
    let resizedImage = renderer.image { _ in
      let imageRect = CGRect(
        x: padding.left,
        y: padding.top,
        width: customSize.width,
        height: customSize.height
      )
      tintedImage.draw(in: imageRect)
    }

    return resizedImage
  }

  override func attachmentBounds(
    for textContainer: NSTextContainer?,
    proposedLineFragment lineFrag: CGRect,
    glyphPosition position: CGPoint,
    characterIndex charIndex: Int
  ) -> CGRect {

    // 画像のサイズ + 余白
    let width = customSize.width + padding.left + padding.right
    let height = customSize.height + padding.top + padding.bottom

    return CGRect(x: 0, y: -padding.top, width: width, height: height)
  }
}
