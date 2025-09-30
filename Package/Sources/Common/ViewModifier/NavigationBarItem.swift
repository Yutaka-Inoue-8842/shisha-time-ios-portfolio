//
//  NavigationBarItemModifier.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/02/20.
//

import SwiftUI

extension View {
  ///  ナビゲーションボタン追加用モディファイア
  public func navigationBarItem<V: View>(
    placement: ToolbarItemPlacement,
    @ViewBuilder content: @escaping () -> V,
    action: @escaping () -> Void
  ) -> some View {
    self.modifier(
      NavigationBarItemModifier(
        placement: placement,
        content: content,
        action: action
      )
    )
  }
}

///  ナビゲーションボタン追加用モディファイア
struct NavigationBarItemModifier<V: View>: ViewModifier {
  /// 配置位置
  let placement: ToolbarItemPlacement
  /// コンテンツ
  let content: () -> V
  /// タップアクション
  let action: () -> Void

  func body(content: Content) -> some View {
    content
      .toolbar {
        ToolbarItem(placement: self.placement) {
          Button(action: action) {
            self.content()
          }
        }
      }
  }
}
