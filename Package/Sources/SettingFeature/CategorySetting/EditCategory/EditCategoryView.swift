//
//  EditCategoryView.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/07/26.
//

import Common
import ComposableArchitecture
import Domain
import SwiftUI

@ViewAction(for: EditCategoryFeature.self)
struct EditCategoryView: View {
  @Bindable var store: StoreOf<EditCategoryFeature>

  init(store: StoreOf<EditCategoryFeature>) {
    self.store = store
  }

  var body: some View {
    VStack(spacing: 0) {
      // ヘッダー
      Text("カテゴリを編集")
        .font(.system(.headline))
        .frame(maxWidth: .infinity)
        .frame(height: 50)

      Divider()

      Spacer()
        .frame(height: 16)

      // フォーム
      CommonTextField(
        placeholder: "カテゴリ名を入力",
        text: $store.categoryName,
        header: {
          Text("カテゴリ名")
            .font(.caption)
            .foregroundStyle(Color.primaryText)
        },
        footer: {
          HStack {
            Spacer()
            Text("\(store.categoryName.count)/20文字")
              .foregroundColor(store.categoryName.count > 15 ? .orange : .secondary)
              .font(.caption)
          }
        }
      )
      .padding(.horizontal, 16)

      Spacer()

      PrimaryButton(
        title: "カテゴリを保存"
      ) {
        send(.saveButtonTapped)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 50)
      .padding(.horizontal, 16)
    }
    .onAppear {
      send(.onAppear)
    }
  }
}

#Preview {
  EditCategoryView(
    store: .init(
      initialState: .init(
        category: Category(
          name: "サンプルカテゴリ",
          createdAt: .init(Date()),
          updatedAt: .init(Date())
        )
      )
    ) {
      EditCategoryFeature()
    }
  )
}
