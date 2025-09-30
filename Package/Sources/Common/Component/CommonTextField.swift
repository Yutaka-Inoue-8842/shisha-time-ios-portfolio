//
//  CommonTextField.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/04/12.
//

import SwiftUI

public struct CommonTextField<Header: View, Footer: View>: View {
  var placeholder: String
  @Binding var text: String
  var header: Header
  var footer: Footer

  public init(
    placeholder: String = "",
    text: Binding<String>,
    @ViewBuilder header: () -> Header = { EmptyView() },
    @ViewBuilder footer: () -> Footer = { EmptyView() }
  ) {
    self.placeholder = placeholder
    self._text = text
    self.header = header()
    self.footer = footer()
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      // ヘッダー
      header

      // テキストフィールド
      TextField(placeholder, text: $text)
        .padding(12)
        .background(Color.secondaryBackground)
        .cornerRadius(8)

      // フッター
      footer
    }
  }
}

#Preview {
  // シンプルなタイトル付き
  CommonTextField(
    placeholder: "入力してください",
    text: .constant("サンプル"),
    header: {
      Text("シンプル")
    },
    footer: {
      EmptyView()
    }
  )

  // 文字数カウンター付き
  CommonTextField(
    placeholder: "カテゴリ名を入力",
    text: .constant("サンプルテキスト"),
    header: {
      Text("カテゴリ名")
    },
    footer: {
      Text("12/20文字")
        .foregroundColor(.orange)
        .font(.caption)
    }
  )

  // カスタムヘッダー・フッター
  CommonTextField(
    placeholder: "カスタム入力",
    text: .constant("テスト"),
    header: {
      HStack {
        Image(systemName: "person")
        Text("ユーザー名")
          .font(.headline)
      }
    },
    footer: {
      VStack(alignment: .leading) {
        Text("10文字以内で入力してください")
          .font(.caption)
          .foregroundColor(.red)
        Text("英数字のみ使用可能")
          .font(.caption2)
          .foregroundColor(.secondary)
      }
    }
  )
}
