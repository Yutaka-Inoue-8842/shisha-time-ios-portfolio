//
//  AddTableView.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/04/12.
//

import Common
import ComposableArchitecture
import SwiftUI

@ViewAction(for: AddTableFeature.self)
struct AddTableView: View {

  @Bindable var store: StoreOf<AddTableFeature>

  init(store: StoreOf<AddTableFeature>) {
    self.store = store
  }

  var body: some View {
    VStack(spacing: 0) {
      Text("テーブルを追加する")
        .font(.system(.headline))
        .frame(maxWidth: .infinity)
        .frame(height: 50)
      Divider()

      Spacer()
        .frame(height: 16)

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

      PrimaryButton(
        title: "テーブルを追加"
      ) {
        send(.addTable)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 50)
      .padding(.horizontal, 16)

    }
  }
}

#Preview {
  AddTableView(
    store: .init(initialState: .init()) {
      AddTableFeature()
    }
  )
}
