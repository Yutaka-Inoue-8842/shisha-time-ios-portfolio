//
//  EditTableView.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/07/25.
//

import Common
import ComposableArchitecture
import SwiftUI

@ViewAction(for: EditTableFeature.self)
public struct EditTableView: View {

  @Bindable public var store: StoreOf<EditTableFeature>

  public init(store: StoreOf<EditTableFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      // ヘッダー
      ZStack(alignment: .center) {
        HStack(alignment: .center) {
          Button("キャンセル") {
            send(.backButtonTapped)
          }
          .foregroundColor(.appPrimary)

          Spacer()

          Button("保存") {
            send(.saveButtonTapped)
          }
          .foregroundColor(.appPrimary)
          .disabled(store.tableName.isEmpty)
        }

        Text("テーブルを編集")
          .font(.system(.headline))
      }
      .padding(.horizontal, 16)
      .frame(height: 50)
      .frame(maxWidth: .infinity, alignment: .center)

      Divider()

      Spacer()
        .frame(height: 16)

      // テーブル名入力
      CommonTextField(
        placeholder: "テーブル名を入力",
        text: $store.tableName,
        header: {
          Text("テーブル名")
            .font(.caption)
            .foregroundStyle(Color.primaryText)
        }
      )
      .padding(.horizontal, 16)

      Spacer()

      // 削除ボタン
      DangerButton(
        title: "テーブルを削除"
      ) {
        send(.deleteButtonTapped)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 50)
      .padding(.horizontal, 16)
    }
    .alert($store.scope(state: \.alert, action: \.alert))
    .onAppear {
      send(.onAppear)
    }
  }
}

#Preview {
  EditTableView(
    store: .init(
      initialState: .init(
        table: .init(
          name: "Preview Table",
          createdAt: .init(Date()),
          updatedAt: .init(Date())
        )
      )
    ) {
      EditTableFeature()
    }
  )
}
