//
//  File.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/03/11.
//

import Foundation
import SwiftUI

#if canImport(UIKit)
  import UIKit
#endif

extension Color {
  public static let appPrimary = Color.indigo
  public static let primaryText = Color(UIColor.label)
  public static let secondaryText = Color(UIColor.secondaryLabel)
  public static let whiteText = Color(UIColor.white)
  public static let primaryBackground = Color(UIColor.systemBackground)
  public static let secondaryBackground = Color(UIColor.secondarySystemBackground)
}
