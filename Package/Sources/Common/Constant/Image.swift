//
//  Image.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/05/03.
//

import Foundation
import SwiftUI

#if canImport(UIKit)
  import UIKit
#endif

extension UIImage {
  public static let titleTextSelect = UIImage(
    named: "title_text_select",
    in: .module,
    compatibleWith: nil
  )!
  public static let titleTextUnselect = UIImage(
    named: "title_text_unselect",
    in: .module,
    compatibleWith: nil
  )!
  public static let headlineTextSelect = UIImage(
    named: "headline_text_select",
    in: .module,
    compatibleWith: nil
  )!
  public static let headlineTextUnselect = UIImage(
    named: "headline_text_unselect",
    in: .module,
    compatibleWith: nil
  )!
  public static let bodyTextSelect = UIImage(
    named: "body_text_select",
    in: .module,
    compatibleWith: nil
  )!
  public static let bodyTextUnselect = UIImage(
    named: "body_text_unselect",
    in: .module,
    compatibleWith: nil
  )!
  public static let bulletTextSelect = UIImage(
    named: "bullet_text_select",
    in: .module,
    compatibleWith: nil
  )!
  public static let bulletTextUnselect = UIImage(
    named: "bullet_text_unselect",
    in: .module,
    compatibleWith: nil
  )!

}
