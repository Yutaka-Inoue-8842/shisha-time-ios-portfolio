//
//  AddTemplateView.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/02/23.
//

import Common
import ComposableArchitecture
import SwiftUI

@ViewAction(for: AddTemplateFeature.self)
struct AddTemplateView: View {

  @Bindable var store: StoreOf<AddTemplateFeature>

  init(store: StoreOf<AddTemplateFeature>) {
    self.store = store
  }

  var body: some View {
    VStack {
      CommonTextField(
        placeholder: "タイトルを入力",
        text: $store.title,
        header: {
          Text("タイトル")
            .font(.caption)
            .foregroundStyle(Color.primaryText)
        }
      )
      Divider()
        .padding(.vertical, 12)

      HStack {
        Text("ドキュメントテンプレート")
          .font(.caption)
          .foregroundStyle(Color.primaryText)
        Spacer()
      }

      RichTextView(
        content: $store.content
      )
      .background(Color(.systemGray6))
      .cornerRadius(8)
    }
    .padding(.horizontal, 16)
    .navigationBarBackButtonHidden(true)
    .navigationBarItem(
      placement: .topBarTrailing,
      content: {
        Text("Save")
          .font(.subheadline)
      },
      action: {
        send(.saveButtonTapped)
      }
    )
    .navigationBarItem(
      placement: .topBarLeading,
      content: {
        HStack(spacing: 0) {
          Image(systemName: "chevron.backward")
          Text("戻る")
            .font(.subheadline)
        }
      },
      action: {
        send(.backButtonTapped)
      }
    )
  }
}

#Preview {
  AddTemplateView(
    store: .init(initialState: .init()) {
      AddTemplateFeature()
    }
  )
}
